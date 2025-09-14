#include "PianoVoice.h"

PianoVoice::PianoVoice()
{
}

bool PianoVoice::canPlaySound(juce::SynthesiserSound* sound)
{
    return dynamic_cast<PianoSound*>(sound) != nullptr;
}

void PianoVoice::startNote(int midiNoteNumber, float velocity, juce::SynthesiserSound* sound, int)
{
    DBG("PianoVoice::startNote - MIDI note: " + juce::String(midiNoteNumber) + ", velocity: " + juce::String(velocity));
    
    if (auto* pianoSound = dynamic_cast<PianoSound*>(sound))
    {
        currentSample = pianoSound->getSampleForNote(midiNoteNumber);
        if (currentSample != nullptr)
        {
            // 使用 SFZ 样本
            currentPosition = 0.0;
            level = velocity;
            tailOff = 0.0f;
            isPlaying = true;
            
            // 计算音高比率
            int sampleRootNote = pianoSound->getRootNoteForMidiNote(midiNoteNumber);
            double sampleSampleRate = pianoSound->getSampleRateForMidiNote(midiNoteNumber);
            double currentSampleRate = getSampleRate();
            double noteFreq = juce::MidiMessage::getMidiNoteInHertz(midiNoteNumber);
            double sampleFreq = juce::MidiMessage::getMidiNoteInHertz(sampleRootNote);
            
            pitchRatio = (noteFreq / sampleFreq) * (sampleSampleRate / currentSampleRate);
            
            DBG("SFZ sample loaded - pitch ratio: " + juce::String(pitchRatio));
        }
        else
        {
            // 回退到合成音色
            currentSample = nullptr;
            currentPosition = 0.0;
            level = velocity * 0.4f;
            tailOff = 0.0f;
            isPlaying = true;
            
            frequency = juce::MidiMessage::getMidiNoteInHertz(midiNoteNumber);
            pitchRatio = frequency * 2.0 * juce::MathConstants<double>::pi / getSampleRate();
            
            DBG("Using synthetic piano fallback");
        }
    }
    else
    {
        DBG("Error: Sound is not PianoSound type");
        isPlaying = false;
    }
}

void PianoVoice::stopNote(float, bool allowTailOff)
{
    if (allowTailOff)
    {
        tailOff = 1.0f;
    }
    else
    {
        clearCurrentNote();
        isPlaying = false;
    }
}

void PianoVoice::renderNextBlock(juce::AudioBuffer<float>& outputBuffer, int startSample, int numSamples)
{
    if (!isVoiceActive() || !isPlaying)
        return;
    
    auto localLevel = level * volume;
    
    while (--numSamples >= 0)
    {
        float envGain = 1.0f;
        
        if (tailOff > 0.0f)
        {
            tailOff *= 0.998f;
            envGain *= tailOff;
            
            if (tailOff < 0.01f)
            {
                clearCurrentNote();
                isPlaying = false;
                break;
            }
        }
        
        float sampleL = 0.0f;
        float sampleR = 0.0f;

        if (currentSample != nullptr)
        {
            // 使用 SFZ 样本（带线性插值 + 立体声）
            const int totalSamples = currentSample->getNumSamples();
            int idx = (int) currentPosition;
            if (idx + 1 < totalSamples)
            {
                float frac = (float) (currentPosition - (double) idx);
                // 左声道
                float s0L = currentSample->getSample(0, idx);
                float s1L = currentSample->getSample(0, idx + 1);
                sampleL = s0L + frac * (s1L - s0L);
                // 右声道（若无则复用左声道）
                if (currentSample->getNumChannels() > 1)
                {
                    float s0R = currentSample->getSample(1, idx);
                    float s1R = currentSample->getSample(1, idx + 1);
                    sampleR = s0R + frac * (s1R - s0R);
                }
                else
                {
                    sampleR = sampleL;
                }
                // 简单攻击避免起始点击（5ms 渐入）
                const double attackSamples = getSampleRate() * 0.005;
                if (currentPosition < attackSamples)
                {
                    float attackGain = (float) (currentPosition / attackSamples);
                    envGain *= attackGain;
                }
                sampleL *= (localLevel * envGain);
                sampleR *= (localLevel * envGain);
                currentPosition += pitchRatio;
            }
            else
            {
                clearCurrentNote();
                isPlaying = false;
                break;
            }
        }
        else
        {
            // 合成音色回退
            float attackTime = getSampleRate() * 0.01f;
            float decayTime = getSampleRate() * 2.0f;
            
            if (currentPosition < attackTime)
            {
                envGain = (float)currentPosition / attackTime;
            }
            else
            {
                float decay = 1.0f - ((float)(currentPosition - attackTime) / decayTime);
                envGain = juce::jmax(0.3f, decay);
            }
            
            float osc = 0.0f;
            osc += std::sin(currentPosition * pitchRatio) * 0.6f;
            osc += std::sin(currentPosition * pitchRatio * 2.0) * 0.3f;
            osc += std::sin(currentPosition * pitchRatio * 3.0) * 0.15f;
            osc *= localLevel * envGain;
            sampleL = sampleR = osc;
            
            currentPosition += 1.0;
            
            if (tailOff == 0.0f && currentPosition > getSampleRate() * 5.0)
            {
                tailOff = 1.0f;
            }
        }
        
        // 写入输出（立体声优先，多通道则复制左右）
        const int outChans = outputBuffer.getNumChannels();
        if (outChans > 0)
            outputBuffer.addSample(0, startSample, sampleL);
        if (outChans > 1)
            outputBuffer.addSample(1, startSample, sampleR);
        for (int ch = 2; ch < outChans; ++ch)
            outputBuffer.addSample(ch, startSample, 0.5f * (sampleL + sampleR));
        
        ++startSample;
    }
}

void PianoVoice::pitchWheelMoved(int)
{
}

void PianoVoice::controllerMoved(int, int)
{
}

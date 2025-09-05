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
            currentPosition = 0.0;
            level = velocity;
            tailOff = 0.0f;
            isPlaying = true;
            
            // 获取样本的根音符（从SFZ文件中的pitch_keycenter）
            int sampleRootNote = pianoSound->getRootNoteForMidiNote(midiNoteNumber);
            
            // 计算音高比率 - 对钢琴应用采样率修正
            double sampleSampleRate = pianoSound->getSampleRateForMidiNote(midiNoteNumber);
            double currentSampleRate = getSampleRate();
            double noteFreq = juce::MidiMessage::getMidiNoteInHertz(midiNoteNumber);
            double sampleFreq = juce::MidiMessage::getMidiNoteInHertz(sampleRootNote);
            
            // 应用采样率修正：样本采样率 / 当前采样率
            pitchRatio = (noteFreq / sampleFreq) * (sampleSampleRate / currentSampleRate);
            
            // 添加平台特定的调试信息
            #if JUCE_IOS
            DBG("=== iOS DEVICE DEBUG ===");
            #else
            DBG("=== SIMULATOR DEBUG ===");
            #endif
            
            DBG("Successfully started piano note - sample length: " + juce::String(currentSample->getNumSamples()) + 
                ", pitch ratio: " + juce::String(pitchRatio) + 
                ", sample root note: " + juce::String(sampleRootNote) +
                ", MIDI note: " + juce::String(midiNoteNumber) +
                ", note freq: " + juce::String(noteFreq) +
                ", sample freq: " + juce::String(sampleFreq) +
                ", sample sample rate: " + juce::String(sampleSampleRate) +
                ", current sample rate: " + juce::String(currentSampleRate));
        }
        else
        {
            DBG("Error: Could not find sample for MIDI note " + juce::String(midiNoteNumber));
            isPlaying = false;
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
    if (!isVoiceActive() || currentSample == nullptr)
        return;
    
    auto localLevel = level * volume;
    
    while (--numSamples >= 0)
    {
        float envGain = 1.0f;
        
        if (tailOff > 0.0f)
        {
            tailOff *= 0.998f; // 更快的淡出速度 (之前是0.9995f)
            envGain *= tailOff;
            
            if (tailOff < 0.01f) // 稍微提高停止阈值，更快停止
            {
                clearCurrentNote();
                isPlaying = false;
                break;
            }
        }
        
        // 从样本中读取音频数据
        int sampleIndex = (int)currentPosition;
        if (sampleIndex < currentSample->getNumSamples())
        {
            float sample = currentSample->getSample(0, sampleIndex) * localLevel * envGain;
            
            for (int channel = 0; channel < outputBuffer.getNumChannels(); ++channel)
            {
                outputBuffer.addSample(channel, startSample, sample);
            }
        }
        else
        {
            // 样本播放完毕
            clearCurrentNote();
            isPlaying = false;
            break;
        }
        
        currentPosition += pitchRatio;
        ++startSample;
    }
}

void PianoVoice::pitchWheelMoved(int)
{
}

void PianoVoice::controllerMoved(int, int)
{
} 
#include "SineVoice.h"

bool SineVoice::canPlaySound (juce::SynthesiserSound* sound)
{
    return dynamic_cast<DummySound*> (sound) != nullptr;
}

void SineVoice::startNote (int midiNoteNumber, float velocity, juce::SynthesiserSound*, int)
{
    currentAngle = 0.0;
    angleDelta = juce::MathConstants<double>::twoPi *
                 juce::MidiMessage::getMidiNoteInHertz (midiNoteNumber) /
                 getSampleRate();
    level = velocity;
    tailOff = 0.0;
    isPlaying = true;
    sampleCount = 0;
}

void SineVoice::stopNote (float, bool allowTailOff)
{
    if (allowTailOff)
        tailOff = 1.0;
    else
        clearCurrentNote();
    isPlaying = false;
}

void SineVoice::renderNextBlock (juce::AudioBuffer<float>& buffer, int startSample, int numSamples)
{
    if (!isVoiceActive()) return;
    auto localLevel = level * volume;
    int attackSamples = int (0.01f * getSampleRate());
    while (--numSamples >= 0)
    {
        float envGain = (sampleCount < attackSamples)
                        ? (float) sampleCount / attackSamples : 1.0f;
        if (tailOff > 0.0f)
        {
            tailOff *= 0.995f; // 更快的淡出速度 (之前是0.99f)
            envGain *= tailOff;
            if (tailOff < 0.01f) // 稍微提高停止阈值，更快停止
            {
                clearCurrentNote();
                break;
            }
        }
        float sample = std::sin (currentAngle) * localLevel * envGain;
        for (int ch = 0; ch < buffer.getNumChannels(); ++ch)
            buffer.addSample (ch, startSample, sample);
        currentAngle += angleDelta;
        ++startSample;
        ++sampleCount;
    }
}

void SineVoice::pitchWheelMoved (int) {}
void SineVoice::controllerMoved (int, int) {}
void SineVoice::setVolume (float newVolume) { volume = newVolume; } 
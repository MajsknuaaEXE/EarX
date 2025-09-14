#pragma once
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_core/juce_core.h>
#include "DummySound.h"

class SineVoice : public juce::SynthesiserVoice
{
public:
    bool canPlaySound (juce::SynthesiserSound* sound) override;
    void startNote (int midiNoteNumber, float velocity, juce::SynthesiserSound*, int) override;
    void stopNote (float, bool allowTailOff) override;
    void renderNextBlock (juce::AudioBuffer<float>& buffer, int startSample, int numSamples) override;
    void pitchWheelMoved (int) override;
    void controllerMoved (int, int) override;
    void setVolume (float newVolume);
private:
    double currentAngle = 0.0, angleDelta = 0.0;
    float level = 0.0f, tailOff = 0.0f, volume = 0.2f;
    int sampleCount = 0;
    bool isPlaying = false;
}; 
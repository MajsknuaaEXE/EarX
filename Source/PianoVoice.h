#pragma once
#include <JuceHeader.h>
#include "PianoSound.h"

class PianoVoice : public juce::SynthesiserVoice
{
public:
    PianoVoice();
    
    bool canPlaySound(juce::SynthesiserSound* sound) override;
    void startNote(int midiNoteNumber, float velocity, juce::SynthesiserSound* sound, int currentPitchWheelPosition) override;
    void stopNote(float velocity, bool allowTailOff) override;
    void renderNextBlock(juce::AudioBuffer<float>& outputBuffer, int startSample, int numSamples) override;
    void pitchWheelMoved(int newPitchWheelValue) override;
    void controllerMoved(int controllerNumber, int newControllerValue) override;
    
    void setVolume(float newVolume) { volume = newVolume; }
    
private:
    juce::AudioBuffer<float>* currentSample = nullptr;
    double currentPosition = 0.0;
    double pitchRatio = 1.0;
    float level = 0.0f;
    float tailOff = 0.0f;
    float volume = 0.2f;
    bool isPlaying = false;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PianoVoice)
}; 
#pragma once
#include <juce_audio_basics/juce_audio_basics.h>

class DummySound : public juce::SynthesiserSound
{
public:
    bool appliesToNote (int) override;
    bool appliesToChannel (int) override;
    void setEnabled(bool e) { enabled = e; }
    bool isEnabled() const { return enabled; }
private:
    std::atomic<bool> enabled { true };
}; 

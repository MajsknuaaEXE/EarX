#pragma once
#include <JuceHeader.h>

class DummySound : public juce::SynthesiserSound
{
public:
    bool appliesToNote (int) override;
    bool appliesToChannel (int) override;
}; 
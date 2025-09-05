#pragma once
#include <JuceHeader.h>

class LightIndicator : public juce::Component
{
public:
    void setOn (bool shouldBeOn);
    void paint (juce::Graphics& g) override;
private:
    bool isOn = false;
}; 
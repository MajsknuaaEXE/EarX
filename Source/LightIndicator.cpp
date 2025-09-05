#include "LightIndicator.h"

void LightIndicator::setOn (bool shouldBeOn)
{
    isOn = shouldBeOn;
    repaint();
}

void LightIndicator::paint (juce::Graphics& g)
{
    g.setColour (isOn ? juce::Colours::yellow : juce::Colours::darkgrey);
    g.fillEllipse (getLocalBounds().toFloat());
} 
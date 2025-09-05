#pragma once
#include <JuceHeader.h>

class EarxLookAndFeel : public juce::LookAndFeel_V4
{
public:
    EarxLookAndFeel();
    void drawBackground(juce::Graphics& g, juce::Component& component);
    void drawLinearSlider(juce::Graphics& g, int x, int y, int width, int height,
                          float sliderPos, float, float,
                          const juce::Slider::SliderStyle, juce::Slider& slider) override;
    void drawToggleButton(juce::Graphics& g, juce::ToggleButton& button,
                          bool shouldDrawButtonAsHighlighted, bool shouldDrawButtonAsDown) override;
    void drawLight(juce::Graphics& g, juce::Rectangle<float> bounds, bool isOn);
}; 
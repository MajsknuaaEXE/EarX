#pragma once
#include <JuceHeader.h>
#include <functional>

class EarxSplashScreen : public juce::Component, private juce::Timer
{
public:
    EarxSplashScreen(std::function<void()> onFinishedCallback);
    void paint (juce::Graphics& g) override;
    void timerCallback() override;
private:
    std::function<void()> onFinished;
    float alpha = 1.0f;
    int waitCounter = 0;
}; 
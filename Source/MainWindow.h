#pragma once
#include <JuceHeader.h>
#include "SplashScreen.h"
#include "MainComponent.h"

class MainWindow : public juce::DocumentWindow
{
public:
    MainWindow (juce::String name);
    void closeButtonPressed() override;
}; 
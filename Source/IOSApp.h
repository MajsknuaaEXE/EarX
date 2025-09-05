#pragma once
#include <JuceHeader.h>
#include "MainWindow.h"

class IOSApp : public juce::JUCEApplication
{
public:
    const juce::String getApplicationName() override;
    const juce::String getApplicationVersion() override;
    bool moreThanOneInstanceAllowed() override;
    void initialise (const juce::String&) override;
    void shutdown() override;
private:
    std::unique_ptr<MainWindow> mainWindow;
}; 
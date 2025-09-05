#include "MainWindow.h"

MainWindow::MainWindow (juce::String name)
    : juce::DocumentWindow (name, juce::Colours::black, DocumentWindow::allButtons)
{
    setUsingNativeTitleBar (true);
    auto display = juce::Desktop::getInstance().getDisplays().getPrimaryDisplay();
    auto screenBounds = display->userArea;
    auto splash = new EarxSplashScreen([this]{
        auto bounds = getLocalBounds();
        setContentOwned(new MainComponent(), true);
        getContentComponent()->setBounds(bounds);
    });
    splash->setSize(screenBounds.getWidth(), screenBounds.getHeight());
    setContentOwned(splash, true);
    setSize(screenBounds.getWidth(), screenBounds.getHeight());
    setResizable(true, false);
    setVisible(true);
    splash->repaint();
}

void MainWindow::closeButtonPressed()
{
    juce::JUCEApplication::getInstance()->systemRequestedQuit();
} 
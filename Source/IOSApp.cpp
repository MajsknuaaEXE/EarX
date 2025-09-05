#include "IOSApp.h"
 
const juce::String IOSApp::getApplicationName() { return "Earx"; }
const juce::String IOSApp::getApplicationVersion() { return "0.2.1"; }
bool IOSApp::moreThanOneInstanceAllowed() { return false; }
void IOSApp::initialise (const juce::String&) { mainWindow.reset (new MainWindow (getApplicationName())); }
void IOSApp::shutdown() { mainWindow = nullptr; } 
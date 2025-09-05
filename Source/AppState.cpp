#include "AppState.h"

AppState::AppState()
{
    DBG("AppState initialized");
}

AppState::~AppState()
{
    listeners.clear();
}

void AppState::addListener(Listener* listener)
{
    listeners.add(listener);
}

void AppState::removeListener(Listener* listener)
{
    listeners.remove(listener);
}

void AppState::notifyAudioStateChanged()
{
    listeners.call([](Listener& l) { l.audioStateChanged(); });
}

void AppState::notifyInteractionStateChanged()
{
    listeners.call([](Listener& l) { l.interactionStateChanged(); });
}

void AppState::notifyPlaybackStateChanged()
{
    listeners.call([](Listener& l) { l.playbackStateChanged(); });
}

void AppState::notifySystemStateChanged()
{
    listeners.call([](Listener& l) { l.systemStateChanged(); });
}

juce::Array<bool> AppState::getScalePattern(int scaleIndex) const
{
    juce::Array<bool> pattern;
    pattern.resize(12);
    
    // 所有音阶的音程模式（相对于根音）
    static const int scalePatterns[][12] = {
        // 大调音阶 (0-11)
        {1,0,1,0,1,1,0,1,0,1,0,1}, // C Major
        {0,1,0,1,0,1,1,0,1,0,1,0}, // Db Major
        {0,0,1,0,1,0,1,1,0,1,0,1}, // D Major
        {1,0,0,1,0,1,0,1,1,0,1,0}, // Eb Major
        {0,1,0,0,1,0,1,0,1,1,0,1}, // E Major
        {1,0,1,0,0,1,0,1,0,1,1,0}, // F Major
        {0,1,0,1,0,0,1,0,1,0,1,1}, // F# Major
        {1,0,1,0,1,0,0,1,0,1,0,1}, // G Major
        {1,1,0,1,0,1,0,0,1,0,1,0}, // Ab Major
        {0,1,1,0,1,0,1,0,0,1,0,1}, // A Major
        {1,0,1,1,0,1,0,1,0,0,1,0}, // Bb Major
        {0,1,0,1,1,0,1,0,1,0,0,1}, // B Major
        
        // 小调音阶 (12-23)
        {1,0,1,1,0,1,0,1,1,0,1,0}, // c minor
        {0,1,0,1,1,0,1,0,1,1,0,1}, // c# minor
        {1,0,1,0,1,1,0,1,0,1,1,0}, // d minor
        {0,1,0,1,0,1,1,0,1,0,1,1}, // eb minor
        {1,0,1,0,1,0,1,1,0,1,0,1}, // e minor
        {1,1,0,1,0,1,0,1,1,0,1,0}, // f minor
        {0,1,1,0,1,0,1,0,1,1,0,1}, // f# minor
        {1,0,1,1,0,1,0,1,0,1,1,0}, // g minor
        {0,1,0,1,1,0,1,0,1,0,1,1}, // g# minor
        {1,0,1,0,1,1,0,1,0,1,0,1}, // a minor
        {1,1,0,1,0,1,1,0,1,0,1,0}, // bb minor
        {0,1,1,0,1,0,1,1,0,1,0,1}  // b minor
    };
    
    if (scaleIndex >= 0 && scaleIndex < 24)
    {
        for (int i = 0; i < 12; ++i)
        {
            pattern.set(i, scalePatterns[scaleIndex][i] == 1);
        }
    }
    
    return pattern;
}

const juce::StringArray& AppState::getScaleNames()
{
    static juce::StringArray scaleNames = {
        "C Maj", "bD Maj", "D Maj", "bE Maj", "E Maj", "F Maj", 
        "#F Maj", "G Maj", "bA Maj", "A Maj", "bB Maj", "B Maj",
        "c min", "#c min", "d min", "be min", "e min", "f min", 
        "#f min", "g min", "#g min", "a min", "bb min", "b min"
    };
    return scaleNames;
} 
#pragma once
#include <JuceHeader.h>

/**
 * 应用程序状态管理器
 * 集中管理所有应用状态，支持观察者模式
 */
class AppState
{
public:
    // 音频相关状态
    struct AudioState
    {
        bool isPianoMode = false;
        float masterVolume = 0.2f;
        bool isSwitchingTimbre = false;
        float currentFadeVolume = 1.0f;
        float targetVolume = 0.2f;
        bool pendingTimbreSwitch = false;
        bool nextIsPianoMode = false;
        
        static constexpr float FADE_STEP = 0.05f;
        static constexpr float FADE_DURATION_MS = 150.0f;
    } audio;
    
    // UI交互状态
    struct InteractionState
    {
        int longPressedButtonIndex = -1;
        juce::Array<double> buttonPressStartTimes;
        bool shouldPlayCenterNote = false;
        int currentPlayingButtonIndex = -1;
        
        // 模式相关
        enum class Mode { Custom, Scale };
        Mode currentMode = Mode::Custom;
        int selectedScaleIndex = 0; // C Major 默认
        
        static constexpr double LONG_PRESS_DURATION = 500.0;
        
        InteractionState()
        {
            buttonPressStartTimes.resize(12);
            for (int i = 0; i < 12; ++i)
                buttonPressStartTimes.set(i, 0.0);
        }
    } interaction;
    
    // 播放相关状态
    struct PlaybackState
    {
        double bpm = 120.0;
        float noteDuration = 100.0f; // 百分比
        bool stopTrigger = false;
        double lastTriggerTime = 0;
        int lastMidiNote = -1;
        int lastSemitone = -1;
        
        struct ActiveNote
        {
            int note;
            int semitone;
            double endTime;
        };
        juce::Array<ActiveNote> activeNotes;
    } playback;
    
    // 系统状态
    struct SystemState
    {
        double shutdownEndTime = 0;
        bool isInitialized = false;
        bool midiOutputEnabled = true;
        int shutdownDurationMinutes = 30; // 默认30分钟
        bool autoShutdownEnabled = false; // 自动关闭开关
        
        // 可选的关闭时长（分钟）
        static constexpr int SHUTDOWN_OPTIONS[4] = {15, 25, 35, 60};
        static constexpr int DEFAULT_SHUTDOWN_DURATION = 30;
    } system;
    
    // 状态变更通知接口
    class Listener
    {
    public:
        virtual ~Listener() = default;
        virtual void audioStateChanged() {}
        virtual void interactionStateChanged() {}
        virtual void playbackStateChanged() {}
        virtual void systemStateChanged() {}
    };
    
    AppState();
    ~AppState();
    
    // 监听器管理
    void addListener(Listener* listener);
    void removeListener(Listener* listener);
    
    // 状态变更通知
    void notifyAudioStateChanged();
    void notifyInteractionStateChanged();
    void notifyPlaybackStateChanged();
    void notifySystemStateChanged();
    
    // 音阶相关方法
    juce::Array<bool> getScalePattern(int scaleIndex) const;
    static const juce::StringArray& getScaleNames();
    
private:
    juce::ListenerList<Listener> listeners;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(AppState)
}; 
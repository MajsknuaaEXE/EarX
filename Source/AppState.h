#pragma once
#include <juce_core/juce_core.h>
#include <juce_data_structures/juce_data_structures.h>

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
        
        // 只保留自定义模式
        
        // 半音激活状态 (0-11对应C到B)
        juce::Array<bool> customSemitones;
        
        // 每个音级的音名选择状态 (12个音级 x 每个音级的多个音名选项)
        // semitoneNoteNames[semitoneIndex][noteNameIndex] = isSelected
        juce::Array<juce::Array<bool>> semitoneNoteNames;
        
        static constexpr double LONG_PRESS_DURATION = 500.0;
        
        InteractionState()
        {
            buttonPressStartTimes.resize(12);
            for (int i = 0; i < 12; ++i)
                buttonPressStartTimes.set(i, 0.0);
            
            // 初始化半音状态，默认激活全十二半音 C, #C, D, bE, E, F, #F, G, bA, A, bB, B
            customSemitones.resize(12);
            for (int i = 0; i < 12; ++i)
            {
                // 激活所有十二个半音
                customSemitones.set(i, true);
            }
            
            // 初始化音名选择状态
            initializeSemitoneNoteNames();
        }
        
        void initializeSemitoneNoteNames();
        juce::StringArray getNoteNamesForSemitone(int semitone) const;
        juce::Array<int> getSelectedNoteNamesForSemitone(int semitone) const;
    } interaction;
    
    // 播放相关状态
    struct PlaybackState
    {
        double bpm = 30.0;
        float noteDuration = 100.0f; // 百分比
        bool stopTrigger = false;
        double lastTriggerTime = 0;
        int lastMidiNote = -1;
        int lastSemitone = -1;
        
        // 自动播放状态
        bool autoPlayEnabled = false;
        double lastAutoPlayTime = 0; // 上次自动播放的时间（毫秒）
        
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
        
        // 训练定时器
        bool timerEnabled = false;
        int timerDurationMinutes = 25; // 默认25分钟
        double timerStartTime = 0;
        
        // 可选的关闭时长（分钟）
        static constexpr int SHUTDOWN_OPTIONS[4] = {15, 25, 35, 60};
        static constexpr int DEFAULT_SHUTDOWN_DURATION = 30;
        static constexpr int TIMER_OPTIONS[3] = {1, 35, 60}; // 第一个改为1分钟，实际会设为10秒
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
    
    // 删除所有scale相关方法
    
    // 音名选择相关方法
    void setSemitoneNoteName(int semitone, int noteNameIndex, bool selected);
    bool isSemitoneNoteNameSelected(int semitone, int noteNameIndex) const;
    juce::String getSelectedNoteNamesDisplayForSemitone(int semitone) const;
    
private:
    juce::ListenerList<Listener> listeners;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(AppState)
}; 
#pragma once
#include <juce_core/juce_core.h>
#include <juce_gui_basics/juce_gui_basics.h>
#include "AppState.h"  // 完整包含而不是前向声明

class AudioController;

/**
 * 播放引擎 - 负责音符播放逻辑和算法
 * 职责：
 * - 音符播放算法
 * - 定时播放管理
 * - 音符序列生成
 * - 播放状态跟踪
 */
class PlaybackEngine : public AppState::Listener
{
public:
    PlaybackEngine(AppState* appState, AudioController* audioController);
    virtual ~PlaybackEngine() override;
    
    // 播放控制
    void playNextNote();
    void playNextNote(const juce::Array<int>& activeIndices); // 重载版本，接受活跃按钮索引
    void stopNote(int midiNote);
    void stopAllNotes();
    
    // 播放状态管理
    void updateActiveNotes(double currentTime);
    void updateNoteDisplay(juce::Label& noteLabel);
    
    // 设置参数
    void setBPM(double bpm);
    void setNoteDuration(float duration);
    
    // AppState::Listener 实现
    virtual void playbackStateChanged() override;
    
private:
    AppState* appState;
    AudioController* audioController;
    
    // 音符名称常量
    static const char* NOTE_NAMES[12];
    
    // 辅助方法
    juce::Array<int> getActiveNoteIndices();
    int selectNextNote(const juce::Array<int>& onIndices);
    void setCurrentPlayingNote(int semitone);
    void clearCurrentPlayingNote(int semitone);
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PlaybackEngine)
}; 
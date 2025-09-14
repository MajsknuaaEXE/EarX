#pragma once
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_audio_devices/juce_audio_devices.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <juce_audio_utils/juce_audio_utils.h>
#include <juce_core/juce_core.h>
#include "AppState.h"  // 完整包含而不是前向声明
#include "PianoSound.h"
#include "PianoVoice.h"
#include "SineVoice.h"
#include "DummySound.h"

/**
 * 音频控制器 - 负责管理所有音频相关逻辑
 * 职责：
 * - 合成器设置和管理
 * - 音色切换（Piano/Sine）
 * - 音量控制和淡入淡出
 * - 音符播放和停止
 */
class AudioController
{
public:
    AudioController(AppState* appState);
    ~AudioController();
    
    // 初始化音频系统
    void initialize(double sampleRate);
    
    // 音频渲染
    void renderNextBlock(juce::AudioBuffer<float>& buffer, 
                        const juce::MidiBuffer& midiBuffer,
                        int startSample, int numSamples);
    
    // 音色管理
    void switchTimbre(bool isPianoMode);
    void setupSynthesiser();
    void preloadPianoSamples();
    
    // 音量控制
    void setMasterVolume(float volume);
    void applyVolumeToVoices(float volume);
    
    // 平滑音色切换
    void startTimbreFadeOut(bool targetIsPianoMode);
    void performTimbreSwitch();
    void startTimbreFadeIn();
    void updateFadeTransition();
    
    // 音符播放
    void playNote(int midiNote, float velocity);
    void stopNote(int midiNote);
    void stopAllNotes();
    
    // 获取合成器引用（用于MainComponent的getNextAudioBlock）
    juce::Synthesiser& getSynthesiser() { return synth; }
    
    // 采样加载状态查询
    bool arePianoSamplesLoaded() const;
    
private:
    AppState* appState;
    juce::Synthesiser synth;
    double currentSampleRate = 44100.0;
    bool soundsInitialized = false;
    juce::CriticalSection synthMutex; // 保护对 synth 的并发访问
    DummySound* dummySound = nullptr;
    PianoSound* pianoSound = nullptr;
    
    // SFZ文件路径辅助方法
    juce::File getSFZFile() const;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(AudioController)
}; 

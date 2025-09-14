#pragma once
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <juce_core/juce_core.h>
#include <juce_events/juce_events.h>
#include <memory>

// 钢琴音色类
class PianoSound : public juce::SynthesiserSound
{
public:
    PianoSound();
    ~PianoSound() override;
    
    bool appliesToNote(int midiNoteNumber) override;
    bool appliesToChannel(int midiChannelNumber) override;
    void setEnabled(bool e) { enabled = e; }
    bool isEnabled() const { return enabled; }
    
    // 加载SFZ音色
    bool loadSFZ(const juce::File& sfzFile);
    
    // 异步加载SFZ音色
    void loadSFZAsync(const juce::File& sfzFile, std::function<void(bool, int, int)> progressCallback = nullptr);
    
    // 检查是否正在加载
    bool isLoading() const { return loadingThread && loadingThread->isThreadRunning(); }
    
    // 检查是否已加载完成
    bool isLoaded() const { return samplesLoaded.load(); }
    
    // 获取加载进度 (0-100)
    int getLoadingProgress() const { return loadingProgress.load(); }
    
    // 获取指定音符的音频数据
    juce::AudioBuffer<float>* getSampleForNote(int midiNote);
    
    // 获取指定MIDI音符对应样本的根音符
    int getRootNoteForMidiNote(int midiNote);
    
    // 获取指定MIDI音符对应样本的采样率
    double getSampleRateForMidiNote(int midiNote);
    
private:
    struct SampleData
    {
        std::shared_ptr<juce::AudioBuffer<float>> audioBuffer; // 共享底层样本缓存，避免重复加载
        int rootNote;
        int loKey;
        int hiKey;
        double sampleRate;
    };
    
    juce::OwnedArray<SampleData> samples;
    std::atomic<bool> samplesLoaded { false };
    std::atomic<bool> enabled { true };
    
    // 异步加载支持
    class LoadingThread : public juce::Thread
    {
    public:
        LoadingThread(PianoSound* owner) : Thread("PianoSoundLoader"), pianoSound(owner) {}
        void run() override { if (pianoSound) pianoSound->runLoadingThread(); }
    private:
        PianoSound* pianoSound;
    };
    
    std::unique_ptr<LoadingThread> loadingThread;
    std::atomic<int> loadingProgress { 0 };
    std::function<void(bool, int, int)> progressCallback;
    juce::File pendingSFZFile;
    
    // 加载线程实现
    void runLoadingThread();
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PianoSound)
}; 

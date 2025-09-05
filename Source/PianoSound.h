#pragma once
#include <JuceHeader.h>

// 钢琴音色类
class PianoSound : public juce::SynthesiserSound
{
public:
    PianoSound();
    ~PianoSound() override;
    
    bool appliesToNote(int midiNoteNumber) override;
    bool appliesToChannel(int midiChannelNumber) override;
    
    // 加载SFZ音色
    bool loadSFZ(const juce::File& sfzFile);
    
    // 获取指定音符的音频数据
    juce::AudioBuffer<float>* getSampleForNote(int midiNote);
    
    // 获取指定MIDI音符对应样本的根音符
    int getRootNoteForMidiNote(int midiNote);
    
    // 获取指定MIDI音符对应样本的采样率
    double getSampleRateForMidiNote(int midiNote);
    
private:
    struct SampleData
    {
        std::unique_ptr<juce::AudioBuffer<float>> audioBuffer;
        int rootNote;
        int loKey;
        int hiKey;
        double sampleRate;
    };
    
    juce::OwnedArray<SampleData> samples;
    bool isLoaded = false;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(PianoSound)
}; 
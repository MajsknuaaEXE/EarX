#include "PianoSound.h"

PianoSound::PianoSound()
{
}

PianoSound::~PianoSound()
{
}

bool PianoSound::appliesToNote(int midiNoteNumber)
{
    return isLoaded && midiNoteNumber >= 21 && midiNoteNumber <= 108; // 钢琴音域
}

bool PianoSound::appliesToChannel(int midiChannelNumber)
{
    return true;
}

bool PianoSound::loadSFZ(const juce::File& sfzFile)
{
    if (!sfzFile.exists())
    {
        DBG("SFZ file does not exist: " + sfzFile.getFullPathName());
        return false;
    }
    
    DBG("Starting SFZ file parsing: " + sfzFile.getFullPathName());
    
    samples.clear();
    
    // 简化的SFZ解析 - 只处理基本的region映射
    juce::StringArray lines;
    sfzFile.readLines(lines);
    
    DBG("SFZ file has " + juce::String(lines.size()) + " lines");
    
    int currentLoKey = -1, currentHiKey = -1, currentRootNote = -1;
    juce::String currentSamplePath;
    int regionCount = 0;
    
    for (const auto& line : lines)
    {
        juce::String trimmedLine = line.trim();
        
        if (trimmedLine.startsWith("<region>"))
        {
            regionCount++;
            // 重置当前region参数
            currentLoKey = currentHiKey = currentRootNote = -1;
            currentSamplePath = "";
        }
        else if (trimmedLine.startsWith("lokey="))
        {
            currentLoKey = trimmedLine.substring(6).getIntValue();
        }
        else if (trimmedLine.startsWith("hikey="))
        {
            currentHiKey = trimmedLine.substring(6).getIntValue();
        }
        else if (trimmedLine.startsWith("pitch_keycenter="))
        {
            currentRootNote = trimmedLine.substring(16).getIntValue();
        }
        else if (trimmedLine.startsWith("sample="))
        {
            currentSamplePath = trimmedLine.substring(7);
            
            // 如果所有参数都设置了，加载这个sample
            if (currentLoKey >= 0 && currentHiKey >= 0 && currentRootNote >= 0)
            {
                juce::File sampleFile = sfzFile.getParentDirectory().getChildFile(currentSamplePath);
                
                DBG("Trying to load sample: " + sampleFile.getFullPathName() + 
                    " (lokey=" + juce::String(currentLoKey) + 
                    ", hikey=" + juce::String(currentHiKey) + 
                    ", root=" + juce::String(currentRootNote) + ")");
                
                if (sampleFile.exists())
                {
                    juce::AudioFormatManager formatManager;
                    formatManager.registerBasicFormats();
                    
                    std::unique_ptr<juce::AudioFormatReader> reader(formatManager.createReaderFor(sampleFile));
                    
                    if (reader != nullptr)
                    {
                        auto sampleData = new SampleData();
                        sampleData->audioBuffer = std::make_unique<juce::AudioBuffer<float>>(
                            (int)reader->numChannels, (int)reader->lengthInSamples);
                        sampleData->rootNote = currentRootNote;
                        sampleData->loKey = currentLoKey;
                        sampleData->hiKey = currentHiKey;
                        sampleData->sampleRate = reader->sampleRate;
                        
                        reader->read(sampleData->audioBuffer.get(), 0, (int)reader->lengthInSamples, 0, true, true);
                        
                        samples.add(sampleData);
                        DBG("Successfully loaded sample: " + sampleFile.getFileName() + 
                            " (sampleRate=" + juce::String(reader->sampleRate) + 
                            ", length=" + juce::String(reader->lengthInSamples) + ")");
                    }
                    else
                    {
                        DBG("Could not create audio reader for: " + sampleFile.getFileName());
                    }
                }
                else
                {
                    DBG("Sample file does not exist: " + sampleFile.getFullPathName());
                }
            }
        }
    }
    
    isLoaded = samples.size() > 0;
    DBG("SFZ loading completed. Processed " + juce::String(regionCount) + " regions, successfully loaded " + juce::String(samples.size()) + " samples");
    return isLoaded;
}

juce::AudioBuffer<float>* PianoSound::getSampleForNote(int midiNote)
{
    for (auto* sample : samples)
    {
        if (midiNote >= sample->loKey && midiNote <= sample->hiKey)
        {
            return sample->audioBuffer.get();
        }
    }
    return nullptr;
}

int PianoSound::getRootNoteForMidiNote(int midiNote)
{
    for (auto* sample : samples)
    {
        if (midiNote >= sample->loKey && midiNote <= sample->hiKey)
        {
            return sample->rootNote;
        }
    }
    return 60; // 默认返回C4 (MIDI note 60)
}

double PianoSound::getSampleRateForMidiNote(int midiNote)
{
    for (auto* sample : samples)
    {
        if (midiNote >= sample->loKey && midiNote <= sample->hiKey)
        {
            return sample->sampleRate;
        }
    }
    return 44100.0; // 默认返回标准采样率
} 
#include "PianoSound.h"
#include <unordered_map>

// 全局样本缓存：按绝对路径缓存已解码的音频数据，避免重复解码导致切换时卡顿/爆音
static std::unordered_map<std::string, std::shared_ptr<juce::AudioBuffer<float>>> gSampleCache;
static std::unordered_map<std::string, double> gSampleRateCache;

PianoSound::PianoSound()
{
    // 构造函数不自动加载，需要显式调用 loadSFZ
    samplesLoaded = false;
    loadingThread = std::make_unique<LoadingThread>(this);
    DBG("PianoSound initialized - ready to load SFZ");
}

PianoSound::~PianoSound()
{
    if (loadingThread && loadingThread->isThreadRunning())
    {
        loadingThread->signalThreadShouldExit();
        loadingThread->waitForThreadToExit(2000);
    }
}

bool PianoSound::appliesToNote(int midiNoteNumber)
{
    return enabled.load() && samplesLoaded.load() && midiNoteNumber >= 21 && midiNoteNumber <= 108; // 钢琴音域
}

bool PianoSound::appliesToChannel(int midiChannelNumber)
{
    return enabled.load();
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
    
    // 解析SFZ文件 - 支持新格式 (key= 和 region 内联属性)
    juce::String content = sfzFile.loadFileAsString();
    
    DBG("SFZ file content length: " + juce::String(content.length()));
    
    // 逐行扫描 <region>，不能用字符集切分（fromTokens 会把 "<region>" 拆成单字符分隔）
    juce::StringArray lines = juce::StringArray::fromLines(content);
    int regionCount = 0;
    
    // 使用全局缓存，避免重复解码

    for (const auto& lineRegionHack : lines)
    {
        juce::String regionContent = lineRegionHack.trim();
        if (regionContent.isEmpty()) continue;
        if (! regionContent.startsWith("<region>")) continue;
        
        regionCount++;
        
        // 解析每行的参数
        int currentLoKey = -1, currentHiKey = -1, currentRootNote = -1;
        juce::String currentSamplePath;
        
        juce::StringArray regionLines = juce::StringArray::fromLines(regionContent);
        
        for (const auto& line : regionLines)
        {
            juce::String trimmedLine = line.trim();
            if (trimmedLine.isEmpty() || trimmedLine.startsWith("//")) continue;
            
            // 解析内联属性 (sample=path key=60 pitch_keycenter=60)
            juce::StringArray tokens = juce::StringArray::fromTokens(trimmedLine, " ", "");
            
            for (const auto& token : tokens)
            {
                if (token.startsWith("sample="))
                {
                    currentSamplePath = token.substring(7);
                    // 规范化路径：去掉引号并将反斜杠改为正斜杠
                    currentSamplePath = currentSamplePath.unquoted();
                    currentSamplePath = currentSamplePath.replaceCharacters("\\", "/");
                }
                else if (token.startsWith("key="))
                {
                    int keyValue = token.substring(4).getIntValue();
                    currentLoKey = currentHiKey = keyValue;
                }
                else if (token.startsWith("lokey="))
                {
                    currentLoKey = token.substring(6).getIntValue();
                }
                else if (token.startsWith("hikey="))
                {
                    currentHiKey = token.substring(6).getIntValue();
                }
                else if (token.startsWith("pitch_keycenter="))
                {
                    currentRootNote = token.substring(16).getIntValue();
                }
            }
        }
        
        // 加载样本
        if (currentLoKey >= 0 && currentHiKey >= 0 && currentRootNote >= 0 && currentSamplePath.isNotEmpty())
        {
            // 处理相对路径
            juce::File basePath = sfzFile.getParentDirectory();
            juce::File sampleFile;
            
            // 处理 ../ 前缀（Windows 风格 ..\ 已被替换为 ../）
            if (currentSamplePath.startsWith("../"))
            {
                sampleFile = basePath.getParentDirectory().getChildFile(currentSamplePath.substring(3));
            }
            else
            {
                sampleFile = basePath.getChildFile(currentSamplePath);
            }
            
            // 若未找到，兼容“扁平化复制资源”的情况：按文件名在 SFZ 所在目录直接查找
            if (! sampleFile.exists())
            {
                auto fileNameOnly = juce::File(currentSamplePath).getFileName();
                auto fallback = basePath.getChildFile(fileNameOnly);
                if (fallback.exists()) {
                    DBG("Fallback sample path hit (flattened bundle): " + fallback.getFullPathName());
                    sampleFile = fallback;
                }
            }
            
            DBG("Trying to load sample: " + sampleFile.getFullPathName() + 
                " (lokey=" + juce::String(currentLoKey) + 
                ", hikey=" + juce::String(currentHiKey) + 
                ", root=" + juce::String(currentRootNote) + ")");
            
            if (sampleFile.exists())
            {
                auto absPath = sampleFile.getFullPathName().toStdString();
                std::shared_ptr<juce::AudioBuffer<float>> bufferPtr;
                double loadedSampleRate = 0.0;

                auto it = gSampleCache.find(absPath);
                if (it != gSampleCache.end())
                {
                    bufferPtr = it->second;
                }
                else
                {
                    juce::AudioFormatManager formatManager;
                    formatManager.registerBasicFormats();
                    // 基础格式已包含 FLAC（若启用）。不重复注册以避免断言。

                    std::unique_ptr<juce::AudioFormatReader> reader(formatManager.createReaderFor(sampleFile));
                    if (reader != nullptr)
                    {
                        bufferPtr = std::make_shared<juce::AudioBuffer<float>>((int)reader->numChannels,
                                                                               (int)reader->lengthInSamples);
                        reader->read(bufferPtr.get(), 0, (int)reader->lengthInSamples, 0, true, true);
                        gSampleCache.emplace(absPath, bufferPtr);
                        loadedSampleRate = reader->sampleRate;
                        gSampleRateCache.emplace(absPath, loadedSampleRate);
                        DBG("Loaded sample file: " + sampleFile.getFileName() +
                            " (sr=" + juce::String(reader->sampleRate) +
                            ", len=" + juce::String(reader->lengthInSamples) + ")");
                    }
                    else
                    {
                        DBG("Could not create audio reader for: " + sampleFile.getFileName());
                    }
                }

                if (bufferPtr != nullptr)
                {
                    auto sampleData = new SampleData();
                    sampleData->audioBuffer = bufferPtr;
                    sampleData->rootNote = currentRootNote;
                    sampleData->loKey = currentLoKey;
                    sampleData->hiKey = currentHiKey;
                    // 采样率从缓存中读取，找不到则回退到48k
                    if (loadedSampleRate <= 0.0)
                    {
                        auto itSR = gSampleRateCache.find(absPath);
                        if (itSR != gSampleRateCache.end())
                            loadedSampleRate = itSR->second;
                        else
                            loadedSampleRate = 48000.0;
                    }
                    sampleData->sampleRate = loadedSampleRate;
                    samples.add(sampleData);
                }
            }
            else
            {
                DBG("Sample file does not exist: " + sampleFile.getFullPathName());
            }
        }
    }
    
    samplesLoaded.store(samples.size() > 0);
    DBG("SFZ loading completed. Processed " + juce::String(regionCount) + " regions, successfully loaded " + juce::String(samples.size()) + " samples");
    return samplesLoaded.load();
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

void PianoSound::loadSFZAsync(const juce::File& sfzFile, std::function<void(bool, int, int)> callback)
{
    // 停止之前的加载任务
    if (loadingThread && loadingThread->isThreadRunning())
    {
        loadingThread->signalThreadShouldExit();
        loadingThread->waitForThreadToExit(1000);
    }
    
    pendingSFZFile = sfzFile;
    progressCallback = callback;
    loadingProgress = 0;
    
    DBG("Starting async SFZ loading: " + sfzFile.getFullPathName());
    
    loadingThread->startThread();
}

void PianoSound::runLoadingThread()
{
    if (!pendingSFZFile.exists())
    {
        DBG("SFZ file does not exist: " + pendingSFZFile.getFullPathName());
        if (progressCallback) progressCallback(false, 0, 0);
        return;
    }
    
    DBG("[Async] Starting SFZ file parsing: " + pendingSFZFile.getFullPathName());
    
    // 暂时清空现有样本
    juce::OwnedArray<SampleData> tempSamples;
    
    // 解析SFZ文件
    juce::String content = pendingSFZFile.loadFileAsString();
    juce::StringArray lines = juce::StringArray::fromLines(content);
    int regionCount = 0;
    int processedRegions = 0;
    
    // 首先统计总数
    for (const auto& line : lines)
    {
        if (line.trim().startsWith("<region>")) regionCount++;
    }
    
    DBG("[Async] Found " + juce::String(regionCount) + " regions to process");

    for (const auto& lineRegionHack : lines)
    {
        if (loadingThread->threadShouldExit()) return;
        
        juce::String regionContent = lineRegionHack.trim();
        if (regionContent.isEmpty() || !regionContent.startsWith("<region>")) continue;
        
        processedRegions++;
        
        // 解析每行的参数
        int currentLoKey = -1, currentHiKey = -1, currentRootNote = -1;
        juce::String currentSamplePath;
        
        juce::StringArray regionLines = juce::StringArray::fromLines(regionContent);
        
        for (const auto& line : regionLines)
        {
            juce::String trimmedLine = line.trim();
            if (trimmedLine.isEmpty() || trimmedLine.startsWith("//")) continue;
            
            juce::StringArray tokens = juce::StringArray::fromTokens(trimmedLine, " ", "");
            
            for (const auto& token : tokens)
            {
                if (token.startsWith("sample="))
                {
                    currentSamplePath = token.substring(7).unquoted().replaceCharacters("\\", "/");
                }
                else if (token.startsWith("key="))
                {
                    int keyValue = token.substring(4).getIntValue();
                    currentLoKey = currentHiKey = keyValue;
                }
                else if (token.startsWith("lokey="))
                {
                    currentLoKey = token.substring(6).getIntValue();
                }
                else if (token.startsWith("hikey="))
                {
                    currentHiKey = token.substring(6).getIntValue();
                }
                else if (token.startsWith("pitch_keycenter="))
                {
                    currentRootNote = token.substring(16).getIntValue();
                }
            }
        }
        
        // 加载样本
        if (currentLoKey >= 0 && currentHiKey >= 0 && currentRootNote >= 0 && currentSamplePath.isNotEmpty())
        {
            juce::File basePath = pendingSFZFile.getParentDirectory();
            juce::File sampleFile;
            
            if (currentSamplePath.startsWith("../"))
            {
                sampleFile = basePath.getParentDirectory().getChildFile(currentSamplePath.substring(3));
            }
            else
            {
                sampleFile = basePath.getChildFile(currentSamplePath);
            }
            
            if (!sampleFile.exists())
            {
                auto fileNameOnly = juce::File(currentSamplePath).getFileName();
                auto fallback = basePath.getChildFile(fileNameOnly);
                if (fallback.exists()) sampleFile = fallback;
            }
            
            DBG("[Async] Processing sample " + juce::String(processedRegions) + "/" + 
                juce::String(regionCount) + ": " + sampleFile.getFileName());
            
            if (sampleFile.exists())
            {
                auto absPath = sampleFile.getFullPathName().toStdString();
                std::shared_ptr<juce::AudioBuffer<float>> bufferPtr;
                double loadedSampleRate = 0.0;

                auto it = gSampleCache.find(absPath);
                if (it != gSampleCache.end())
                {
                    bufferPtr = it->second;
                    auto itSR = gSampleRateCache.find(absPath);
                    if (itSR != gSampleRateCache.end())
                        loadedSampleRate = itSR->second;
                    else
                        loadedSampleRate = 48000.0;
                }
                else
                {
                    juce::AudioFormatManager formatManager;
                    formatManager.registerBasicFormats();

                    std::unique_ptr<juce::AudioFormatReader> reader(formatManager.createReaderFor(sampleFile));
                    if (reader != nullptr)
                    {
                        bufferPtr = std::make_shared<juce::AudioBuffer<float>>((int)reader->numChannels,
                                                                               (int)reader->lengthInSamples);
                        reader->read(bufferPtr.get(), 0, (int)reader->lengthInSamples, 0, true, true);
                        gSampleCache.emplace(absPath, bufferPtr);
                        loadedSampleRate = reader->sampleRate;
                        gSampleRateCache.emplace(absPath, loadedSampleRate);
                        DBG("[Async] Loaded: " + sampleFile.getFileName() + " (sr=" + 
                            juce::String(reader->sampleRate) + ", len=" + juce::String(reader->lengthInSamples) + ")");
                    }
                }

                if (bufferPtr != nullptr)
                {
                    auto sampleData = new SampleData();
                    sampleData->audioBuffer = bufferPtr;
                    sampleData->rootNote = currentRootNote;
                    sampleData->loKey = currentLoKey;
                    sampleData->hiKey = currentHiKey;
                    sampleData->sampleRate = loadedSampleRate;
                    tempSamples.add(sampleData);
                }
            }
        }
        
        // 更新进度
        int progress = (processedRegions * 100) / regionCount;
        loadingProgress = progress;
        
        // 为了避免真机上MessageManager::callAsync引起的问题，暂时移除进度回调
        // 加载完成后会有最终回调
        if (progressCallback && processedRegions % 10 == 0)  // 每10个样本输出一次日志
        {
            DBG("[Async] Progress: " + juce::String(progress) + "% (" + juce::String(tempSamples.size()) + " samples)");
        }
        
        // 给主线程一些喘息时间
        juce::Thread::sleep(2);
    }
    
    // 原子性地替换样本数据
    if (!loadingThread->threadShouldExit())
    {
        samples.swapWith(tempSamples);
        samplesLoaded.store(samples.size() > 0);
        loadingProgress = 100;
        
        DBG("[Async] SFZ loading completed. Loaded " + juce::String(samples.size()) + " samples");
        
        if (progressCallback)
        {
            // 直接在后台线程调用完成回调，避免MessageManager::callAsync的问题
            progressCallback(true, 100, samples.size());
        }
    }
} 

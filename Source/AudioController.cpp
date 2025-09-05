#include "AudioController.h"
#include "AppState.h"

AudioController::AudioController(AppState* state) 
    : appState(state)
{
    DBG("AudioController initialized");
}

AudioController::~AudioController()
{
    synth.clearVoices();
    synth.clearSounds();
}

void AudioController::initialize(double sampleRate)
{
    currentSampleRate = sampleRate;
    synth.setCurrentPlaybackSampleRate(sampleRate);
    setupSynthesiser();
    DBG("AudioController initialized with sample rate: " + juce::String(sampleRate));
    
    // 添加详细的采样率调试信息
    DBG("=== AUDIO SYSTEM INFO ===");
    DBG("Current sample rate: " + juce::String(currentSampleRate));
    DBG("Synthesiser sample rate: " + juce::String(synth.getSampleRate()));
    DBG("=== END AUDIO SYSTEM INFO ===");
}

void AudioController::renderNextBlock(juce::AudioBuffer<float>& buffer, 
                                    const juce::MidiBuffer& midiBuffer,
                                    int startSample, int numSamples)
{
    synth.renderNextBlock(buffer, midiBuffer, startSample, numSamples);
}

void AudioController::switchTimbre(bool isPianoMode)
{
    if (appState->audio.isSwitchingTimbre) {
        DBG("Already switching timbre, ignoring request");
        return;
    }
    
    if (isPianoMode == appState->audio.isPianoMode) {
        return; // 已经是目标模式
    }
    
    DBG("Starting smooth timbre switch to: " + juce::String(isPianoMode ? "Piano" : "Sine"));
    
    appState->audio.targetVolume = appState->audio.masterVolume;
    startTimbreFadeOut(isPianoMode);
    appState->notifyAudioStateChanged();
}

void AudioController::setupSynthesiser()
{
    DBG("Starting synthesiser setup, mode: " + juce::String(appState->audio.isPianoMode ? "piano" : "sine"));
    
    // 清除现有的voices和sounds
    synth.clearVoices();
    synth.clearSounds();
    
    if (appState->audio.isPianoMode)
    {
        // 钢琴模式
        DBG("Setting up piano mode");
        for (int i = 0; i < 8; ++i)
            synth.addVoice(new PianoVoice());
        
        // 创建新的PianoSound对象
        auto* pianoSound = new PianoSound();
        
        juce::File sfzFile = getSFZFile();
        if (sfzFile.exists())
        {
            pianoSound->loadSFZ(sfzFile);
        }
        
        synth.addSound(pianoSound);
    }
    else
    {
        // 正弦波模式
        DBG("Setting up sine mode");
        for (int i = 0; i < 8; ++i)
            synth.addVoice(new SineVoice());
        synth.addSound(new DummySound());
    }
    
    // 应用当前音量设置
    if (!appState->audio.isSwitchingTimbre) {
        appState->audio.targetVolume = appState->audio.masterVolume;
        appState->audio.currentFadeVolume = 1.0f;
        applyVolumeToVoices(appState->audio.masterVolume);
    }
    
    DBG("Synthesiser setup completed");
}

void AudioController::setMasterVolume(float volume)
{
    appState->audio.targetVolume = volume;
    appState->audio.masterVolume = volume;
    
    if (!appState->audio.isSwitchingTimbre) {
        appState->audio.currentFadeVolume = 1.0f;
        applyVolumeToVoices(volume);
    }
    
    appState->notifyAudioStateChanged();
}

void AudioController::applyVolumeToVoices(float volume)
{
    float effectiveVolume = volume * appState->audio.currentFadeVolume;
    
    for (int i = 0; i < synth.getNumVoices(); ++i)
    {
        if (auto* sineVoice = dynamic_cast<SineVoice*>(synth.getVoice(i)))
        {
            sineVoice->setVolume(effectiveVolume);
        }
        else if (auto* pianoVoice = dynamic_cast<PianoVoice*>(synth.getVoice(i)))
        {
            pianoVoice->setVolume(effectiveVolume);
        }
    }
}

void AudioController::startTimbreFadeOut(bool targetIsPianoMode)
{
    appState->audio.isSwitchingTimbre = true;
    appState->audio.pendingTimbreSwitch = true;
    appState->audio.nextIsPianoMode = targetIsPianoMode;
    appState->audio.currentFadeVolume = 1.0f;
    
    DBG("Starting fade out, current volume: " + juce::String(appState->audio.currentFadeVolume));
}

void AudioController::performTimbreSwitch()
{
    DBG("Performing actual timbre switch");
    
    // 停止所有正在播放的音符
    stopAllNotes();
    
    // 切换模式
    appState->audio.isPianoMode = appState->audio.nextIsPianoMode;
    
    // 重新设置合成器
    setupSynthesiser();
    
    DBG("Timbre switched to: " + juce::String(appState->audio.isPianoMode ? "Piano" : "Sine"));
    
    // 开始淡入
    startTimbreFadeIn();
}

void AudioController::startTimbreFadeIn()
{
    appState->audio.pendingTimbreSwitch = false;
    appState->audio.currentFadeVolume = 0.0f;
    
    DBG("Starting fade in");
}

void AudioController::updateFadeTransition()
{
    if (!appState->audio.isSwitchingTimbre) return;
    
    if (appState->audio.pendingTimbreSwitch)
    {
        // 淡出阶段
        appState->audio.currentFadeVolume -= appState->audio.FADE_STEP;
        
        if (appState->audio.currentFadeVolume <= 0.0f)
        {
            appState->audio.currentFadeVolume = 0.0f;
            applyVolumeToVoices(appState->audio.targetVolume);
            
            // 淡出完成，执行音色切换
            performTimbreSwitch();
        }
        else
        {
            applyVolumeToVoices(appState->audio.targetVolume);
        }
    }
    else
    {
        // 淡入阶段
        appState->audio.currentFadeVolume += appState->audio.FADE_STEP;
        
        if (appState->audio.currentFadeVolume >= 1.0f)
        {
            appState->audio.currentFadeVolume = 1.0f;
            applyVolumeToVoices(appState->audio.targetVolume);
            
            // 淡入完成，结束切换过程
            appState->audio.isSwitchingTimbre = false;
            DBG("Smooth timbre switch completed");
            
            appState->notifyAudioStateChanged();
        }
        else
        {
            applyVolumeToVoices(appState->audio.targetVolume);
        }
    }
}

void AudioController::playNote(int midiNote, float velocity)
{
    // 检查MIDI输出是否启用
    if (!appState->system.midiOutputEnabled)
    {
        DBG("MIDI output disabled, ignoring note: " + juce::String(midiNote));
        return;
    }
    
    synth.noteOn(1, midiNote, velocity);
}

void AudioController::stopNote(int midiNote)
{
    synth.noteOff(1, midiNote, 0.0f, true); // 允许淡出
}

void AudioController::stopAllNotes()
{
    synth.allNotesOff(1, true); // 允许淡出
}

juce::File AudioController::getSFZFile() const
{
    // iOS真机优先：尝试从app bundle获取资源
    #if JUCE_IOS
    juce::File bundleDir = juce::File::getSpecialLocation(juce::File::currentApplicationFile);
    DBG("Bundle directory: " + bundleDir.getFullPathName());
    
    // 列出bundle根目录内容
    juce::Array<juce::File> bundleContents;
    bundleDir.findChildFiles(bundleContents, juce::File::findFilesAndDirectories, false);
    DBG("Bundle root contents (" + juce::String(bundleContents.size()) + " items):");
    for (auto& file : bundleContents) {
        DBG("  - " + file.getFileName() + (file.isDirectory() ? " (dir)" : " (file)"));
    }
    
    // 正确的文件夹结构：UprightPianoKW-small-SFZ-20190703/UprightPianoKW-small-20190703.sfz
    juce::File bundleSFZ = bundleDir
        .getChildFile("UprightPianoKW-small-SFZ-20190703")
        .getChildFile("UprightPianoKW-small-20190703.sfz");
    
    DBG("Checking bundle SFZ path: " + bundleSFZ.getFullPathName());
    if (bundleSFZ.exists()) {
        DBG("Found SFZ in app bundle: " + bundleSFZ.getFullPathName());
        return bundleSFZ;
    }
    
    DBG("SFZ not found in bundle structure, trying Resources directory...");
    
    // 尝试从Resources目录获取
    juce::File resourcesDir = bundleDir.getChildFile("Resources");
    DBG("Resources directory: " + resourcesDir.getFullPathName());
    DBG("Resources directory exists: " + juce::String(resourcesDir.exists() ? "true" : "false"));
    
    if (resourcesDir.exists()) {
        juce::Array<juce::File> resourcesContents;
        resourcesDir.findChildFiles(resourcesContents, juce::File::findFilesAndDirectories, false);
        DBG("Resources contents (" + juce::String(resourcesContents.size()) + " items):");
        for (auto& file : resourcesContents) {
            DBG("  - " + file.getFileName() + (file.isDirectory() ? " (dir)" : " (file)"));
        }
        
        juce::File resourcesSFZ = resourcesDir
            .getChildFile("UprightPianoKW-small-SFZ-20190703")
            .getChildFile("UprightPianoKW-small-20190703.sfz");
            
        if (resourcesSFZ.exists()) {
            DBG("Found SFZ in Resources: " + resourcesSFZ.getFullPathName());
            return resourcesSFZ;
        }
    }
    #endif
    
    // 开发环境回退：使用源码目录
    DBG("Using source directory fallback");
    juce::File sourceDir = juce::File(__FILE__).getParentDirectory();
    juce::File sourceSFZ = sourceDir
        .getChildFile("UprightPianoKW-small-SFZ-20190703")
        .getChildFile("UprightPianoKW-small-20190703.sfz");
    
    DBG("Source SFZ exists: " + juce::String(sourceSFZ.exists() ? "true" : "false"));
    DBG("Using source directory SFZ: " + sourceSFZ.getFullPathName());
    return sourceSFZ;
} 
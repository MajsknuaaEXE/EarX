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
    // 在音频线程中推进淡入淡出与切换逻辑，避免点击声
    updateFadeTransition();
    const juce::ScopedLock sl (synthMutex);
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
    // 先淡出，淡出完成后在音频线程执行真正的切换，再淡入
    startTimbreFadeOut(isPianoMode);
}

void AudioController::setupSynthesiser()
{
    DBG("=== setupSynthesiser() called ===");
    DBG("Starting synthesiser setup, mode: " + juce::String(appState->audio.isPianoMode ? "piano" : "sine"));
    const juce::ScopedLock sl (synthMutex);
    // 只清除现有的voices，保留sounds（一次性添加，避免切换时重新加载样本）
    synth.clearVoices();

    // 首次初始化时一次性添加两种Sound（DummySound + PianoSound），之后不再移除
    if (!soundsInitialized)
    {
        // 添加正弦用的占位Sound
        dummySound = new DummySound();
        synth.addSound(dummySound);

        // 添加钢琴Sound：异步加载避免阻塞UI
        pianoSound = new PianoSound();
        synth.addSound(pianoSound);
        
        juce::File sfzFile = getSFZFile();
        if (sfzFile.exists())
        {
            DBG("Starting async SFZ loading to avoid UI blocking");
            pianoSound->loadSFZAsync(sfzFile, [this](bool completed, int progress, int loadedSamples) {
                if (completed)
                {
                    DBG("[Preload] SFZ piano samples preloaded");
                }
                else
                {
                    DBG("[Preload] Loading progress: " + juce::String(progress) + "% (" + juce::String(loadedSamples) + " samples)");
                }
            });
        }
        else
        {
            DBG("Initial attach: SFZ file not found, piano sound will be silent");
        }

        soundsInitialized = true;
    }
    
    if (appState->audio.isPianoMode)
    {
        // 钢琴模式：仅添加钢琴 Voices（PianoSound 已常驻）
        DBG("Setting up piano mode with SFZ samples");
        if (dummySound) dummySound->setEnabled(false);
        if (pianoSound) pianoSound->setEnabled(true);
        for (int i = 0; i < 8; ++i)
            synth.addVoice(new PianoVoice());
        DBG("Piano mode setup complete");
    }
    else
    {
        // 正弦波模式：仅添加正弦 Voices（DummySound 已常驻）
        DBG("Setting up sine mode");
        if (dummySound) dummySound->setEnabled(true);
        if (pianoSound) pianoSound->setEnabled(false);
        for (int i = 0; i < 8; ++i)
            synth.addVoice(new SineVoice());
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
    const juce::ScopedLock sl (synthMutex);
    // 为了匹配两种音色的主观响度，适当降低正弦波音色的电平
    constexpr float kSineLoudnessScale = 0.55f; // 调整此系数以微调两种音色的相对音量
    for (int i = 0; i < synth.getNumVoices(); ++i)
    {
        if (auto* sineVoice = dynamic_cast<SineVoice*>(synth.getVoice(i)))
        {
            sineVoice->setVolume(effectiveVolume * kSineLoudnessScale);
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
    DBG("Performing timbre switch fade transition");
    
    // 停止所有正在播放的音符
    stopAllNotes();
    // 在音频线程中完成真正的音色切换，避免点击
    appState->audio.isPianoMode = appState->audio.nextIsPianoMode;
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
    const juce::ScopedLock sl (synthMutex);
    synth.noteOn(1, midiNote, velocity);
}

void AudioController::stopNote(int midiNote)
{
    const juce::ScopedLock sl (synthMutex);
    synth.noteOff(1, midiNote, 0.0f, true); // 允许淡出
}

void AudioController::stopAllNotes()
{
    const juce::ScopedLock sl (synthMutex);
    synth.allNotesOff(1, true); // 允许淡出
}

juce::File AudioController::getSFZFile() const
{
    DBG("=== getSFZFile() called ===");
    
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
    
    // 常规：保留目录层级的蓝色文件夹
    {
        juce::File bundleSFZ = bundleDir
            .getChildFile("AccurateSalamanderGrandPianoV6.0_48khz16bit")
            .getChildFile("sfz")
            .getChildFile("Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz");
        DBG("Checking bundle SFZ path: " + bundleSFZ.getFullPathName());
        if (bundleSFZ.exists()) {
            DBG("Found SFZ in app bundle: " + bundleSFZ.getFullPathName());
            return bundleSFZ;
        }
    }

    // 特殊：若以“创建组（黄色文件夹）”方式添加，可能被扁平化到根目录
    {
        juce::File flatSFZ = bundleDir.getChildFile("Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz");
        if (flatSFZ.exists()) {
            DBG("Found flat SFZ in bundle root: " + flatSFZ.getFullPathName());
            return flatSFZ;
        }
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
            .getChildFile("AccurateSalamanderGrandPianoV6.0_48khz16bit")
            .getChildFile("sfz")
            .getChildFile("Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz");
            
        if (resourcesSFZ.exists()) {
            DBG("Found SFZ in Resources: " + resourcesSFZ.getFullPathName());
            return resourcesSFZ;
        }
    }
    // 再尝试：Flutter 资产目录 (Runner.app/Frameworks/App.framework/flutter_assets/...)
    {
        auto flutterAssets = bundleDir
            .getChildFile("Frameworks")
            .getChildFile("App.framework")
            .getChildFile("flutter_assets");
        DBG("Flutter assets dir: " + flutterAssets.getFullPathName() + ", exists=" + juce::String(flutterAssets.exists() ? "true" : "false"));

        // 允许两种布局：直接放在 flutter_assets/Accurate... 或 flutter_assets/assets/Accurate...
        juce::File fa1 = flutterAssets
            .getChildFile("AccurateSalamanderGrandPianoV6.0_48khz16bit")
            .getChildFile("sfz")
            .getChildFile("Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz");
        juce::File fa2 = flutterAssets
            .getChildFile("assets")
            .getChildFile("AccurateSalamanderGrandPianoV6.0_48khz16bit")
            .getChildFile("sfz")
            .getChildFile("Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz");
        if (fa1.exists()) { DBG("Found SFZ in flutter_assets: " + fa1.getFullPathName()); return fa1; }
        if (fa2.exists()) { DBG("Found SFZ in flutter_assets/assets: " + fa2.getFullPathName()); return fa2; }
    }

    // 最后尝试：应用可写目录（可通过 Files / iTunes 拷入）
    {
        auto docs = juce::File::getSpecialLocation(juce::File::userDocumentsDirectory);
        juce::File docsSFZ = docs
            .getChildFile("AccurateSalamanderGrandPianoV6.0_48khz16bit")
            .getChildFile("sfz")
            .getChildFile("Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz");
        DBG("Documents dir: " + docs.getFullPathName() + ", candidate: " + docsSFZ.getFullPathName());
        if (docsSFZ.exists()) { DBG("Found SFZ in Documents"); return docsSFZ; }

        auto appData = juce::File::getSpecialLocation(juce::File::userApplicationDataDirectory);
        juce::File dataSFZ = appData
            .getChildFile("AccurateSalamanderGrandPianoV6.0_48khz16bit")
            .getChildFile("sfz")
            .getChildFile("Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz");
        DBG("ApplicationSupport dir: " + appData.getFullPathName() + ", candidate: " + dataSFZ.getFullPathName());
        if (dataSFZ.exists()) { DBG("Found SFZ in ApplicationSupport"); return dataSFZ; }
    }
    #endif
    
    // 开发环境回退：使用源码目录
    DBG("Using source directory fallback");
    juce::File sourceDir = juce::File(__FILE__).getParentDirectory();
    juce::File sourceSFZ = sourceDir
        .getChildFile("AccurateSalamanderGrandPianoV6.0_48khz16bit")
        .getChildFile("sfz")
        .getChildFile("Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz");
    
    DBG("Source SFZ exists: " + juce::String(sourceSFZ.exists() ? "true" : "false"));
    DBG("Using source directory SFZ: " + sourceSFZ.getFullPathName());
    return sourceSFZ;
} 
void AudioController::preloadPianoSamples()
{
    // 现在由 setupSynthesiser() 中的异步加载处理，这个方法已不需要
    DBG("[Preload] Piano samples will be loaded asynchronously by setupSynthesiser()");
}

bool AudioController::arePianoSamplesLoaded() const
{
    const juce::ScopedLock sl(synthMutex);
    
    if (!soundsInitialized || !pianoSound) {
        return false;
    }
    
    return pianoSound->isLoaded();
}

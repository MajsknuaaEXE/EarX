#include "PlaybackEngine.h"
#include "AppState.h"
#include "AudioController.h"

// 音符名称常量定义 - 现在通过 AppState 动态获取
const char* PlaybackEngine::NOTE_NAMES[12] = {
    "C", "C#/Db", "D", "D#/Eb", "E", "F", "F#/Gb",
    "G", "G#/Ab", "A", "A#/Bb", "B"
};

PlaybackEngine::PlaybackEngine(AppState* state, AudioController* audio)
    : appState(state), audioController(audio)
{
    appState->addListener(this);
    DBG("PlaybackEngine initialized");
}

PlaybackEngine::~PlaybackEngine()
{
    if (appState)
        appState->removeListener(this);
}

void PlaybackEngine::playNextNote()
{
    auto onIndices = getActiveNoteIndices();
    playNextNote(onIndices); // 调用重载版本
}

void PlaybackEngine::playNextNote(const juce::Array<int>& onIndices)
{
    if (onIndices.isEmpty())
        return;
    
    int semitone = selectNextNote(onIndices);
    if (semitone == -1)
        return;
    
    // 智能八度选择：避免重复相同的音符
    int baseOctave;
    
    if (onIndices.size() == 1)
    {
        // 只有一个音符激活时，通过不同八度来制造变化
        int availableOctaves[] = {4, 5, 6};
        int numOctaves = 3;
        
        // 如果上一个音符存在且是相同半音，选择不同的八度
        if (appState->playback.lastSemitone == semitone && 
            appState->playback.lastMidiNote != -1)
        {
            int lastOctave = appState->playback.lastMidiNote / 12;
            
            // 从可用八度中排除上一个八度
            juce::Array<int> differentOctaves;
            for (int i = 0; i < numOctaves; ++i)
            {
                if (availableOctaves[i] != lastOctave)
                    differentOctaves.add(availableOctaves[i]);
            }
            
            if (!differentOctaves.isEmpty())
            {
                baseOctave = differentOctaves[juce::Random::getSystemRandom().nextInt(differentOctaves.size())];
            }
            else
            {
                baseOctave = availableOctaves[juce::Random::getSystemRandom().nextInt(numOctaves)];
            }
        }
        else
        {
            // 第一次播放或不同半音，随机选择八度
            baseOctave = availableOctaves[juce::Random::getSystemRandom().nextInt(numOctaves)];
        }
    }
    else
    {
        // 有多个音符激活时，随机选择八度（因为音符本身已经不同了）
        int availableOctaves[] = {4, 5, 6};
        baseOctave = availableOctaves[juce::Random::getSystemRandom().nextInt(3)];
    }
    
    int note = baseOctave * 12 + semitone;
    
    // 记录这个音符
    appState->playback.lastMidiNote = note;
    appState->playback.lastSemitone = semitone;
    
    // 设置播放状态
    setCurrentPlayingNote(semitone);
    
    // 播放音符
    audioController->playNote(note, 0.8f);
    
    // 计算音符持续时间
    double durationMs = (60000.0 / appState->playback.bpm) *
                        (appState->playback.noteDuration / 100.0);
    double endTime = juce::Time::getMillisecondCounterHiRes() + durationMs;
    
    // 添加到活跃音符列表
    AppState::PlaybackState::ActiveNote activeNote;
    activeNote.note = note;
    activeNote.semitone = semitone;
    activeNote.endTime = endTime;
    appState->playback.activeNotes.add(activeNote);
    
    appState->notifyPlaybackStateChanged();
    
    // 使用选择的音名进行调试输出
    juce::String selectedNoteNames = appState->getSelectedNoteNamesDisplayForSemitone(semitone);
    if (selectedNoteNames.isEmpty())
        selectedNoteNames = juce::String(NOTE_NAMES[semitone]);
    
    DBG("Playing note: " + selectedNoteNames + " (MIDI: " + juce::String(note) + ")");
}

void PlaybackEngine::stopNote(int midiNote)
{
    audioController->stopNote(midiNote);
}

void PlaybackEngine::stopAllNotes()
{
    audioController->stopAllNotes();
    appState->playback.activeNotes.clear();
    appState->interaction.currentPlayingButtonIndex = -1;
    appState->notifyPlaybackStateChanged();
}

void PlaybackEngine::updateActiveNotes(double currentTime)
{
    // 检查并移除已结束的音符
    for (int i = appState->playback.activeNotes.size() - 1; i >= 0; --i)
    {
        const auto& activeNote = appState->playback.activeNotes.getReference(i);
        if (currentTime >= activeNote.endTime)
        {
            // 音符结束，停止播放
            stopNote(activeNote.note);
            clearCurrentPlayingNote(activeNote.semitone);
            appState->playback.activeNotes.remove(i);
        }
    }
}

void PlaybackEngine::updateNoteDisplay(juce::Label& noteLabel)
{
    if (appState->interaction.currentPlayingButtonIndex >= 0 && 
        appState->interaction.currentPlayingButtonIndex < 12)
    {
        // 使用 AppState 中的音名选择获取显示文本
        juce::String displayText = appState->getSelectedNoteNamesDisplayForSemitone(
            appState->interaction.currentPlayingButtonIndex);
        
        // 如果没有选择的音名，回退到默认音名
        if (displayText.isEmpty())
        {
            displayText = juce::String(NOTE_NAMES[appState->interaction.currentPlayingButtonIndex]);
        }
        
        // 如果是中心音，添加特殊标识
        if (appState->interaction.longPressedButtonIndex == appState->interaction.currentPlayingButtonIndex)
        {
            displayText += " *";
        }
        
        noteLabel.setText(displayText, juce::dontSendNotification);
    }
    else
    {
        noteLabel.setText("", juce::dontSendNotification);
    }
}

void PlaybackEngine::setBPM(double bpm)
{
    appState->playback.bpm = bpm;
    appState->notifyPlaybackStateChanged();
}

void PlaybackEngine::setNoteDuration(float duration)
{
    appState->playback.noteDuration = duration;
    appState->notifyPlaybackStateChanged();
}

void PlaybackEngine::playbackStateChanged()
{
    DBG("Playback state changed - BPM: " + juce::String(appState->playback.bpm) + 
        ", Duration: " + juce::String(appState->playback.noteDuration) + "%");
}

juce::Array<int> PlaybackEngine::getActiveNoteIndices()
{
    juce::Array<int> onIndices;
    
    // 只使用Custom模式：使用AppState中的customSemitones状态
    for (int i = 0; i < 12; ++i)
    {
        if (i < appState->interaction.customSemitones.size() && 
            appState->interaction.customSemitones[i])
            onIndices.add(i);
    }
    
    return onIndices;
}

int PlaybackEngine::selectNextNote(const juce::Array<int>& onIndices)
{
    if (onIndices.isEmpty())
        return -1;
    
    int semitone;
    
    // 检查是否有中心音（长按的按钮），以及是否应该播放中心音
    if (appState->interaction.longPressedButtonIndex != -1 && 
        appState->interaction.shouldPlayCenterNote)
    {
        // 播放中心音
        semitone = appState->interaction.longPressedButtonIndex;
        appState->interaction.shouldPlayCenterNote = false;  // 下次播放随机音
    }
    else
    {
        // 播放随机音，避免重复
        do
        {
            semitone = onIndices[juce::Random::getSystemRandom().nextInt(onIndices.size())];
        }
        while (semitone == appState->playback.lastSemitone && onIndices.size() > 1);
        
        // 如果有中心音，下次播放中心音
        if (appState->interaction.longPressedButtonIndex != -1)
        {
            appState->interaction.shouldPlayCenterNote = true;
        }
    }
    
    return semitone;
}

void PlaybackEngine::setCurrentPlayingNote(int semitone)
{
    appState->interaction.currentPlayingButtonIndex = semitone;
    appState->notifyInteractionStateChanged();
}

void PlaybackEngine::clearCurrentPlayingNote(int semitone)
{
    if (appState->interaction.currentPlayingButtonIndex == semitone)
    {
        appState->interaction.currentPlayingButtonIndex = -1;
        appState->notifyInteractionStateChanged();
    }
} 
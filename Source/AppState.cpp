#include "AppState.h"

AppState::AppState()
{
    DBG("AppState initialized");
}

AppState::~AppState()
{
    listeners.clear();
}

void AppState::addListener(Listener* listener)
{
    listeners.add(listener);
}

void AppState::removeListener(Listener* listener)
{
    listeners.remove(listener);
}

void AppState::notifyAudioStateChanged()
{
    listeners.call([](Listener& l) { l.audioStateChanged(); });
}

void AppState::notifyInteractionStateChanged()
{
    listeners.call([](Listener& l) { l.interactionStateChanged(); });
}

void AppState::notifyPlaybackStateChanged()
{
    listeners.call([](Listener& l) { l.playbackStateChanged(); });
}

void AppState::notifySystemStateChanged()
{
    listeners.call([](Listener& l) { l.systemStateChanged(); });
}

// 删除getScalePattern函数

// 删除getScaleNoteNames函数

// 删除getNoteNameSemitone函数

// 删除setScaleNoteNameSelection函数

// 删除getScaleNames函数

// 统一的音名选项定义，供两个函数共用
static const char* SEMITONE_NOTE_OPTIONS[12][3] = {
    {"C", "B♯", nullptr},      // 0: C
    {"C♯", "D♭", nullptr},     // 1: #C  
    {"D", "D♮", nullptr},      // 2: D
    {"E♭", "D♯", nullptr},     // 3: bE
    {"E", "E♮", nullptr},      // 4: E
    {"F", "E♯", nullptr},      // 5: F
    {"F♯", "G♭", nullptr},     // 6: #F
    {"G", "G♮", nullptr},      // 7: G
    {"A♭", "G♯", nullptr},     // 8: bA
    {"A", "A♮", nullptr},      // 9: A  
    {"B♭", "A♯", nullptr},     // 10: bB
    {"B", "B♮", nullptr}      // 11: B
};

void AppState::InteractionState::initializeSemitoneNoteNames()
{
    
    semitoneNoteNames.clear();
    semitoneNoteNames.resize(12);
    
    for (int semitone = 0; semitone < 12; ++semitone)
    {
        juce::Array<bool> noteNameSelections;
        
        // 计算这个音级有多少个音名选项
        int numOptions = 0;
        for (int i = 0; i < 3 && SEMITONE_NOTE_OPTIONS[semitone][i] != nullptr; ++i)
        {
            numOptions++;
        }
        
        noteNameSelections.resize(numOptions);
        
        // 默认选择第一个选项，这样会显示 C，C♯，D，E♭，E，F，F♯，G，A♭，A，B♭，B
        for (int i = 0; i < numOptions; ++i)
        {
            noteNameSelections.set(i, (i == 0));
        }
        
        semitoneNoteNames.set(semitone, noteNameSelections);
    }
}

juce::StringArray AppState::InteractionState::getNoteNamesForSemitone(int semitone) const
{
    juce::StringArray noteNames;
    
    if (semitone >= 0 && semitone < 12)
    {
        for (int i = 0; i < 3 && SEMITONE_NOTE_OPTIONS[semitone][i] != nullptr; ++i)
        {
            // 使用UTF-8指针构造，确保非ASCII字符（如♯、♭、𝄪）不会触发ASCII断言
            noteNames.add(juce::String(juce::CharPointer_UTF8(SEMITONE_NOTE_OPTIONS[semitone][i])));
        }
    }
    
    return noteNames;
}

juce::Array<int> AppState::InteractionState::getSelectedNoteNamesForSemitone(int semitone) const
{
    juce::Array<int> selectedIndices;
    
    if (semitone >= 0 && semitone < semitoneNoteNames.size())
    {
        const auto& selections = semitoneNoteNames.getReference(semitone);
        for (int i = 0; i < selections.size(); ++i)
        {
            if (selections[i])
                selectedIndices.add(i);
        }
    }
    
    return selectedIndices;
}

void AppState::setSemitoneNoteName(int semitone, int noteNameIndex, bool selected)
{
    if (semitone >= 0 && semitone < interaction.semitoneNoteNames.size())
    {
        auto& selections = interaction.semitoneNoteNames.getReference(semitone);
        if (noteNameIndex >= 0 && noteNameIndex < selections.size())
        {
            selections.set(noteNameIndex, selected);
            
            // 确保每个音级至少有一个音名被选中
            bool hasSelection = false;
            for (int i = 0; i < selections.size(); ++i)
            {
                if (selections[i])
                {
                    hasSelection = true;
                    break;
                }
            }
            
            // 如果没有任何选择，强制选择第一个选项
            if (!hasSelection && !selections.isEmpty())
            {
                selections.set(0, true);
            }
            
            notifyInteractionStateChanged();
        }
    }
}

bool AppState::isSemitoneNoteNameSelected(int semitone, int noteNameIndex) const
{
    if (semitone >= 0 && semitone < interaction.semitoneNoteNames.size())
    {
        const auto& selections = interaction.semitoneNoteNames.getReference(semitone);
        if (noteNameIndex >= 0 && noteNameIndex < selections.size())
        {
            return selections[noteNameIndex];
        }
    }
    return false;
}

juce::String AppState::getSelectedNoteNamesDisplayForSemitone(int semitone) const
{
    if (semitone < 0 || semitone >= interaction.semitoneNoteNames.size())
        return "";
    
    juce::StringArray noteNames = interaction.getNoteNamesForSemitone(semitone);
    juce::Array<int> selectedIndices = interaction.getSelectedNoteNamesForSemitone(semitone);
    
    juce::StringArray selectedNames;
    for (int index : selectedIndices)
    {
        if (index >= 0 && index < noteNames.size())
        {
            selectedNames.add(noteNames[index]);
        }
    }
    
    return selectedNames.joinIntoString("/");
} 

#include "InteractionController.h"

InteractionController::InteractionController(AppState* state)
    : appState(state)
{
    appState->addListener(this);
    DBG("InteractionController initialized");
}

InteractionController::~InteractionController()
{
    if (appState)
        appState->removeListener(this);
}

// 长按检测逻辑已移至Flutter端处理
// 这些方法现在为空实现，保持接口兼容性

void InteractionController::updateButtonVisualState(juce::OwnedArray<juce::ToggleButton>& toggles)
{
    // 更新所有按钮的视觉状态
    for (int i = 0; i < toggles.size() && i < 12; ++i)
    {
        auto* button = toggles[i];
        if (!button) continue;
        
        // 更新长按状态
        bool isLongPressed = (appState->interaction.longPressedButtonIndex == i);
        button->getProperties().set("longPressed", isLongPressed);
        
        // 如果是长按状态，强制开启按钮开关（但要考虑当前模式）
        if (isLongPressed) // 只保留自定义模式
        {
            button->setToggleState(true, juce::dontSendNotification);
        }
        
        // 更新播放状态 - 这个在所有模式下都需要正确显示
        bool isPlaying = (appState->interaction.currentPlayingButtonIndex == i);
        button->getProperties().set("isPlaying", isPlaying);
        
        // 强制重绘按钮，确保播放状态能在禁用状态下也正确显示
        button->repaint();
    }
}

void InteractionController::interactionStateChanged()
{
    // 当交互状态改变时的响应
    DBG("Interaction state changed - Long pressed button: " + 
        juce::String(appState->interaction.longPressedButtonIndex));
}

int InteractionController::findButtonIndex(juce::Component* button, 
                                         const juce::OwnedArray<juce::ToggleButton>& toggles)
{
    for (int i = 0; i < toggles.size(); ++i)
    {
        if (toggles[i] == button)
            return i;
    }
    return -1;
} 
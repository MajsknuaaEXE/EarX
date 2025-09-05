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

void InteractionController::handleButtonMouseDown(juce::Component* button, double timestamp)
{
    // 这个方法需要在MainComponent中调用时传入toggles数组来找到按钮索引
    // 目前先记录时间戳，具体的按钮识别在MainComponent中处理
}

void InteractionController::handleButtonMouseUp(juce::Component* button)
{
    // 按钮释放时重置对应的按下时间
}

void InteractionController::updateLongPressDetection(double currentTime)
{
    // 检查所有按钮的长按状态
    for (int i = 0; i < appState->interaction.buttonPressStartTimes.size(); ++i)
    {
        double pressStartTime = appState->interaction.buttonPressStartTimes[i];
        if (pressStartTime > 0)  // 按钮正在被按下
        {
            double pressDuration = currentTime - pressStartTime;
            if (pressDuration >= appState->interaction.LONG_PRESS_DURATION)
            {
                // 长按时间达到，触发长按效果
                if (appState->interaction.longPressedButtonIndex == i)
                {
                    // 如果当前按钮已经是长按状态，取消它
                    cancelLongPress(i);
                }
                else
                {
                    // 否则设置为长按状态
                    handleLongPress(i);
                }
                
                // 重置按下时间，防止重复触发
                appState->interaction.buttonPressStartTimes.set(i, 0.0);
            }
        }
    }
}

void InteractionController::handleLongPress(int buttonIndex)
{
    if (buttonIndex >= 0 && buttonIndex < 12)
    {
        // 如果已经有其他按钮在发光，取消它
        if (appState->interaction.longPressedButtonIndex != -1 && 
            appState->interaction.longPressedButtonIndex != buttonIndex)
        {
            // 状态会在updateButtonVisualState中处理
        }
        
        // 设置新的长按按钮
        appState->interaction.longPressedButtonIndex = buttonIndex;
        appState->interaction.shouldPlayCenterNote = false; // 重置中心音播放状态
        
        appState->notifyInteractionStateChanged();
        
        DBG("Long press detected on button: " + juce::String(buttonIndex));
    }
}

void InteractionController::cancelLongPress(int buttonIndex)
{
    if (buttonIndex >= 0 && buttonIndex < 12 && 
        appState->interaction.longPressedButtonIndex == buttonIndex)
    {
        // 取消当前长按按钮的发光状态
        appState->interaction.longPressedButtonIndex = -1;
        appState->interaction.shouldPlayCenterNote = false;
        
        appState->notifyInteractionStateChanged();
        
        DBG("Long press cancelled on button: " + juce::String(buttonIndex));
    }
}

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
        if (isLongPressed && appState->interaction.currentMode == AppState::InteractionState::Mode::Custom)
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
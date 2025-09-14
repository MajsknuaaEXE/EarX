#pragma once
#include <juce_core/juce_core.h>
#include <juce_gui_basics/juce_gui_basics.h>
#include "AppState.h"  // 完整包含而不是前向声明

/**
 * 交互控制器 - 负责处理用户交互逻辑
 * 职责：
 * - 长按手势识别和处理
 * - 按钮点击事件处理
 * - 鼠标事件管理
 * - UI状态更新
 */
class InteractionController : public AppState::Listener
{
public:
    InteractionController(AppState* appState);
    virtual ~InteractionController() override;
    
    // 鼠标事件处理 (长按检测逻辑已移至Flutter)
    void handleButtonMouseDown(juce::Component* button, double timestamp) {} // 空实现
    void handleButtonMouseUp(juce::Component* button) {} // 空实现
    
    // 长按处理 (已弃用，现在通过FFI直接设置中心音)
    void updateLongPressDetection(double currentTime) {} // 空实现
    void handleLongPress(int buttonIndex) {} // 已弃用
    void cancelLongPress(int buttonIndex) {} // 已弃用
    
    // 按钮状态管理
    void updateButtonVisualState(juce::OwnedArray<juce::ToggleButton>& toggles);
    
    // AppState::Listener 实现
    virtual void interactionStateChanged() override;
    
private:
    AppState* appState;
    
    // 辅助方法
    int findButtonIndex(juce::Component* button, const juce::OwnedArray<juce::ToggleButton>& toggles);
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(InteractionController)
}; 
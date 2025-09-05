#pragma once
#include <JuceHeader.h>
#include "EarxLookAndFeel.h"
#include "LightIndicator.h"
#include "AppState.h"
#include "AudioController.h"
#include "InteractionController.h"
#include "PlaybackEngine.h"

/**
 * 主界面组件 - 重构后只负责UI布局和事件分发
 * 职责：
 * - UI组件管理和布局
 * - 事件分发到相应控制器
 * - 状态变化的UI响应
 */
class MainComponent : public juce::AudioAppComponent, 
                     private juce::Timer, 
                     public AppState::Listener
{
public:
    MainComponent();
    ~MainComponent() override;
    
    // AudioAppComponent 接口
    void paint(juce::Graphics& g) override;
    void prepareToPlay(int samplesPerBlockExpected, double sampleRate) override;
    void getNextAudioBlock(const juce::AudioSourceChannelInfo& bufferToFill) override;
    void releaseResources() override;
    void resized() override;
    
    // Timer 回调
    void timerCallback() override;
    
    // AppState::Listener 实现
    void audioStateChanged() override;
    void interactionStateChanged() override;
    void playbackStateChanged() override;
    void systemStateChanged() override;
    
private:
    // 内部鼠标监听器类
    class ButtonMouseListener : public juce::MouseListener
    {
    public:
        ButtonMouseListener(MainComponent* parent) : parentComponent(parent) {}
        void mouseDown(const juce::MouseEvent& event) override;
        void mouseUp(const juce::MouseEvent& event) override;
    private:
        MainComponent* parentComponent;
    };
    
    // 核心组件
    std::unique_ptr<AppState> appState;
    std::unique_ptr<AudioController> audioController;
    std::unique_ptr<InteractionController> interactionController;
    std::unique_ptr<PlaybackEngine> playbackEngine;
    
    // UI组件
    std::unique_ptr<EarxLookAndFeel> earxLookAndFeel;
    juce::OwnedArray<juce::ToggleButton> toggles;
    juce::OwnedArray<LightIndicator> lights;
    juce::Slider bpmSlider, volumeSlider, noteDurationSlider;
    juce::ToggleButton shutdownToggle;
    juce::ComboBox shutdownDurationCombo;
    juce::ToggleButton timbreToggle;
    juce::ComboBox modeCombo;
    juce::ComboBox scaleCombo;
    juce::Label currentNoteLabel;
    std::unique_ptr<ButtonMouseListener> buttonMouseListener;
    
    // UI事件处理方法
    void setupUIComponents();
    void setupSliders();
    void setupButtons();
    void setupButtonCallbacks();
    
    // 辅助方法
    void updateUIFromState();
    juce::Array<int> getActiveToggleIndices();
    int findButtonIndex(juce::Component* button);
    void updateButtonsForScaleMode();
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(MainComponent)
}; 
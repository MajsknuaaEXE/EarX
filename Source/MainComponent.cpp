#include "MainComponent.h"

MainComponent::MainComponent()
{
    // 初始化核心组件
    appState = std::make_unique<AppState>();
    audioController = std::make_unique<AudioController>(appState.get());
    interactionController = std::make_unique<InteractionController>(appState.get());
    playbackEngine = std::make_unique<PlaybackEngine>(appState.get(), audioController.get());
    
    // 监听状态变化
    appState->addListener(this);
    
    // 设置UI
    setupUIComponents();
    
    // 初始化音频
    setAudioChannels(0, 2);
    
    // 启动定时器
    startTimer(10);
    setSize(400, 1000);
    
    DBG("MainComponent initialized with new architecture");
}

MainComponent::~MainComponent()
{
    shutdownAudio();
    setLookAndFeel(nullptr);
    
    if (appState)
        appState->removeListener(this);
}

void MainComponent::setupUIComponents()
{
    // 设置外观
    earxLookAndFeel = std::make_unique<EarxLookAndFeel>();
    setLookAndFeel(earxLookAndFeel.get());
    
    // 设置音符按钮
    setupButtons();
    
    // 设置滑块
    setupSliders();
    
    // 设置当前音名显示标签
    addAndMakeVisible(currentNoteLabel);
    currentNoteLabel.setText("", juce::dontSendNotification);
    currentNoteLabel.setFont(juce::Font("Arial", 32.0f, juce::Font::bold));
    currentNoteLabel.setColour(juce::Label::textColourId, juce::Colours::white);
    currentNoteLabel.setJustificationType(juce::Justification::centred);
}

void MainComponent::setupButtons()
{
    static const char* noteNames[] = { "C", "C#/Db", "D", "D#/Eb", "E/Fb", "#E/F", "F#/Gb",
                                       "G", "G#/Ab", "A", "A#/Bb", "B/Cb" };
    
    // 创建鼠标监听器
    buttonMouseListener = std::make_unique<ButtonMouseListener>(this);
    
    // 创建音符按钮
    for (int i = 0; i < 12; ++i)
    {
        auto* tb = new juce::ToggleButton(noteNames[i]);
        toggles.add(tb);
        addAndMakeVisible(tb);
        
        // 初始化按钮属性
        tb->getProperties().set("longPressed", false);
        tb->getProperties().set("isPlaying", false);
        
        // 添加长按检测
        tb->addMouseListener(buttonMouseListener.get(), false);
        
        // 添加点击监听器
        tb->onClick = [this, i]()
        {
            // 如果这是中心音（长按按钮），强制保持开启状态
            if (appState->interaction.longPressedButtonIndex == i)
            {
                toggles[i]->setToggleState(true, juce::dontSendNotification);
            }
        };
        
        // 创建指示灯（虽然现在不使用，但保持兼容性）
        auto* li = new LightIndicator();
        lights.add(li);
        addAndMakeVisible(li);
        li->setVisible(false); // 隐藏指示灯，使用按钮本身显示状态
    }
    
    // 设置系统按钮
    addAndMakeVisible(shutdownToggle);
    shutdownToggle.setButtonText("Auto Shutdown");
    
    // 设置关闭时长下拉菜单
    addAndMakeVisible(shutdownDurationCombo);
    shutdownDurationCombo.addItem("15 min", 1);
    shutdownDurationCombo.addItem("25 min", 2);
    shutdownDurationCombo.addItem("35 min", 3);
    shutdownDurationCombo.addItem("60 min", 4);
    shutdownDurationCombo.setSelectedId(2, juce::dontSendNotification); // 默认选择25分钟
    appState->system.shutdownDurationMinutes = 25;
    
    shutdownDurationCombo.onChange = [this]
    {
        int selectedId = shutdownDurationCombo.getSelectedId();
        switch (selectedId)
        {
            case 1: appState->system.shutdownDurationMinutes = 15; break;
            case 2: appState->system.shutdownDurationMinutes = 25; break;
            case 3: appState->system.shutdownDurationMinutes = 35; break;
            case 4: appState->system.shutdownDurationMinutes = 60; break;
            default: appState->system.shutdownDurationMinutes = 25; break;
        }
        
        // 如果自动关闭正在运行，重新启动计时器
        if (appState->system.autoShutdownEnabled && appState->system.shutdownEndTime > 0)
        {
            double durationMs = appState->system.shutdownDurationMinutes * 60.0 * 1000.0;
            appState->system.shutdownEndTime = juce::Time::getMillisecondCounterHiRes() + durationMs;
            DBG("Auto shutdown timer updated to " << appState->system.shutdownDurationMinutes << " minutes");
        }
        
        appState->notifySystemStateChanged();
    };
    
    addAndMakeVisible(timbreToggle);
    timbreToggle.setButtonText("Piano Mode");
    
    // 设置模式选择下拉菜单
    addAndMakeVisible(modeCombo);
    modeCombo.addItem("Custom", 1);
    modeCombo.addItem("Scale", 2);
    modeCombo.setSelectedId(1, juce::dontSendNotification); // 默认 Custom 模式
    
    modeCombo.onChange = [this]
    {
        int selectedId = modeCombo.getSelectedId();
        appState->interaction.currentMode = (selectedId == 2) ? 
            AppState::InteractionState::Mode::Scale : 
            AppState::InteractionState::Mode::Custom;
        
        // 更新音阶选择框可见性
        scaleCombo.setVisible(appState->interaction.currentMode == AppState::InteractionState::Mode::Scale);
        
        // 在 Scale 模式下，根据选择的音阶设置按钮状态
        if (appState->interaction.currentMode == AppState::InteractionState::Mode::Scale)
        {
            updateButtonsForScaleMode();
        }
        
        appState->notifyInteractionStateChanged();
    };
    
    // 设置音阶选择下拉菜单
    addAndMakeVisible(scaleCombo);
    const auto& scaleNames = AppState::getScaleNames();
    for (int i = 0; i < scaleNames.size(); ++i)
    {
        scaleCombo.addItem(scaleNames[i], i + 1);
    }
    scaleCombo.setSelectedId(1, juce::dontSendNotification); // 默认 C Major
    scaleCombo.setVisible(false); // 默认隐藏，只在 Scale 模式下显示
    
    scaleCombo.onChange = [this]
    {
        appState->interaction.selectedScaleIndex = scaleCombo.getSelectedId() - 1;
        if (appState->interaction.currentMode == AppState::InteractionState::Mode::Scale)
        {
            updateButtonsForScaleMode();
        }
        appState->notifyInteractionStateChanged();
    };
    
    setupButtonCallbacks();
}

void MainComponent::setupSliders()
{
    // BPM滑块
    addAndMakeVisible(bpmSlider);
    bpmSlider.setRange(0.0, 300.0, 0.1);
    bpmSlider.setValue(appState->playback.bpm);
    bpmSlider.onValueChange = [this] {
        playbackEngine->setBPM(bpmSlider.getValue());
    };
    
    // 音量滑块
    addAndMakeVisible(volumeSlider);
    volumeSlider.setRange(0.0, 1.0, 0.01);
    volumeSlider.setValue(appState->audio.masterVolume);
    volumeSlider.onValueChange = [this] {
        audioController->setMasterVolume((float)volumeSlider.getValue());
    };
    
    // 音符持续时间滑块
    addAndMakeVisible(noteDurationSlider);
    noteDurationSlider.setRange(10, 100, 1);
    noteDurationSlider.setValue(appState->playback.noteDuration);
    noteDurationSlider.setTextValueSuffix(" %");
    noteDurationSlider.onValueChange = [this] {
        playbackEngine->setNoteDuration((float)noteDurationSlider.getValue());
    };
}

void MainComponent::setupButtonCallbacks()
{
    // Shutdown按钮回调 - 改为开关功能
    shutdownToggle.onClick = [this]
    {
        appState->system.autoShutdownEnabled = shutdownToggle.getToggleState();
        
        if (appState->system.autoShutdownEnabled)
        {
            // 开启自动关闭，开始倒计时
            double durationMs = appState->system.shutdownDurationMinutes * 60.0 * 1000.0;
            appState->system.shutdownEndTime = juce::Time::getMillisecondCounterHiRes() + durationMs;
            appState->playback.stopTrigger = false;
            DBG("Auto shutdown enabled for " << appState->system.shutdownDurationMinutes << " minutes");
        }
        else
        {
            // 关闭自动关闭，恢复MIDI输出
            appState->system.midiOutputEnabled = true;
            appState->system.shutdownEndTime = 0;
            DBG("Auto shutdown disabled - MIDI output enabled");
        }
        appState->notifySystemStateChanged();
    };
    
    // 音色切换按钮回调
    timbreToggle.onClick = [this]
    {
        bool targetMode = timbreToggle.getToggleState();
        audioController->switchTimbre(targetMode);
    };
    
    // 为所有音符按钮添加点击回调
    for (int i = 0; i < toggles.size(); ++i)
    {
        toggles[i]->onClick = [this, i]()
        {
            // 如果这是中心音（长按按钮），强制保持开启状态
            if (appState->interaction.longPressedButtonIndex == i)
            {
                toggles[i]->setToggleState(true, juce::dontSendNotification);
            }
        };
    }
}

void MainComponent::paint(juce::Graphics& g)
{
    if (earxLookAndFeel)
        earxLookAndFeel->drawBackground(g, *this);
}

void MainComponent::prepareToPlay(int samplesPerBlockExpected, double sampleRate)
{
    audioController->initialize(sampleRate);
    appState->system.isInitialized = true;
    appState->notifySystemStateChanged();
}

void MainComponent::getNextAudioBlock(const juce::AudioSourceChannelInfo& bufferToFill)
{
    bufferToFill.clearActiveBufferRegion();
    juce::MidiBuffer dummyMidi;
    audioController->renderNextBlock(*bufferToFill.buffer, dummyMidi,
                          bufferToFill.startSample, bufferToFill.numSamples);
}

void MainComponent::releaseResources()
{
    // 控制器会自动清理资源
}

void MainComponent::timerCallback()
{
    auto now = juce::Time::getMillisecondCounterHiRes();
    
    // 更新长按检测
    interactionController->updateLongPressDetection(now);
    
    // 更新活跃音符
    playbackEngine->updateActiveNotes(now);
    
    // 更新音符显示
    playbackEngine->updateNoteDisplay(currentNoteLabel);
    
    // 更新音频淡入淡出
    audioController->updateFadeTransition();
                
    // 检查自动播放触发
    if (!appState->playback.stopTrigger)
{
        auto onIndices = getActiveToggleIndices();
        if (!onIndices.isEmpty() && 
            now - appState->playback.lastTriggerTime >= (60000.0 / appState->playback.bpm))
        {
            // 使用重载版本，直接传入活跃的toggle索引
            playbackEngine->playNextNote(onIndices);
            appState->playback.lastTriggerTime = now;
        }
    }
    
    // 检查关机计时器
    if (appState->system.shutdownEndTime > 0)
    {
        double remainingTime = (appState->system.shutdownEndTime - now) / 1000.0;
        DBG("Shutdown countdown: " + juce::String(remainingTime) + " seconds remaining");
        
        if (now >= appState->system.shutdownEndTime)
        {
            // 时间到了，直接禁用MIDI输出
            appState->system.midiOutputEnabled = false;
            
            // 添加调试信息
            DBG("Auto shutdown timer expired - MIDI output disabled");
            
            appState->system.shutdownEndTime = 0;
            appState->system.autoShutdownEnabled = false;
            shutdownToggle.setToggleState(false, juce::dontSendNotification); // 不触发回调
            appState->notifySystemStateChanged();
        }
    }
}

void MainComponent::resized()
{
    auto area = getLocalBounds();
    int topPadding = area.getHeight() * 0.10;
    area.removeFromTop(topPadding);
    int sliderHeight = juce::jmax(30, static_cast<int>(area.getHeight() * 0.04));
    int toggleHeight = juce::jmax(35, static_cast<int>(area.getHeight() * 0.05));
    int margin = juce::jmax(3, static_cast<int>(area.getHeight() * 0.005));
    
    // 顶部控制区
    juce::FlexBox controlBox;
    controlBox.flexDirection = juce::FlexBox::Direction::column;
    controlBox.justifyContent = juce::FlexBox::JustifyContent::flexStart;
    controlBox.items.add(juce::FlexItem(bpmSlider).withHeight(sliderHeight).withMargin(margin));
    controlBox.items.add(juce::FlexItem(volumeSlider).withHeight(sliderHeight).withMargin(margin));
    controlBox.items.add(juce::FlexItem(noteDurationSlider).withHeight(sliderHeight).withMargin(margin));
    
    auto controlArea = area.removeFromTop(sliderHeight * 3 + margin * 4);
    controlBox.performLayout(controlArea);
    
    // 模式选择区域
    auto modeArea = area.removeFromTop(toggleHeight + margin * 2);
    auto leftModeArea = modeArea.removeFromLeft(modeArea.getWidth() / 2).reduced(margin);
    auto rightModeArea = modeArea.reduced(margin);
    
    modeCombo.setBounds(leftModeArea);
    scaleCombo.setBounds(rightModeArea);
    
    // 自动关闭控制区 - 单独的水平布局
    auto shutdownArea = area.removeFromTop(toggleHeight + margin * 2);
    auto leftShutdownArea = shutdownArea.removeFromLeft(shutdownArea.getWidth() / 2).reduced(margin);
    auto rightShutdownArea = shutdownArea.reduced(margin);
    
    shutdownToggle.setBounds(leftShutdownArea);
    shutdownDurationCombo.setBounds(rightShutdownArea);
    
    // 圆形排列音符按钮
    auto fullArea = getLocalBounds();
    int centerX = fullArea.getCentreX();
    int centerY = fullArea.getCentreY() - 20;
    int maxRadius = juce::jmin(fullArea.getWidth(), fullArea.getHeight()) * 0.35f;
    int buttonSize = juce::jmax(50, maxRadius / 8);
    int radius = maxRadius - buttonSize / 2;
    
    for (int i = 0; i < toggles.size(); ++i)
    {
        double angle = -juce::MathConstants<double>::halfPi + (i * juce::MathConstants<double>::twoPi / 12.0);
        int buttonX = centerX + static_cast<int>(radius * std::cos(angle)) - buttonSize / 2;
        int buttonY = centerY + static_cast<int>(radius * std::sin(angle)) - buttonSize / 2;
        toggles[i]->setBounds(buttonX, buttonY, buttonSize, buttonSize);
        lights[i]->setVisible(false);
    }
    
    // 中央音名显示区域
    int labelSize = radius * 0.6f;
    int labelX = centerX - labelSize / 2;
    int labelY = centerY - labelSize / 2;
    currentNoteLabel.setBounds(labelX, labelY, labelSize, labelSize);
    float fontSize = labelSize * 0.3f;
    currentNoteLabel.setFont(juce::Font("Arial", fontSize, juce::Font::bold));
    
    // Mode开关在圆环下方
    int modeToggleWidth = fullArea.getWidth() * 0.4f;
    int modeToggleHeight = toggleHeight * 1.5f;
    int modeToggleX = centerX - modeToggleWidth / 2;
    int modeToggleY = centerY + radius + buttonSize / 2 + 30;
    timbreToggle.setBounds(modeToggleX, modeToggleY, modeToggleWidth, modeToggleHeight);
}

// 长按相关方法实现


// ButtonMouseListener 方法实现
void MainComponent::ButtonMouseListener::mouseDown(const juce::MouseEvent& event)
{
    int buttonIndex = parentComponent->findButtonIndex(event.eventComponent);
    if (buttonIndex >= 0)
        {
        parentComponent->appState->interaction.buttonPressStartTimes.set(buttonIndex, 
            juce::Time::getMillisecondCounterHiRes());
    }
}

void MainComponent::ButtonMouseListener::mouseUp(const juce::MouseEvent& event)
{
    int buttonIndex = parentComponent->findButtonIndex(event.eventComponent);
    if (buttonIndex >= 0)
        {
        parentComponent->appState->interaction.buttonPressStartTimes.set(buttonIndex, 0.0);
        }
    }

// 辅助方法已移至文件末尾

int MainComponent::findButtonIndex(juce::Component* button)
    {
    for (int i = 0; i < toggles.size(); ++i)
    {
        if (toggles[i] == button)
            return i;
    }
    return -1;
}

void MainComponent::updateUIFromState()
{
    // 从状态更新UI（如果需要的话）
}

// 所有的音频和交互逻辑已经移到对应的控制器中

// AppState::Listener 实现
void MainComponent::audioStateChanged()
{
    // 响应音频状态变化
    timbreToggle.setToggleState(appState->audio.isPianoMode, juce::dontSendNotification);
    volumeSlider.setValue(appState->audio.masterVolume, juce::dontSendNotification);
    }

void MainComponent::interactionStateChanged()
{
    // 不论哪种模式都要更新按钮视觉状态（包括播放状态高亮）
    interactionController->updateButtonVisualState(toggles);
    
    // 根据当前模式更新按钮状态
    if (appState->interaction.currentMode == AppState::InteractionState::Mode::Scale)
    {
        updateButtonsForScaleMode();
    }
    else
    {
        // Custom 模式：恢复按钮的交互能力
        for (auto* toggle : toggles)
        {
            if (toggle != nullptr)
                toggle->setEnabled(true);
        }
    }
    
    // 更新 UI 组件状态
    modeCombo.setSelectedId(appState->interaction.currentMode == AppState::InteractionState::Mode::Scale ? 2 : 1, 
                           juce::dontSendNotification);
    scaleCombo.setSelectedId(appState->interaction.selectedScaleIndex + 1, juce::dontSendNotification);
    scaleCombo.setVisible(appState->interaction.currentMode == AppState::InteractionState::Mode::Scale);
}

void MainComponent::playbackStateChanged()
{
    // 响应播放状态变化
    bpmSlider.setValue(appState->playback.bpm, juce::dontSendNotification);
    noteDurationSlider.setValue(appState->playback.noteDuration, juce::dontSendNotification);
    }
    
void MainComponent::systemStateChanged()
{
    // 响应系统状态变化
    shutdownToggle.setToggleState(appState->system.autoShutdownEnabled, juce::dontSendNotification);
    
    // 更新下拉菜单选择
    int durationMinutes = appState->system.shutdownDurationMinutes;
    int selectedId = 2; // 默认25分钟
    switch (durationMinutes)
    {
        case 15: selectedId = 1; break;
        case 25: selectedId = 2; break;
        case 35: selectedId = 3; break;
        case 60: selectedId = 4; break;
    }
    shutdownDurationCombo.setSelectedId(selectedId, juce::dontSendNotification);
}

void MainComponent::updateButtonsForScaleMode()
{
    // 获取当前选择音阶的音级模式
    juce::Array<bool> scalePattern = appState->getScalePattern(appState->interaction.selectedScaleIndex);
    
    // 根据音阶模式设置按钮状态
    for (int i = 0; i < toggles.size() && i < scalePattern.size(); ++i)
    {
        if (toggles[i] != nullptr)
        {
            // 设置音阶对应的按钮状态
            toggles[i]->setToggleState(scalePattern[i], juce::dontSendNotification);
            
            // 在Scale模式下禁用按钮点击，但保持视觉反馈
            toggles[i]->setEnabled(false);
            
            // 重要：确保播放状态属性保持不变，不被音阶设置覆盖
            // 播放状态会通过 interactionController->updateButtonVisualState() 设置
            // 这里我们触发重绘以确保视觉效果正确显示
            toggles[i]->repaint();
        }
    }
}

juce::Array<int> MainComponent::getActiveToggleIndices()
{
    juce::Array<int> activeIndices;
    
    if (appState->interaction.currentMode == AppState::InteractionState::Mode::Scale)
    {
        // Scale 模式：根据选择的音阶获取音级
        juce::Array<bool> scalePattern = appState->getScalePattern(appState->interaction.selectedScaleIndex);
        for (int i = 0; i < scalePattern.size(); ++i)
        {
            if (scalePattern[i])
                activeIndices.add(i);
        }
    }
    else
    {
        // Custom 模式：检查用户选择的按钮
        for (int i = 0; i < toggles.size(); ++i)
        {
            if (toggles[i] != nullptr && toggles[i]->getToggleState())
            {
                activeIndices.add(i);
            }
        }
    }
    
    return activeIndices;
}

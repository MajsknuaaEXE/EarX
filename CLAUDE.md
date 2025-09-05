# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

本文件为 Claude Code (claude.ai/code) 在此代码仓库中工作时提供指导。

## 语言偏好
- 请使用中文作为主要交流语言，包含解释、注释和回答。
- 代码仍保持英文关键字，但代码内的注释请使用中文。
- 对话和说明默认用简体中文。

## 项目概述

EarX 是一个基于 JUCE 的 iOS 音频应用程序，专用于听音训练和音乐教育。该应用通过十二半音界面提供互动式音高识别训练，具有多种音色（正弦波和钢琴）和可自定义的播放参数。

## 构建系统

### 项目结构
- **CMakeLists.txt**: 主要的 CMake 项目文件 - 包含项目配置、源文件、模块和构建目标
- **External/JUCE/**: JUCE 框架子目录（优先选择）或回退到 `/Library/JUCE`（系统安装）
- **build-ios/**: iOS 构建输出目录

### 常用命令

生成 iOS 项目：
```bash
# 配置 iOS 构建
cmake -S . -B build-ios -G Xcode \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
  -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=YOUR_TEAM_ID

# 构建项目
cmake --build build-ios --config Debug
```

生成 macOS 项目：
```bash
# 配置 macOS 构建
cmake -S . -B build-mac -G Xcode

# 构建项目  
cmake --build build-mac --config Debug
```

在 Xcode 中打开项目：
```bash
open build-ios/Earx.xcodeproj   # iOS
open build-mac/Earx.xcodeproj   # macOS
```

## 架构

### 核心组件

应用程序遵循模块化的类似 MVC 的架构，具有明确的关注点分离：

#### 1. AppState (`AppState.h/cpp`)
使用观察者模式的中央状态管理系统：
- **AudioState**: 音色切换、音量控制、淡入淡出过渡
- **InteractionState**: 按钮按压处理、长按检测
- **PlaybackState**: BPM、音符持续时间、活动音符跟踪
- **SystemState**: 关闭定时器、MIDI 输出设置

#### 2. MainComponent (`MainComponent.h/cpp`) 
主要 UI 控制器和入口点：
- 继承自 `AudioAppComponent`、`Timer` 和 `AppState::Listener`
- 管理 UI 布局和事件分发
- 处理音频回调路由
- 协调所有其他组件之间的关系

#### 3. AudioController (`AudioController.h/cpp`)
音频处理和合成管理：
- JUCE 合成器设置和管理
- 在钢琴（基于 SFZ）和正弦波之间切换音色
- 具有平滑淡入淡出过渡的音量控制
- 音符播放和语音管理

#### 4. InteractionController (`InteractionController.h/cpp`)
用户交互和手势识别：
- 长按检测（500ms 阈值）
- 按钮状态管理
- 鼠标事件处理
- UI 视觉状态更新

#### 5. PlaybackEngine (`PlaybackEngine.h/cpp`)
音乐播放逻辑和算法：
- 从活动半音中随机选择音符
- 时间和 BPM 管理
- 活动音符跟踪和显示
- 音符序列生成

### 音频组件

#### 合成器语音
- **SineVoice**: 纯正弦波生成
- **PianoVoice**: 使用 `UprightPianoKW-small-SFZ-20190703/` 样本的基于 SFZ 样本的钢琴声音

#### 声音类
- **DummySound**: 基础声音类
- **PianoSound**: 处理 SFZ 文件加载和样本管理

### UI 组件
- **EarxLookAndFeel**: 应用主题的自定义 JUCE LookAndFeel
- **LightIndicator**: 活动音符的视觉反馈
- **SplashScreen**: 应用程序启动屏幕

## 开发指南

### JUCE 模块依赖
项目使用这些 JUCE 模块（在 CMakeLists.txt 中定义）：
- **GUI**: juce_gui_extra, juce_gui_basics, juce_graphics, juce_events
- **Core**: juce_data_structures, juce_core  
- **Audio**: juce_audio_utils, juce_audio_processors, juce_audio_formats, juce_audio_devices, juce_audio_basics
- **DSP**: juce_dsp

### 状态管理模式
- 所有组件应通过 AppState 进行交互，而不是直接耦合
- 使用 AppState::Listener 接口进行反应式更新
- 状态变化应通过 `notify*StateChanged()` 方法触发通知

### 音频线程
- 音频处理在 `AudioController::renderNextBlock()` 中进行
- UI 更新通过 AppState 通知在消息线程上发生
- 使用 JUCE 的线程安全模式进行跨线程通信

### 资源管理
- SFZ 钢琴样本通过 CMake 的 MACOSX_PACKAGE_LOCATION 打包到应用包中
- App 图标资源自动从 Assets.xcassets 或 Builds/iOS/Assets.xcassets 目录检测和包含
- 资源路径在 CMakeLists.txt 中定义，iOS/macOS 分别处理

## 文件组织

```
Source/
├── Main.mm                    # iOS 应用程序入口点
├── MainComponent.*            # 主要 UI 组件
├── AppState.*                 # 集中状态管理
├── AudioController.*          # 音频处理
├── InteractionController.*    # 用户交互处理
├── PlaybackEngine.*          # 音乐播放逻辑
├── EarxLookAndFeel.*         # 自定义 UI 主题
├── LightIndicator.*          # 视觉反馈组件
├── SplashScreen.*            # 启动屏幕
├── MainWindow.*              # 窗口管理
├── *Voice.*                  # 合成器语音实现
├── *Sound.*                  # 声音/样本管理
└── UprightPianoKW-small-SFZ-20190703/  # 钢琴样本库
```

## 版本信息

当前版本：0.3.1（功能历史请参见 CHANGELOG.md）
目标平台：iOS 12.0+，macOS
构建系统：CMake 3.22+，需要 C++17 标准
JUCE 版本：优先使用 External/JUCE 子目录，回退到 `/Library/JUCE`

## 重要开发指导原则

### 代码约定
- 始终遵循现有的代码风格和命名约定
- 优先编辑现有文件而不是创建新文件
- 除非明确要求，否则不要创建文档文件（*.md）或 README 文件
- 不要在代码中添加不必要的注释，除非用户明确要求

### 架构原则
- 通过 AppState 进行组件间通信，避免直接耦合
- 音频处理必须在音频线程中进行，UI 更新在消息线程中进行
- 使用 JUCE 的线程安全模式确保跨线程通信的安全性
- 资源文件（如 SFZ 样本）通过 CMake 的 MACOSX_PACKAGE_LOCATION 正确打包
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

本文件为 Claude Code (claude.ai/code) 在此代码仓库中工作时提供指导。

## 语言偏好
- 请使用中文作为主要交流语言，包含解释、注释和回答。
- 代码仍保持英文关键字，但代码内的注释请使用中文。
- 对话和说明默认用简体中文。

## 项目概述

EarX 是一个混合架构的 iOS 音频应用程序，专用于听音训练和音乐教育。该应用采用 JUCE C++ 音频引擎处理音频逻辑，Flutter 提供现代化 UI 界面。应用通过十二半音界面提供互动式音高识别训练，具有多种音色（正弦波和钢琴）和可自定义的播放参数。

## 构建系统

### 项目结构
- **CMakeLists.txt**: 主要的 CMake 项目文件 - 包含项目配置、源文件、模块和构建目标
- **External/JUCE/**: JUCE 框架子目录（优先选择）或回退到 `/Library/JUCE`（系统安装）
- **build-ios/**: iOS 构建输出目录
- **earxui/**: Flutter UI 前端项目
- **Source/**: JUCE C++ 音频引擎源文件

### 混合架构项目
该项目采用混合架构：
- **JUCE C++ 音频引擎**: 处理所有音频逻辑、合成器、音色切换
- **Flutter UI**: 提供现代化的用户界面
- **CMake 构建系统**: 构建静态库供 Flutter FFI 调用

### 构建命令

#### 方式一：使用自动化构建脚本（推荐）
```bash
# 构建 iOS 静态库（Device + Simulator）
./scripts/build_ios_engine.sh

# 构建特定配置
./scripts/build_ios_engine.sh Debug        # 只构建 Debug
./scripts/build_ios_engine.sh Release      # 只构建 Release
./scripts/build_ios_engine.sh --no-xcframework Debug  # 跳过 XCFramework 生成
```

构建脚本会自动：
- 生成 Xcode 项目（如果不存在）
- 为 iOS 设备和模拟器分别构建
- 将库文件复制到正确位置：`build-ios/Debug-iphoneos/libEarxAudioEngine.a` 等
- 生成 XCFramework：`build-ios/xcframeworks/Debug/EarxAudioEngine.xcframework`

#### 方式二：手动 CMake 构建
```bash
# 在项目根目录下生成 Xcode 项目
cmake -S . -B build-ios -G Xcode

# 构建静态库
cd build-ios
xcodebuild -project Earx.xcodeproj -scheme EarxAudioEngine -configuration Debug \
    -destination 'generic/platform=iOS' build
```

#### Flutter UI 构建
```bash
# 在 earxui/ 目录下
flutter pub get
flutter run
flutter build ios --release

# 分析 Flutter 代码
flutter analyze
```

### 重要构建注意事项
- **JUCE 头文件**: 项目已移除 JuceHeader.h 依赖，改用具体模块头文件
- **静态库输出**: 生成 `libEarxAudioEngine.a` 供 Flutter FFI 使用
- **架构**: 支持 iOS arm64 架构（模拟器和设备）
- **静态库位置**: 构建完成后需要手动复制或通过脚本同步到 `earxui/ios/` 目录
- **钢琴样本**: 使用 Accurate Salamander Grand Piano V6.0 样本库，通过 Flutter 资源系统加载


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
├── AppState.*                 # 集中状态管理
├── AudioController.*          # 音频处理
├── InteractionController.*    # 用户交互处理
├── PlaybackEngine.*          # 音乐播放逻辑
├── EarxAudioEngineFFI.*      # FFI 接口层
├── *Voice.*                  # 合成器语音实现（SineVoice, PianoVoice）
├── *Sound.*                  # 声音/样本管理（DummySound, PianoSound）
└── AccurateSalamanderGrandPianoV6.0_48khz16bit/  # 钢琴样本库

earxui/                       # Flutter UI 前端
├── lib/                      # Dart 源代码
├── ios/                      # iOS 平台特定文件
│   ├── libEarxAudioEngine.a  # 编译后的静态库
│   └── AccurateSalamanderGrandPianoV6.0_48khz16bit/  # 钢琴样本资源
├── pubspec.yaml              # Flutter 依赖配置
└── analysis_options.yaml     # Dart 代码分析配置

build-ios/                    # iOS 构建输出
├── Earx.xcodeproj           # 生成的 Xcode 项目
├── Debug/                   # Debug 构建产物
├── Release/                 # Release 构建产物
└── xcframeworks/            # XCFramework 输出

scripts/
└── build_ios_engine.sh      # iOS 构建自动化脚本
```

## 版本信息

当前版本：0.3.1
目标平台：iOS 12.0+
构建系统：CMake 3.22+，C++17 标准
JUCE 版本：优先使用 External/JUCE 子目录，回退到 `/Library/JUCE`
Flutter 版本：Flutter 3.9.2+，使用 FFI 2.1.2

## 重要开发指导原则

### 开发流程
#### 音频引擎开发
1. 修改 `Source/` 中的 C++ 文件
2. 运行 `./scripts/build_ios_engine.sh` 重新构建静态库
3. 将生成的 `libEarxAudioEngine.a` 复制到 `earxui/ios/` 目录
4. 如果修改了 FFI 接口，需要相应更新 Flutter 中的 Dart 绑定代码

#### UI 开发
1. 修改 `earxui/` 中的 Dart/Flutter 文件
2. 运行 `flutter run` 进行热重载调试
3. 通过 FFI 接口与 C++ 音频引擎通信

#### 测试
- **Flutter 测试**: `flutter test` 在 `earxui/` 目录下
- **C++ 单元测试**: 当前项目无单独的 C++ 测试框架
- **集成测试**: 通过 Flutter 应用进行端到端测试

### 代码约定
- 始终遵循现有的代码风格和命名约定
- 优先编辑现有文件而不是创建新文件
- 除非明确要求，否则不要创建文档文件（*.md）或 README 文件
- 不要在代码中添加不必要的注释，除非用户明确要求
- **重要**: 不要使用 `#include <JuceHeader.h>`，改用具体的模块头文件

### 架构原则
- 通过 AppState 进行组件间通信，避免直接耦合
- 音频处理必须在音频线程中进行，UI 更新在消息线程中进行
- 使用 JUCE 的线程安全模式确保跨线程通信的安全性
- 资源文件（如 SFZ 样本）通过 CMake 的 MACOSX_PACKAGE_LOCATION 正确打包
- Flutter 与 C++ 通过 FFI 接口通信，保持清晰的边界

## FFI 接口

### 核心接口文件
- **EarxAudioEngineFFI.h**: 定义 C 风格的 FFI 接口，提供给 Flutter Dart 调用
- **EarxAudioEngineFFI.cpp**: FFI 接口的具体实现

### 主要 FFI 功能组
1. **音频引擎生命周期**: `earx_initialize()`, `earx_destroy()`
2. **音符播放控制**: `earx_play_note()`, `earx_stop_note()`, `earx_stop_all_notes()`
3. **音色控制**: `earx_set_piano_mode()`, `earx_get_current_timbre()`
4. **音量控制**: `earx_set_master_volume()`, `earx_get_master_volume()`
5. **播放引擎**: `earx_set_bpm()`, `earx_set_note_duration()`, `earx_play_random_note()`
6. **半音选择**: `earx_set_semitone_active()`, `earx_get_semitone_active()`
7. **自动播放**: `earx_start_auto_play()`, `earx_stop_auto_play()`
8. **定时器控制**: `earx_set_timer_enabled()`, `earx_set_timer_duration()`
9. **中心音控制**: `earx_set_center_tone()`, `earx_get_center_tone()`

### FFI 接口约定
- 所有函数返回值：0=成功，负数=错误码
- 半音编号：0-11（C=0, C#=1, ..., B=11）
- MIDI 音符：标准 MIDI 音符编号
- 音量范围：0.0-1.0 浮点数

### **关键开发规则**

#### **忠于 Source 代码原则**
- **Flutter 只是前端 UI**: Flutter (`earxui/`) 仅提供用户界面，所有核心音频逻辑都在 `Source/` 目录的 C++ 代码中实现
- **问题排查必须从 Source 开始**: 检查 bug 和问题时，始终从 `Source/` 目录的源代码开始排查，这里包含真正的业务逻辑
- **数值修改只改 Source**: 当需要更改特定数值（如 BPM、音频参数、延迟时间等）时，只修改 `Source/` 源代码中的相应数值
- **保持函数结构不变**: 修改数值时，不要动原有的函数结构、类设计或架构模式，只改变具体的数值常量
- **Source 是真相源**: `Source/` 目录中的 C++ 代码是应用的核心真相源，Flutter UI 通过 FFI 调用这些功能

#### **修改策略**
1. **定位问题**: 在 `Source/` 目录中找到相关的 .h/.cpp 文件
2. **识别数值**: 找到需要修改的常量、枚举值或配置参数
3. **保守修改**: 只修改数值，保持原有的函数签名、类结构和逻辑流程
4. **重新构建**: 修改后需要重新构建静态库让 Flutter 调用新的逻辑
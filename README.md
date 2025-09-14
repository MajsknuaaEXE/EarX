# EarX - Intelligent Ear Training Tool

*[中文版本](#中文版本) | English*

## 🎵 Project Overview

EarX is a professional music ear training application designed specifically for music education and auditory training. The application uses a hybrid architecture that combines the powerful performance of the JUCE C++ audio engine with the elegant experience of modern Flutter UI.

### ✨ Core Features

- **🎯 Precise Ear Training**: Supports random playback training within the twelve-tone system
- **🎹 Multiple Timbre Options**: Built-in high-quality piano timbres and pure sine wave timbres
- **⚙️ Flexible Parameter Adjustment**: Adjustable BPM, note duration, volume and other parameters
- **🎵 Center Tone Mode**: Long press to set center tone for tonal ear training
- **⏰ Timed Training**: Supports 25/35/60 minute timed training modes
- **🌍 Multi-language Support**: Supports Chinese, English, Japanese, German, French, Korean
- **📚 Custom Note Names**: Supports various note name display methods (sharps, flats, double sharps/flats, etc.)

### 🛠️ Technical Architecture

- **Audio Engine**: JUCE C++ - Professional audio processing framework
- **User Interface**: Flutter - Cross-platform modern UI
- **Build System**: CMake - Cross-platform build management
- **Platform Support**: iOS (primary), macOS (compatible)

## 🚀 Quick Start

### 📋 System Requirements

- **iOS**: iOS 12.0 or higher
- **Development Environment**:
  - Xcode 14.0+
  - Flutter 3.9.2+
  - CMake 3.22+
  - JUCE 7.0+

### 🔧 Build Instructions

#### 1. Clone Project
```bash
git clone https://github.com/MajsknuaaEXE/EarX.git
cd EarX
```

#### 2. Initialize Submodules
```bash
git submodule update --init --recursive
```

#### 3. Build Audio Engine (iOS)
```bash
cd build-ios
cmake -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_BUILD_TYPE=Debug \
    ..
cmake --build . --config Debug
```

#### 4. Build Flutter App
```bash
cd earxui
flutter pub get
flutter run
```

## 📱 Application Usage

### Basic Operations
1. **Select Notes**: Click notes on the dial to select/deselect
2. **Long Press Center Tone**: Long press a note to set it as the center tone for random playback
3. **Adjust Parameters**: Adjust speed, duration, timbre, etc. in settings
4. **Timed Training**: Enable timer mode for focused training sessions

### Advanced Features
- **Custom Note Names**: Click notes to customize displayed note names
- **Multi-language Switching**: Switch interface language in settings
- **Countdown Display**: Training progress ring displayed in timer mode

## 🏗️ Project Structure

```
EarX/
├── Source/                 # JUCE C++ audio engine source code
│   ├── AppState.*          # Application state management
│   ├── AudioController.*   # Audio controller
│   ├── PlaybackEngine.*    # Playback engine
│   ├── EarxAudioEngineFFI.*# FFI interface
│   └── ...
├── earxui/                 # Flutter UI frontend
│   ├── lib/               # Dart source code
│   │   ├── main.dart      # Application entry
│   │   ├── wheel_dial.dart# Dial component
│   │   ├── audio_engine.dart# Audio engine binding
│   │   └── ...
│   └── ...
├── External/               # External dependencies
│   └── JUCE/              # JUCE audio framework
├── build-ios/             # iOS build output
├── CMakeLists.txt         # CMake configuration
├── LICENSE                # MIT license
└── CHANGELOG.md           # Update log
```

## 🤝 Contributing

We welcome community contributions! Please follow these steps:

1. Fork this project
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

### Development Guidelines
- Follow existing code style
- Add appropriate comments
- Ensure error-free builds
- Test new feature compatibility

## 📄 License

This project is open source under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- **JUCE** - Professional audio development framework
- **Flutter** - Cross-platform UI development framework
- **Salamander Grand Piano** - High-quality piano timbre samples
- Support from all contributors and users

## 📞 Contact

- **Issue Reports**: Please submit via [GitHub Issues](https://github.com/MajsknuaaEXE/EarX/issues)
- **Feature Suggestions**: Welcome to discuss new feature ideas in Issues

---

## 中文版本

# EarX - 智能听音训练工具

## 🎵 项目简介

EarX 是一个专业的音乐听音训练应用，专为音乐教育和听觉训练设计。应用采用混合架构，结合 JUCE C++ 音频引擎的强大性能和 Flutter 现代化 UI 的优雅体验。

### ✨ 核心特性

- **🎯 精准听音训练**：支持十二半音体系的随机播放训练
- **🎹 多种音色选择**：内置高品质钢琴音色和纯正弦波音色
- **⚙️ 灵活参数调节**：可调节 BPM、音符时值、音量等参数
- **🎵 中心音模式**：长按设置中心音，构建调性听音训练
- **⏰ 定时训练**：支持 25/35/60 分钟定时训练模式
- **🌍 多语言支持**：支持中文、英文、日文、德文、法文、韩文
- **📚 自定义音名**：支持多种音名显示方式（升号、降号、重升重降等）

### 🛠️ 技术架构

- **音频引擎**：JUCE C++ - 专业音频处理框架
- **用户界面**：Flutter - 跨平台现代化 UI
- **构建系统**：CMake - 跨平台构建管理
- **平台支持**：iOS（主要），macOS（兼容）

## 🚀 快速开始

### 📋 系统要求

- **iOS**: iOS 12.0 或更高版本
- **开发环境**:
  - Xcode 14.0+
  - Flutter 3.9.2+
  - CMake 3.22+
  - JUCE 7.0+

### 🔧 构建说明

#### 1. 克隆项目
```bash
git clone https://github.com/MajsknuaaEXE/EarX.git
cd EarX
```

#### 2. 初始化子模块
```bash
git submodule update --init --recursive
```

#### 3. 构建音频引擎 (iOS)
```bash
cd build-ios
cmake -G Xcode \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT=iphonesimulator \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_BUILD_TYPE=Debug \
    ..
cmake --build . --config Debug
```

#### 4. 构建 Flutter 应用
```bash
cd earxui
flutter pub get
flutter run
```

## 📱 应用使用

### 基础操作
1. **选择音级**：点击圆盘上的音级进行选择/取消
2. **长按中心音**：长按音级设置为随机播放的中心音
3. **调节参数**：在设置界面调节速度、时值、音色等
4. **定时训练**：开启定时模式进行专注训练

### 高级功能
- **音名自定义**：点击音级可自定义显示的音名
- **多语言切换**：在设置中切换界面语言
- **倒计时显示**：定时模式下会显示训练进度环

## 🤝 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/新功能`)
3. 提交更改 (`git commit -am '添加新功能'`)
4. 推送到分支 (`git push origin feature/新功能`)
5. 创建 Pull Request

### 开发规范
- 遵循现有的代码风格
- 添加适当的注释（中文）
- 确保构建无错误
- 测试新功能的兼容性

## 📄 许可证

本项目基于 [MIT 许可证](LICENSE) 开源。

## 🙏 致谢

- **JUCE** - 专业音频开发框架
- **Flutter** - 跨平台 UI 开发框架
- **Salamander Grand Piano** - 高品质钢琴音色样本
- 所有贡献者和用户的支持

## 📞 联系方式

- **问题反馈**：请在 [GitHub Issues](https://github.com/MajsknuaaEXE/EarX/issues) 提交
- **功能建议**：欢迎在 Issues 中讨论新功能想法

---

**EarX v1.0.1** - 让音乐听觉训练更智能、更有趣！🎵
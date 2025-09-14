# EarX Changelog / EarX 更新日志

*[中文版本](#中文版本) | English*

## [v1.0.1] - 2025-09-14
### 🚀 Performance Optimization Release
#### Architecture Optimizations
- **Code Structure Optimization**: Further streamlined project structure for improved maintainability
- **Enhanced FFI Interface**: Improved data transmission efficiency between C++ and Flutter
- **Build System Optimization**: Refined CMake configuration and iOS build process
- **Static Library Optimization**: Optimized audio engine build artifact size and loading speed

#### Performance Improvements
- **Audio Processing Optimization**: Reduced audio processing latency, improved real-time response
- **Memory Management Optimization**: Optimized memory usage during timbre switching
- **State Management Optimization**: Improved application state synchronization mechanism
- **Resource Loading Optimization**: Enhanced piano sample loading speed

#### Development Experience Improvements
- **Documentation Enhancement**: Updated project documentation and build guides
- **Code Comments**: Added Chinese comments for key code sections
- **Build Scripts**: Enhanced automated build scripts
- **Project Configuration**: Optimized .gitignore and project configuration files

#### Bug Fixes
- Fixed audio playback issues under specific conditions
- Improved stability on low-memory devices
- Enhanced error handling and exception recovery mechanisms

## [v1.0.0] - 2025-09-13
### 🎉 First Public Release
#### Major Architecture Upgrade
- **New Frontend Architecture**: Upgraded from native JUCE UI to Flutter cross-platform interface
- **Audio Engine Optimization**: Maintained JUCE C++ core audio engine, communicating with Flutter via FFI
- **Hybrid Architecture Design**: Combined C++ high-performance audio processing with Flutter modern UI

#### New Features
- **High-Quality Piano Timbre**: Integrated Accurate Salamander Grand Piano V6.0 sample library
- **Multi-language Support**: Supports Chinese, English, Japanese, German, French, Korean interfaces
- **Timed Training Mode**: Supports 25/35/60 minute focused training sessions
- **Tonal Ear Training**: Long press to set center tone for tonal ear training experience
- **Custom Note Name Display**: Supports various note name methods including sharps, flats, double sharps/flats

#### User Experience Optimizations
- **Modern UI Design**: Brand new circular dial interaction interface and visual effects
- **Smooth Animation Interactions**: Optimized button response and state transition animations
- **Smart Parameter Control**: Precise control of BPM, note duration, volume and other parameters
- **Training Progress Display**: Visual countdown ring in timed mode

#### Technical Improvements
- **Cross-platform Compatibility**: Foundation laid for future Android and desktop versions
- **Performance Optimization**: Reduced audio latency, improved response speed
- **Open Source Preparation**: Complete documentation and open source license configuration

---

## [Unreleased - Internal Testing Versions]
The following versions were internal iOS testing versions, integrated into v1.0.0 official release.

### [v0.3.0] - In Development
#### Added
- Volume control optimization
- Piano timbre integration
- Center tone mode
- Major UI overhaul with semitone circle

### [v0.2.1] - In Development
#### Added
- UI beautification
- Splash screen addition

### [v0.2.0] - In Development
#### Optimized
- Random playback mechanism optimization
- Indicator light duration synchronized with note duration
#### Added
- Timer shutdown functionality

### [v0.1.1] - In Development
#### Added
- iOS support for random playback within twelve semitone system (allowing octave variations)
- Adjustable Note Length, BPM, Output Volume
- Sine wave timbre integration

---

## 中文版本

## [v1.0.1] - 2025-09-14
### 🚀 性能优化版本
#### 架构优化
- **代码结构优化**：进一步精简项目结构，提升维护性
- **FFI 接口完善**：改进 C++ 与 Flutter 间的数据传输效率
- **构建系统优化**：完善 CMake 配置和 iOS 构建流程
- **静态库优化**：优化音频引擎编译产物大小和加载速度

#### 性能提升
- **音频处理优化**：减少音频处理延迟，提升实时响应
- **内存管理优化**：优化音色切换时的内存使用
- **状态管理优化**：改进应用状态同步机制
- **资源加载优化**：提升钢琴样本加载速度

#### 开发体验改进
- **文档完善**：更新项目文档和构建指南
- **代码注释**：增加关键代码的中文注释
- **构建脚本**：完善自动化构建脚本
- **项目配置**：优化 .gitignore 和项目配置文件

#### Bug 修复
- 修复特定情况下的音频播放异常
- 优化低内存设备的稳定性
- 改进错误处理和异常恢复机制

## [v1.0.0] - 2025-09-13
### 🎉 首次公开发布
#### 重大架构升级
- **全新前端架构**：从原生 JUCE UI 升级到 Flutter 跨平台界面
- **音频引擎优化**：保持 JUCE C++ 核心音频引擎，通过 FFI 与 Flutter 通信
- **混合架构设计**：结合 C++ 高性能音频处理和 Flutter 现代化 UI

#### 新增功能
- **高品质钢琴音色**：集成 Accurate Salamander Grand Piano V6.0 音色库
- **多语言支持**：支持中文、英文、日文、德文、法文、韩文界面
- **定时训练模式**：支持 25/35/60 分钟专注训练
- **调性听音训练**：长按设置中心音，构建调性听音体验
- **自定义音名显示**：支持升号、降号、重升重降等多种音名方式

#### 用户体验优化
- **现代化 UI 设计**：全新的圆盘交互界面和视觉效果
- **流畅动画交互**：优化按钮响应和状态切换动画
- **智能参数调节**：BPM、音符时值、音量等参数的精确控制
- **训练进度显示**：定时模式下的可视化倒计时环

#### 技术改进
- **跨平台兼容**：为未来 Android 和桌面版本奠定基础
- **性能优化**：音频延迟降低，响应速度提升
- **开源准备**：完整的文档和开源许可证配置

---

## [Unreleased - 内部测试版本]
以下版本为 iOS 内部测试版本，已整合到 v1.0.0 正式版本中。

### [v0.3.0] - 开发中
#### 新增
- 优化音量调节
- 加入钢琴音色
- 加入中心音程模式
- 大改UI，加入半音圈

### [v0.2.1] - 开发中
#### 新增
- 美化 UI
- 加入启动界面

### [v0.2.0] - 开发中
#### 优化
- 优化随机播放机制
- 指示灯保持时长与音符时值同步
#### 新增
- 加入定时关闭功能

### [v0.1.1] - 开发中
#### 新增
- iOS 端支持十二个半音体系内随机播放选中的音级（允许八度上下）
- 允许调节 Note Length、BPM、Output Volume
- 加入正弦波音色
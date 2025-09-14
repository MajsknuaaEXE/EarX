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
git clone https://github.com/你的用户名/EarX.git
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

## 🏗️ 项目结构

```
EarX/
├── Source/                 # JUCE C++ 音频引擎源码
│   ├── AppState.*          # 应用状态管理
│   ├── AudioController.*   # 音频控制器
│   ├── PlaybackEngine.*    # 播放引擎
│   ├── EarxAudioEngineFFI.*# FFI 接口
│   └── ...
├── earxui/                 # Flutter UI 前端
│   ├── lib/               # Dart 源码
│   │   ├── main.dart      # 应用入口
│   │   ├── wheel_dial.dart# 圆盘组件
│   │   ├── audio_engine.dart# 音频引擎绑定
│   │   └── ...
│   └── ...
├── External/               # 外部依赖
│   └── JUCE/              # JUCE 音频框架
├── build-ios/             # iOS 构建输出
├── CMakeLists.txt         # CMake 配置
├── LICENSE                # MIT 许可证
└── CHANGELOG.md           # 更新日志
```

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

- **问题反馈**：请在 [GitHub Issues](https://github.com/你的用户名/EarX/issues) 提交
- **功能建议**：欢迎在 Issues 中讨论新功能想法

---

**EarX v1.0.0** - 让音乐听觉训练更智能、更有趣！🎵
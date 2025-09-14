cmake_minimum_required(VERSION 3.22)

project(Earx VERSION 1.0.0 LANGUAGES CXX OBJC OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ===== JUCE 引入 =====
# 方式A：子目录（推荐）
set(JUCE_DIR "${CMAKE_SOURCE_DIR}/External/JUCE" CACHE STRING "Path to JUCE root")
if(EXISTS "${JUCE_DIR}/CMakeLists.txt")
    add_subdirectory("${JUCE_DIR}" EXCLUDE_FROM_ALL)
else()
    # 方式B：系统安装
    set(JUCE_DIR "/Library/JUCE" CACHE STRING "Path to JUCE root")
    if(NOT EXISTS "${JUCE_DIR}/CMakeLists.txt")
        message(FATAL_ERROR "JUCE not found. Set JUCE_DIR to your JUCE root (contains modules/ and CMakeLists.txt).")
    endif()
    add_subdirectory("${JUCE_DIR}" EXCLUDE_FROM_ALL)
endif()

# ===== 核心音频引擎源文件 =====
set(SOURCES
    Source/AppState.cpp
    Source/AudioController.cpp
    Source/DummySound.cpp
    Source/InteractionController.cpp
    Source/PianoSound.cpp
    Source/PianoVoice.cpp
    Source/PlaybackEngine.cpp
    Source/SineVoice.cpp
    Source/EarxAudioEngineFFI.cpp
)

set(HEADERS
    Source/AppState.h
    Source/AudioController.h
    Source/DummySound.h
    Source/InteractionController.h
    Source/PianoSound.h
    Source/PianoVoice.h
    Source/PlaybackEngine.h
    Source/SineVoice.h
    Source/EarxAudioEngineFFI.h
)

# ===== 创建音频引擎库 =====
# 改为静态库供Flutter FFI使用
add_library(EarxAudioEngine STATIC ${SOURCES} ${HEADERS})

# 注释掉 JuceHeader.h 生成 - 静态库不需要
# juce_generate_juce_header(EarxAudioEngine)

# 音频引擎核心 JUCE 模块
target_link_libraries(EarxAudioEngine PRIVATE
    juce::juce_core
    juce::juce_data_structures
    juce::juce_events

    juce::juce_audio_utils
    juce::juce_audio_processors
    juce::juce_audio_formats
    juce::juce_audio_devices
    juce::juce_audio_basics

    juce::juce_dsp
)

# Xcode 平台与构建属性（确保可同时针对 iOS 与模拟器构建）
if(APPLE)
    # 允许目标在 iOS 真机与 iOS 模拟器平台上构建
    set_target_properties(EarxAudioEngine PROPERTIES
        XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS "iphonesimulator iphoneos"
        XCODE_ATTRIBUTE_SKIP_INSTALL "YES"
        XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
    )
endif()

# 统一编译定义（不要再去碰模块内部）
target_compile_definitions(EarxAudioEngine PRIVATE
    JUCE_APPLICATION_NAME_STRING="EarX"
    JUCE_APPLICATION_VERSION_STRING="${PROJECT_VERSION}"
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_STRICT_REFCOUNTEDPOINTER=1
    JUCE_STANDALONE_APPLICATION=1
    # iOS特定：禁用MIDI以避免断言失败
    JUCE_ALSA=0
    JUCE_USE_ANDROID_MIDI_API=0
    JUCE_USE_WINRT_MIDI=0
    JUCE_DISABLE_AUDIO_MIXING_WITH_OTHER_APPS=0
    # 完全禁用MIDI功能
    JUCE_USE_COREMIDI=0
    JUCE_PLUGINHOST_AU=0
    JUCE_PLUGINHOST_VST3=0
    JUCE_USE_MP3AUDIOFORMAT=0
    # 禁用MIDI设备扫描
    JUCE_DONT_AUTO_OPEN_MIDI_DEVICES_ON_MOBILE=1
    $<$<CONFIG:Debug>:DEBUG=1;_DEBUG=1>
)

# 头文件路径（你的工程里还有自有头）
target_include_directories(EarxAudioEngine PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

# =============================================
# 钢琴样本（Accurate Salamander Grand Piano）
file(GLOB_RECURSE PIANO_SAMPLES
    "Source/AccurateSalamanderGrandPianoV6.0_48khz16bit/48khz16bit_vel9_dry_flac/*.flac")

set(PIANO_META
    Source/AccurateSalamanderGrandPianoV6.0_48khz16bit/README.txt
    Source/AccurateSalamanderGrandPianoV6.0_48khz16bit/README.orig.txt
    Source/AccurateSalamanderGrandPianoV6.0_48khz16bit/sfz/Accurate-SalamanderGrandPiano_flat.Recommended_vel9_dry_flac_48_84.sfz
)

# 钢琴样本将通过Flutter资源系统加载，无需编译进库


# 警告级别
target_compile_options(EarxAudioEngine PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-Wno-deprecated-declarations>
    $<$<COMPILE_LANGUAGE:OBJCXX>:-Wno-deprecated-declarations>
)

# 导出头文件给Flutter使用
target_include_directories(EarxAudioEngine PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/Source"
)

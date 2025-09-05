cmake_minimum_required(VERSION 3.22)

project(Earx VERSION 0.3.1 LANGUAGES CXX OBJC OBJCXX)

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

# ===== 源文件 =====
set(SOURCES
    Source/AppState.cpp
    Source/AudioController.cpp
    Source/DummySound.cpp
    Source/EarxLookAndFeel.cpp
    Source/InteractionController.cpp
    Source/IOSApp.cpp
    Source/LightIndicator.cpp
    Source/MainComponent.cpp
    Source/MainWindow.cpp
    Source/PianoSound.cpp
    Source/PianoVoice.cpp
    Source/PlaybackEngine.cpp
    Source/SineVoice.cpp
    Source/SplashScreen.cpp
    Source/Main.mm
)

set(HEADERS
    Source/AppState.h
    Source/AudioController.h
    Source/DummySound.h
    Source/EarxLookAndFeel.h
    Source/InteractionController.h
    Source/IOSApp.h
    Source/LightIndicator.h
    Source/MainComponent.h
    Source/MainWindow.h
    Source/PianoSound.h
    Source/PianoVoice.h
    Source/PlaybackEngine.h
    Source/SineVoice.h
    Source/SplashScreen.h
)

# App 图标（Assets）
set(APP_ICON_RESOURCES)
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Assets.xcassets/AppIcon.appiconset/Contents.json")
    file(GLOB APP_ICONS "Assets.xcassets/AppIcon.appiconset/*.png")
    set(APP_ICON_RESOURCES ${APP_ICONS} "Assets.xcassets/AppIcon.appiconset/Contents.json")
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Builds/iOS/Assets.xcassets/AppIcon.appiconset/Contents.json")
    file(GLOB APP_ICONS "Builds/iOS/Assets.xcassets/AppIcon.appiconset/*.png")
    set(APP_ICON_RESOURCES ${APP_ICONS} "Builds/iOS/Assets.xcassets/AppIcon.appiconset/Contents.json")
endif()

# ===== 创建 GUI App（官方） =====
juce_add_gui_app(Earx
    PRODUCT_NAME "EarX"
    # 如果你需要开 VST/AU 等插件格式，改用 juce_add_plugin
)

# 生成 JuceHeader.h（代替你旧的 JuceLibraryCode）
juce_generate_juce_header(Earx)

# 源码
target_sources(Earx PRIVATE ${SOURCES} ${HEADERS})

# 依赖的 JUCE 模块（按你项目需求增减）
target_link_libraries(Earx PRIVATE
    juce::juce_gui_extra
    juce::juce_gui_basics
    juce::juce_graphics
    juce::juce_events
    juce::juce_data_structures
    juce::juce_core

    juce::juce_audio_utils
    juce::juce_audio_processors
    juce::juce_audio_formats
    juce::juce_audio_devices
    juce::juce_audio_basics

    juce::juce_dsp
)

# 统一编译定义（不要再去碰模块内部）
target_compile_definitions(Earx PRIVATE
    JUCE_APPLICATION_NAME_STRING="EarX"
    JUCE_APPLICATION_VERSION_STRING="${PROJECT_VERSION}"
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_STRICT_REFCOUNTEDPOINTER=1
    JUCE_STANDALONE_APPLICATION=1
    $<$<CONFIG:Debug>:DEBUG=1;_DEBUG=1>
)

# 头文件路径（你的工程里还有自有头）
target_include_directories(Earx PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

# =============================================
# 钢琴样本（打进 bundle，不做二进制内嵌）
file(GLOB_RECURSE PIANO_SAMPLES
    "Source/UprightPianoKW-small-SFZ-20190703/samples/*.wav")

set(PIANO_META
    Source/UprightPianoKW-small-SFZ-20190703/cc0.txt
    Source/UprightPianoKW-small-SFZ-20190703/photo.jpg
    Source/UprightPianoKW-small-SFZ-20190703/readme.txt
    Source/UprightPianoKW-small-SFZ-20190703/UprightPianoKW-small-20190703.sfz
)

set_source_files_properties(${PIANO_META} PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources/UprightPianoKW-small-SFZ-20190703")
set_source_files_properties(${PIANO_SAMPLES} PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources/UprightPianoKW-small-SFZ-20190703/samples")
target_sources(Earx PRIVATE ${PIANO_META} ${PIANO_SAMPLES} ${APP_ICON_RESOURCES})


# ===== 平台差异化设置 & 资源放包 =====
if(CMAKE_SYSTEM_NAME STREQUAL "iOS")
    # iOS 包信息 + 自动签名（Personal Team 也能跑真机）
    set_target_properties(Earx PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.earx.earx"
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "12.0"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_ENABLE_BITCODE NO
        XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        # 如有 TeamID：cmake -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=YOURTEAM ..
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM}"
    )

    # 把资源打进 iOS 包
    set_source_files_properties(${PIANO_RESOURCES} PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources/UprightPianoKW-small-SFZ-20190703)
    set_source_files_properties(${APP_ICON_RESOURCES} PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources)
    target_sources(Earx PRIVATE ${PIANO_RESOURCES} ${APP_ICON_RESOURCES})

else() # macOS
    set_target_properties(Earx PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.earx.earx"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.earx.earx"
    )

    # 把资源打进 macOS 包
    set_source_files_properties(${PIANO_RESOURCES} PROPERTIES
        MACOSX_PACKAGE_LOCATION Resources/UprightPianoKW-small-SFZ-20190703)
    target_sources(Earx PRIVATE ${PIANO_RESOURCES})
endif()

# 警告级别
target_compile_options(Earx PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-Wno-deprecated-declarations>
    $<$<COMPILE_LANGUAGE:OBJCXX>:-Wno-deprecated-declarations>
)
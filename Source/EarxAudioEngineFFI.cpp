#include "EarxAudioEngineFFI.h"
#include "AppState.h"
#include "AudioController.h"
#include "PlaybackEngine.h"
#include <memory>
#include <thread>
#include <atomic>
#include <chrono>
#include <juce_audio_devices/juce_audio_devices.h>
#include <juce_core/juce_core.h>
#include <juce_events/juce_events.h>
#if JUCE_MAC || JUCE_IOS
#include <dispatch/dispatch.h>
#include <pthread.h>
#endif

// 全局实例
static std::unique_ptr<AppState> g_appState;
static std::unique_ptr<AudioController> g_audioController;
static std::unique_ptr<PlaybackEngine> g_playbackEngine;
static std::unique_ptr<juce::AudioDeviceManager> g_deviceManager;
static bool g_initialized = false;

// 音频回调类
class AudioEngineCallback : public juce::AudioIODeviceCallback
{
public:
    AudioEngineCallback(AudioController* controller) : audioController(controller) {}
    
    void audioDeviceIOCallbackWithContext(const float* const* inputChannelData,
                                        int numInputChannels,
                                        float* const* outputChannelData,
                                        int numOutputChannels,
                                        int numSamples,
                                        const juce::AudioIODeviceCallbackContext& context) override
    {
        if (audioController)
        {
            double currentTime = juce::Time::getMillisecondCounterHiRes();
            
            // 检查定时器是否到期，如果到期则停止自动播放
            if (g_appState && g_appState->system.timerEnabled)
            {
                double elapsedMs = currentTime - g_appState->system.timerStartTime;
                double totalMs = g_appState->system.timerDurationMinutes * 60.0 * 1000.0;
                double remainingMs = totalMs - elapsedMs;
                int remainingSeconds = (int)(remainingMs / 1000.0);
                
                // 每秒输出一次剩余时间
                static double lastDebugTime = 0;
                if (currentTime - lastDebugTime >= 1000.0) // 每1000ms输出一次
                {
                    int minutes = remainingSeconds / 60;
                    int seconds = remainingSeconds % 60;
                    DBG("Timer remaining: " + juce::String(minutes) + "m " + juce::String(seconds) + "s");
                    lastDebugTime = currentTime;
                }
                
                if (elapsedMs >= totalMs)
                {
                    // 定时器到期，停止自动播放
                    DBG("Timer expired! Stopping auto play and timer");
                    g_appState->playback.autoPlayEnabled = false;
                    g_appState->system.timerEnabled = false; // 关闭定时器
                    
                    // 停止所有正在播放的音符
                    if (g_audioController)
                    {
                        g_audioController->stopAllNotes();
                    }
                    
                    g_appState->notifySystemStateChanged();
                    g_appState->notifyPlaybackStateChanged();
                }
            }
            
            // 先驱动到时停音逻辑
            if (g_playbackEngine)
            {
                g_playbackEngine->updateActiveNotes(currentTime);
                
                // 处理自动播放逻辑
                if (g_appState && g_appState->playback.autoPlayEnabled)
                {
                    double timeSinceLastPlay = currentTime - g_appState->playback.lastAutoPlayTime;
                    double beatInterval = 60000.0 / g_appState->playback.bpm; // 毫秒
                    
                    if (timeSinceLastPlay >= beatInterval)
                    {
                        g_playbackEngine->playNextNote();
                        g_appState->playback.lastAutoPlayTime = currentTime;
                    }
                }
            }
            
            juce::AudioBuffer<float> buffer(outputChannelData, numOutputChannels, numSamples);
            buffer.clear();
            juce::MidiBuffer midiBuffer;
            audioController->renderNextBlock(buffer, midiBuffer, 0, numSamples);
        }
    }
    
    void audioDeviceAboutToStart(juce::AudioIODevice* device) override {}
    void audioDeviceStopped() override {}
    
private:
    AudioController* audioController;
};

static std::unique_ptr<AudioEngineCallback> g_audioCallback;

// iOS/macOS 主线程派发帮助：C 接口函数指针形式，避免捕获 lambda 无法转换
#if JUCE_MAC || JUCE_IOS
struct EarxInitAudioArgs {
    bool* initSuccess;
    juce::String* errorMsg;
};

static void earx_initAudioDeviceOnMain(void* ctx)
{
    auto* args = static_cast<EarxInitAudioArgs*>(ctx);
    printf("[EarX C++] 开始音频设备初始化（主线程）\n");
    try {
        if (juce::MessageManager::getInstanceWithoutCreating() == nullptr)
            juce::MessageManager::getInstance();

        printf("[EarX C++] 创建音频设备管理器\n");
        g_deviceManager = std::make_unique<juce::AudioDeviceManager>();

        printf("[EarX C++] 开始初始化音频设备（0输入，2输出）\n");
        juce::String error = g_deviceManager->initialise(0, 2, nullptr, false);

        if (error.isEmpty()) {
            *(args->initSuccess) = true;
        } else {
            printf("[EarX C++] 音频设备初始化失败: %s\n", error.toRawUTF8());
            *(args->errorMsg) = error;
        }
    } catch (...) {
        printf("[EarX C++] 音频设备初始化过程中发生异常\n");
        *(args->errorMsg) = "Exception during initialization";
    }
}

static void earx_addAudioCallbackOnMain(void*)
{
    if (g_deviceManager && g_audioCallback)
        g_deviceManager->addAudioCallback(g_audioCallback.get());
}
#endif


extern "C" {

int earx_initialize(double sampleRate) {
    printf("[EarX C++] 开始初始化音频引擎，采样率: %.2f\n", sampleRate);
    try {
        if (g_initialized) {
            earx_destroy();
        }
        
        // 创建核心组件
        printf("[EarX C++] 创建应用状态组件\n");
        g_appState = std::make_unique<AppState>();
        
        // 启用MIDI输出（断言问题已通过音频设备初始化方式修复）
        g_appState->system.midiOutputEnabled = true;
        
        printf("[EarX C++] 创建音频控制器和播放引擎\n");
        g_audioController = std::make_unique<AudioController>(g_appState.get());
        g_playbackEngine = std::make_unique<PlaybackEngine>(g_appState.get(), g_audioController.get());
        
        // 先不初始化音频控制器，等获取实际采样率后统一初始化
        
        g_audioCallback = std::make_unique<AudioEngineCallback>(g_audioController.get());

       #if JUCE_MAC || JUCE_IOS
        // iOS/macOS：在主线程初始化设备管理器，确保 MessageManager 存在，避免 JUCE 断言
        try {
            bool initSuccess = false;
            juce::String errorMsg;

            // 如果当前就是主线程，则直接执行；否则同步派发到主线程
            bool onMain = false;
           #if JUCE_IOS || JUCE_MAC
            onMain = (pthread_main_np() != 0);
           #endif

            if (onMain) {
                EarxInitAudioArgs args{ &initSuccess, &errorMsg };
                earx_initAudioDeviceOnMain(&args);
            } else {
                EarxInitAudioArgs args{ &initSuccess, &errorMsg };
                // 同步派发，使用栈上参数，函数返回后即安全
                dispatch_sync_f(dispatch_get_main_queue(), &args, earx_initAudioDeviceOnMain);
            }

            if (!initSuccess) {
                DBG("Audio device initialization error: " + errorMsg);
                printf("[EarX C++] Audio device initialization error: %s\n", errorMsg.toRawUTF8());
                return -1;
            }

        } catch (...) {
            DBG("Exception during audio device initialization");
            printf("[EarX C++] Exception during audio device initialization\n");
            return -1;
        }
       #else
        // 其它平台维持原逻辑
        g_deviceManager = std::make_unique<juce::AudioDeviceManager>();
        juce::String error = g_deviceManager->initialise(0, 2, nullptr, false);
        if (error.isNotEmpty())
        {
            DBG("Audio device initialization error: " + error);
            return -1;
        }
        g_deviceManager->addAudioCallback(g_audioCallback.get());
       #endif
        
        // 获取实际音频设备采样率并初始化音频控制器（在添加音频回调之前完成，避免未初始化就进入回调）
        double finalSampleRate = sampleRate;
        if (auto* device = g_deviceManager->getCurrentAudioDevice())
        {
            double actualSampleRate = device->getCurrentSampleRate();
            if (actualSampleRate > 0)
            {
                finalSampleRate = actualSampleRate;
                DBG("Device actual sample rate: " + juce::String(actualSampleRate));
            }
        }
        
        // 统一初始化音频控制器，避免重复设置
        printf("[EarX C++] 初始化音频控制器，采样率: %.2f\n", finalSampleRate);
        g_audioController->initialize(finalSampleRate);

        // 控制器初始化完毕后再添加音频回调（iOS/macOS 在主线程执行更安全）
       #if JUCE_MAC || JUCE_IOS
        {
            bool onMain = false;
           #if JUCE_IOS || JUCE_MAC
            onMain = (pthread_main_np() != 0);
           #endif
            if (onMain) earx_addAudioCallbackOnMain(nullptr);
            else dispatch_sync_f(dispatch_get_main_queue(), nullptr, earx_addAudioCallbackOnMain);
        }
       #else
        if (g_deviceManager && g_audioCallback)
            g_deviceManager->addAudioCallback(g_audioCallback.get());
       #endif

        printf("[EarX C++] 音频引擎初始化成功完成\n");
        g_initialized = true;
        return 0;
    } catch (...) {
        printf("[EarX C++] 音频引擎初始化过程中发生异常\n");
        return -1;
    }
}

int earx_destroy() {
    try {
        if (g_deviceManager && g_audioCallback) {
           #if JUCE_MAC || JUCE_IOS
            // 简化iOS销毁逻辑，避免死锁
            try {
                if (g_deviceManager)
                {
                    g_deviceManager->removeAudioCallback(g_audioCallback.get());
                    g_deviceManager->closeAudioDevice();
                }
                g_audioCallback.reset();
                g_deviceManager.reset();
            } catch (...) {
                // 忽略销毁时的异常
                g_audioCallback.reset();
                g_deviceManager.reset();
            }
           #else
            g_deviceManager->removeAudioCallback(g_audioCallback.get());
            g_deviceManager->closeAudioDevice();
            g_audioCallback.reset();
            g_deviceManager.reset();
           #endif
        } else {
            g_audioCallback.reset();
            g_deviceManager.reset();
        }
        g_playbackEngine.reset();
        g_audioController.reset();
        g_appState.reset();
        g_initialized = false;
        return 0;
    } catch (...) {
        return -2;
    }
}

int earx_play_note(int midiNote, float velocity) {
    if (!g_initialized || !g_audioController) return -100;
    try {
        g_audioController->playNote(midiNote, velocity);
        return 0;
    } catch (...) {
        return -3;
    }
}

int earx_stop_note(int midiNote) {
    if (!g_initialized || !g_audioController) return -100;
    try {
        g_audioController->stopNote(midiNote);
        return 0;
    } catch (...) {
        return -4;
    }
}

int earx_stop_all_notes() {
    if (!g_initialized || !g_audioController) return -100;
    try {
        g_audioController->stopAllNotes();
        return 0;
    } catch (...) {
        return -5;
    }
}

int earx_set_piano_mode(int isPianoMode) {
    if (!g_initialized || !g_audioController) return -100;
    try {
        g_audioController->switchTimbre(isPianoMode != 0);
        return 0;
    } catch (...) {
        return -6;
    }
}

int earx_get_current_timbre() {
    if (!g_initialized || !g_appState) return -100;
    try {
        return g_appState->audio.isPianoMode ? 1 : 0;
    } catch (...) {
        return -7;
    }
}

int earx_set_master_volume(float volume) {
    if (!g_initialized || !g_audioController) return -100;
    try {
        g_audioController->setMasterVolume(juce::jlimit(0.0f, 1.0f, volume));
        return 0;
    } catch (...) {
        return -8;
    }
}

float earx_get_master_volume() {
    if (!g_initialized || !g_appState) return 0.0f;
    try {
        return g_appState->audio.masterVolume;
    } catch (...) {
        return 0.0f;
    }
}

int earx_set_bpm(double bpm) {
    if (!g_initialized || !g_appState) return -100;
    try {
        g_appState->playback.bpm = juce::jlimit(20.0, 200.0, bpm);
        g_appState->notifyPlaybackStateChanged();
        return 0;
    } catch (...) {
        return -9;
    }
}

double earx_get_bpm() {
    if (!g_initialized || !g_appState) return 30.0;
    try {
        return g_appState->playback.bpm;
    } catch (...) {
        return 30.0;
    }
}

int earx_set_note_duration(float duration) {
    if (!g_initialized || !g_appState) return -100;
    try {
        g_appState->playback.noteDuration = juce::jlimit(0.0f, 100.0f, duration);
        g_appState->notifyPlaybackStateChanged();
        return 0;
    } catch (...) {
        return -10;
    }
}

float earx_get_note_duration() {
    if (!g_initialized || !g_appState) return 100.0f;
    try {
        return g_appState->playback.noteDuration;
    } catch (...) {
        return 100.0f;
    }
}

int earx_set_semitone_active(int semitone, int isActive) {
    if (!g_initialized || !g_appState) return -100;
    if (semitone < 0 || semitone > 11) return -101; // 无效半音
    
    try {
        g_appState->interaction.customSemitones.set(semitone, isActive != 0);
        g_appState->notifyInteractionStateChanged();
        return 0;
    } catch (...) {
        return -11;
    }
}

int earx_get_semitone_active(int semitone) {
    if (!g_initialized || !g_appState) return 0;
    if (semitone < 0 || semitone > 11) return 0;
    
    try {
        if (semitone < g_appState->interaction.customSemitones.size())
            return g_appState->interaction.customSemitones[semitone] ? 1 : 0;
        return 0;
    } catch (...) {
        return 0;
    }
}

int earx_clear_all_semitones() {
    if (!g_initialized || !g_appState) return -100;
    try {
        for (int i = 0; i < 12; ++i)
            g_appState->interaction.customSemitones.set(i, false);
        g_appState->notifyInteractionStateChanged();
        return 0;
    } catch (...) {
        return -12;
    }
}

int earx_play_random_note() {
    if (!g_initialized || !g_playbackEngine) return -100;
    try {
        g_playbackEngine->playNextNote();
        return 0;
    } catch (...) {
        return -13;
    }
}

int earx_get_last_played_note() {
    if (!g_initialized || !g_appState) return -1;
    try {
        return g_appState->playback.lastMidiNote;
    } catch (...) {
        return -1;
    }
}

int earx_get_current_playing_semitone() {
    if (!g_initialized || !g_appState) return -1;
    try {
        return g_appState->interaction.currentPlayingButtonIndex;
    } catch (...) {
        return -1;
    }
}

int earx_start_auto_play() {
    if (!g_initialized || !g_appState) return -100;
    try {
        g_appState->playback.autoPlayEnabled = true;
        g_appState->playback.lastAutoPlayTime = juce::Time::getMillisecondCounterHiRes();
        g_appState->notifyPlaybackStateChanged();
        return 0;
    } catch (...) {
        return -14;
    }
}

int earx_stop_auto_play() {
    if (!g_initialized || !g_appState) return -100;
    try {
        g_appState->playback.autoPlayEnabled = false;
        g_appState->notifyPlaybackStateChanged();
        return 0;
    } catch (...) {
        return -15;
    }
}

int earx_is_auto_playing() {
    if (!g_initialized || !g_appState) return 0;
    try {
        return g_appState->playback.autoPlayEnabled ? 1 : 0;
    } catch (...) {
        return 0;
    }
}

int earx_set_center_tone(int semitone) {
    if (!g_initialized || !g_appState) return -100;
    if (semitone < -1 || semitone > 11) return -101; // 无效半音
    
    try {
        g_appState->interaction.longPressedButtonIndex = semitone;
        // 修复：设置中心音时应该启用播放，而不是禁用
        if (semitone != -1) {
            g_appState->interaction.shouldPlayCenterNote = true; // 设置中心音时启用播放
        } else {
            g_appState->interaction.shouldPlayCenterNote = false; // 取消中心音时禁用播放
        }
        g_appState->notifyInteractionStateChanged();
        return 0;
    } catch (...) {
        return -16;
    }
}

int earx_get_center_tone() {
    if (!g_initialized || !g_appState) return -1;
    try {
        return g_appState->interaction.longPressedButtonIndex;
    } catch (...) {
        return -1;
    }
}

int earx_should_play_center_note() {
    if (!g_initialized || !g_appState) return 0;
    try {
        return g_appState->interaction.shouldPlayCenterNote ? 1 : 0;
    } catch (...) {
        return 0;
    }
}

int earx_set_should_play_center_note(int should_play) {
    if (!g_initialized || !g_appState) return -100;
    try {
        g_appState->interaction.shouldPlayCenterNote = should_play != 0;
        g_appState->notifyInteractionStateChanged();
        return 0;
    } catch (...) {
        return -17;
    }
}

int earx_is_initialized() {
    return g_initialized ? 1 : 0;
}

int earx_are_piano_samples_loaded() {
    if (!g_initialized || !g_audioController) {
        return 0;
    }
    
    return g_audioController->arePianoSamplesLoaded() ? 1 : 0;
}

// 删除所有scale mode相关的FFI函数实现

// 定时器控制
int earx_set_timer_enabled(int enabled) {
    DBG("earx_set_timer_enabled called with enabled=" + juce::String(enabled));
    if (!g_initialized || !g_appState) {
        DBG("earx_set_timer_enabled: not initialized or no appState");
        return -100;
    }
    
    try {
        bool wasEnabled = g_appState->system.timerEnabled;
        g_appState->system.timerEnabled = enabled != 0;
        
        DBG("Timer enabled state changed from " + juce::String(wasEnabled ? 1 : 0) + " to " + juce::String(g_appState->system.timerEnabled ? 1 : 0));
        
        if (!wasEnabled && enabled) {
            // 启动定时器，记录开始时间
            g_appState->system.timerStartTime = juce::Time::getMillisecondCounterHiRes();
            DBG("Timer started at time: " + juce::String(g_appState->system.timerStartTime));
        }
        
        g_appState->notifySystemStateChanged();
        DBG("earx_set_timer_enabled: success, returning 0");
        return 0;
    } catch (...) {
        DBG("earx_set_timer_enabled: exception caught, returning -20");
        return -20;
    }
}

int earx_get_timer_enabled() {
    if (!g_initialized || !g_appState) return 0;
    try {
        return g_appState->system.timerEnabled ? 1 : 0;
    } catch (...) {
        return 0;
    }
}

int earx_set_timer_duration(int minutes) {
    if (!g_initialized || !g_appState) return -100;
    if (minutes <= 0) return -101; // 无效时长
    
    try {
        g_appState->system.timerDurationMinutes = minutes;
        g_appState->notifySystemStateChanged();
        return 0;
    } catch (...) {
        return -21;
    }
}

int earx_get_timer_duration() {
    if (!g_initialized || !g_appState) return 25;
    try {
        return g_appState->system.timerDurationMinutes;
    } catch (...) {
        return 25;
    }
}

int earx_get_timer_remaining() {
    if (!g_initialized || !g_appState) return 0;
    if (!g_appState->system.timerEnabled) return 0;
    
    try {
        double currentTime = juce::Time::getMillisecondCounterHiRes();
        double elapsedMs = currentTime - g_appState->system.timerStartTime;
        double totalMs = g_appState->system.timerDurationMinutes * 60.0 * 1000.0;
        double remainingMs = totalMs - elapsedMs;
        
        return juce::jmax(0, (int)(remainingMs / 1000.0)); // 返回剩余秒数
    } catch (...) {
        return 0;
    }
}

// 音名选择控制函数
int earx_get_note_names_for_semitone(int semitone, char** names, int maxNames) {
    if (!g_initialized || !g_appState || !names || maxNames <= 0) return -100;
    if (semitone < 0 || semitone >= 12) return -101;
    
    try {
        juce::StringArray noteNames = g_appState->interaction.getNoteNamesForSemitone(semitone);
        int count = juce::jmin(noteNames.size(), maxNames);
        
        for (int i = 0; i < count; ++i) {
            // 注意：调用者需要负责释放这些字符串内存
            juce::String name = noteNames[i];
            names[i] = new char[name.length() + 1];
            strcpy(names[i], name.toUTF8());
        }
        
        return count;
    } catch (...) {
        return -22;
    }
}

int earx_set_semitone_note_name(int semitone, int noteNameIndex, int selected) {
    if (!g_initialized || !g_appState) return -100;
    if (semitone < 0 || semitone >= 12) return -101;
    if (noteNameIndex < 0) return -102;
    
    try {
        g_appState->setSemitoneNoteName(semitone, noteNameIndex, selected != 0);
        return 0;
    } catch (...) {
        return -23;
    }
}

int earx_get_semitone_note_name(int semitone, int noteNameIndex) {
    if (!g_initialized || !g_appState) return 0;
    if (semitone < 0 || semitone >= 12) return 0;
    if (noteNameIndex < 0) return 0;
    
    try {
        return g_appState->isSemitoneNoteNameSelected(semitone, noteNameIndex) ? 1 : 0;
    } catch (...) {
        return 0;
    }
}

int earx_get_selected_note_names_display(int semitone, char* buffer, int bufferSize) {
    if (!g_initialized || !g_appState || !buffer || bufferSize <= 0) return -100;
    if (semitone < 0 || semitone >= 12) return -101;
    
    try {
        juce::String displayText = g_appState->getSelectedNoteNamesDisplayForSemitone(semitone);
        
        if (displayText.length() >= bufferSize) {
            return -103; // 缓冲区太小
        }
        
        strcpy(buffer, displayText.toUTF8());
        return 0;
    } catch (...) {
        return -24;
    }
}


} // extern "C"

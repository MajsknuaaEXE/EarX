#pragma once

// 强制符号导出
#if defined(__GNUC__) || defined(__clang__)
    #define EARX_EXPORT __attribute__((visibility("default")))
#elif defined(_MSC_VER)
    #define EARX_EXPORT __declspec(dllexport)
#else
    #define EARX_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// FFI接口 - 提供C风格API供Flutter调用
// 所有函数返回值: 0=成功, 负数=错误码

// 音频引擎生命周期
EARX_EXPORT int earx_initialize(double sampleRate);
EARX_EXPORT int earx_destroy();

// 音符播放控制
EARX_EXPORT int earx_play_note(int midiNote, float velocity);
EARX_EXPORT int earx_stop_note(int midiNote);
EARX_EXPORT int earx_stop_all_notes();

// 音色控制
EARX_EXPORT int earx_set_piano_mode(int isPianoMode); // 0=正弦波, 1=钢琴
EARX_EXPORT int earx_get_current_timbre(); // 返回当前音色: 0=正弦波, 1=钢琴

// 音量控制
EARX_EXPORT int earx_set_master_volume(float volume); // 0.0-1.0
EARX_EXPORT float earx_get_master_volume();

// 播放引擎控制
EARX_EXPORT int earx_set_bpm(double bpm);
EARX_EXPORT double earx_get_bpm();
EARX_EXPORT int earx_set_note_duration(float duration); // 百分比 0-100
EARX_EXPORT float earx_get_note_duration();

// 半音选择状态管理
EARX_EXPORT int earx_set_semitone_active(int semitone, int isActive); // semitone: 0-11
EARX_EXPORT int earx_get_semitone_active(int semitone); // 返回 0 或 1
EARX_EXPORT int earx_clear_all_semitones();

// 播放控制
EARX_EXPORT int earx_play_random_note(); // 从活动半音中随机播放一个
EARX_EXPORT int earx_get_last_played_note(); // 获取最后播放的MIDI音符
EARX_EXPORT int earx_get_current_playing_semitone(); // 获取当前播放的半音 (0-11, -1表示无音符在播放)

// 自动播放控制
EARX_EXPORT int earx_start_auto_play(); // 开始按BPM自动播放
EARX_EXPORT int earx_stop_auto_play(); // 停止自动播放
EARX_EXPORT int earx_is_auto_playing(); // 返回自动播放状态: 0=关闭, 1=开启

// 中心音控制 (长按逻辑移至Flutter)
EARX_EXPORT int earx_set_center_tone(int semitone); // 设置中心音 (0-11, -1表示无中心音)
EARX_EXPORT int earx_get_center_tone(); // 获取当前中心音 (-1表示无中心音)
EARX_EXPORT int earx_should_play_center_note(); // 返回是否应该播放中心音 (0或1)
EARX_EXPORT int earx_set_should_play_center_note(int should_play); // 设置是否播放中心音

// 删除所有scale mode相关的FFI函数

// 定时器控制
EARX_EXPORT int earx_set_timer_enabled(int enabled); // 0=关闭, 1=开启
EARX_EXPORT int earx_get_timer_enabled(); // 返回定时器状态
EARX_EXPORT int earx_set_timer_duration(int minutes); // 设置定时时长（分钟）
EARX_EXPORT int earx_get_timer_duration(); // 获取定时时长
EARX_EXPORT int earx_get_timer_remaining(); // 获取剩余时间（秒）

// 音名选择控制 (Custom Mode)
EARX_EXPORT int earx_get_note_names_for_semitone(int semitone, char** names, int maxNames); // 获取音级的所有音名选项
EARX_EXPORT int earx_set_semitone_note_name(int semitone, int noteNameIndex, int selected); // 设置音名选择状态
EARX_EXPORT int earx_get_semitone_note_name(int semitone, int noteNameIndex); // 获取音名选择状态
EARX_EXPORT int earx_get_selected_note_names_display(int semitone, char* buffer, int bufferSize); // 获取选择的音名显示文本

// 状态查询
EARX_EXPORT int earx_is_initialized();
EARX_EXPORT int earx_are_piano_samples_loaded(); // 检查钢琴采样是否加载完成

#ifdef __cplusplus
}
#endif
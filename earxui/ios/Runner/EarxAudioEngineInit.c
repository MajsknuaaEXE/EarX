//
//  EarxAudioEngineInit.c
//  Runner
//
//  Force linking of EarxAudioEngine static library symbols
//

// 引用EarxAudioEngine中的关键符号以强制链接
extern int earx_initialize(double sampleRate);
extern int earx_destroy(void);
extern int earx_play_note(int midiNote, float velocity);
extern int earx_stop_note(int midiNote);
extern int    earx_set_piano_mode(int isPianoMode);
extern int    earx_get_current_timbre(void);
extern int    earx_set_master_volume(float volume);
extern float  earx_get_master_volume(void);
extern int    earx_set_bpm(double bpm);
extern double earx_get_bpm(void);
extern int    earx_set_note_duration(float duration);
extern float  earx_get_note_duration(void);
extern int    earx_set_semitone_active(int semitone, int isActive);
extern int    earx_get_semitone_active(int semitone);
extern int    earx_clear_all_semitones(void);
extern int    earx_play_random_note(void);
extern int    earx_stop_all_notes(void);
extern int    earx_get_last_played_note(void);
extern int    earx_get_current_playing_semitone(void);
// 新增的中心音控制函数
extern int earx_set_center_tone(int semitone);
extern int earx_get_center_tone(void);
extern int earx_should_play_center_note(void);
extern int earx_set_should_play_center_note(int shouldPlay);
// 设置功能函数
extern int earx_set_timer_enabled(int enabled);
extern int earx_get_timer_enabled(void);
extern int earx_set_timer_duration(int minutes);
extern int earx_get_timer_duration(void);
extern int earx_get_timer_remaining(void);
extern int earx_is_initialized(void);
extern int earx_start_auto_play(void);
extern int earx_stop_auto_play(void);
extern int earx_is_auto_playing(void);
extern int earx_set_semitone_note_name(int semitone, int noteNameIndex, int selected);
extern int earx_get_semitone_note_name(int semitone, int noteNameIndex);
extern int earx_get_note_names_for_semitone(int semitone, char** names, int maxNames);
extern int earx_get_selected_note_names_display(int semitone, char* buffer, int bufferSize);

// 强制链接函数 - 确保静态库符号不被优化掉
void __attribute__((constructor)) force_link_earx_audio_engine(void) {
    // 这些函数指针引用会强制链接器包含符号
    // 但由于是constructor，这些代码不会实际执行
    static void* funcs[] __attribute__((used)) = {
        (void*)earx_initialize,
        (void*)earx_destroy,
        (void*)earx_play_note,
        (void*)earx_stop_note,
        (void*)earx_stop_all_notes,
        (void*)earx_set_piano_mode,
        (void*)earx_get_current_timbre,
        (void*)earx_set_master_volume,
        (void*)earx_get_master_volume,
        (void*)earx_set_bpm,
        (void*)earx_get_bpm,
        (void*)earx_set_note_duration,
        (void*)earx_get_note_duration,
        (void*)earx_set_semitone_active,
        (void*)earx_get_semitone_active,
        (void*)earx_clear_all_semitones,
        (void*)earx_play_random_note,
        (void*)earx_get_last_played_note,
        (void*)earx_get_current_playing_semitone,
        // 中心音控制函数
        (void*)earx_set_center_tone,
        (void*)earx_get_center_tone,
        (void*)earx_should_play_center_note,
        (void*)earx_set_should_play_center_note,
        // 自动播放
        (void*)earx_start_auto_play,
        (void*)earx_stop_auto_play,
        (void*)earx_is_auto_playing,
        // 设置功能函数
        (void*)earx_set_timer_enabled,
        (void*)earx_get_timer_enabled,
        (void*)earx_set_timer_duration,
        (void*)earx_get_timer_duration,
        (void*)earx_get_timer_remaining,
        (void*)earx_is_initialized,
        // 音名选择控制
        (void*)earx_set_semitone_note_name,
        (void*)earx_get_semitone_note_name,
        (void*)earx_get_note_names_for_semitone,
        (void*)earx_get_selected_note_names_display,
    };
    (void)funcs; // 避免未使用变量警告
}

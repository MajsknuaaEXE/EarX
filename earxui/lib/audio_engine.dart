import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';

// 获取动态库路径
DynamicLibrary _loadLibrary() {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('libEarxAudioEngine.so');
  } else if (Platform.isIOS) {
    // iOS上静态库会被链接到主程序中
    return DynamicLibrary.executable();
  } else {
    throw UnsupportedError('平台不支持: ${Platform.operatingSystem}');
  }
}

final DynamicLibrary _dylib = _loadLibrary();

// FFI函数签名定义
typedef _InitializeC = Int32 Function(Double sampleRate);
typedef _InitializeDart = int Function(double sampleRate);

typedef _DestroyC = Int32 Function();
typedef _DestroyDart = int Function();

typedef _PlayNoteC = Int32 Function(Int32 midiNote, Float velocity);
typedef _PlayNoteDart = int Function(int midiNote, double velocity);

typedef _StopNoteC = Int32 Function(Int32 midiNote);
typedef _StopNoteDart = int Function(int midiNote);

typedef _StopAllNotesC = Int32 Function();
typedef _StopAllNotesDart = int Function();

typedef _SetPianoModeC = Int32 Function(Int32 isPianoMode);
typedef _SetPianoModeDart = int Function(int isPianoMode);

typedef _GetCurrentTimbreC = Int32 Function();
typedef _GetCurrentTimbreDart = int Function();

typedef _SetMasterVolumeC = Int32 Function(Float volume);
typedef _SetMasterVolumeDart = int Function(double volume);

typedef _GetMasterVolumeC = Float Function();
typedef _GetMasterVolumeDart = double Function();

typedef _SetBpmC = Int32 Function(Double bpm);
typedef _SetBpmDart = int Function(double bpm);

typedef _GetBpmC = Double Function();
typedef _GetBpmDart = double Function();

typedef _SetNoteDurationC = Int32 Function(Float duration);
typedef _SetNoteDurationDart = int Function(double duration);

typedef _GetNoteDurationC = Float Function();
typedef _GetNoteDurationDart = double Function();

typedef _SetSemitoneActiveC = Int32 Function(Int32 semitone, Int32 isActive);
typedef _SetSemitoneActiveDart = int Function(int semitone, int isActive);

typedef _GetSemitoneActiveC = Int32 Function(Int32 semitone);
typedef _GetSemitoneActiveDart = int Function(int semitone);

typedef _ClearAllSemitonesC = Int32 Function();
typedef _ClearAllSemitonesDart = int Function();

typedef _PlayRandomNoteC = Int32 Function();
typedef _PlayRandomNoteDart = int Function();

typedef _GetLastPlayedNoteC = Int32 Function();
typedef _GetLastPlayedNoteDart = int Function();

typedef _GetCurrentPlayingSemitoneC = Int32 Function();
typedef _GetCurrentPlayingSemitoneDart = int Function();

typedef _IsInitializedC = Int32 Function();
typedef _IsInitializedDart = int Function();

typedef _ArePianoSamplesLoadedC = Int32 Function();
typedef _ArePianoSamplesLoadedDart = int Function();

// 自动播放控制函数类型定义
typedef _StartAutoPlayC = Int32 Function();
typedef _StartAutoPlayDart = int Function();

typedef _StopAutoPlayC = Int32 Function();
typedef _StopAutoPlayDart = int Function();

typedef _IsAutoPlayingC = Int32 Function();
typedef _IsAutoPlayingDart = int Function();

// 中心音控制函数类型定义
typedef _SetCenterToneC = Int32 Function(Int32 semitone);
typedef _SetCenterToneDart = int Function(int semitone);

typedef _GetCenterToneC = Int32 Function();
typedef _GetCenterToneDart = int Function();

typedef _ShouldPlayCenterNoteC = Int32 Function();
typedef _ShouldPlayCenterNoteDart = int Function();

typedef _SetShouldPlayCenterNoteC = Int32 Function(Int32 shouldPlay);
typedef _SetShouldPlayCenterNoteDart = int Function(int shouldPlay);


// 定时器控制
typedef _SetTimerEnabledC = Int32 Function(Int32 enabled);
typedef _SetTimerEnabledDart = int Function(int enabled);
typedef _GetTimerEnabledC = Int32 Function();
typedef _GetTimerEnabledDart = int Function();
typedef _SetTimerDurationC = Int32 Function(Int32 minutes);
typedef _SetTimerDurationDart = int Function(int minutes);
typedef _GetTimerDurationC = Int32 Function();
typedef _GetTimerDurationDart = int Function();
typedef _GetTimerRemainingC = Int32 Function();
typedef _GetTimerRemainingDart = int Function();

// 音名选择控制
typedef _SetSemitoneNoteNameC = Int32 Function(Int32 semitone, Int32 noteNameIndex, Int32 selected);
typedef _SetSemitoneNoteNameDart = int Function(int semitone, int noteNameIndex, int selected);
typedef _GetSemitoneNoteNameC = Int32 Function(Int32 semitone, Int32 noteNameIndex);
typedef _GetSemitoneNoteNameDart = int Function(int semitone, int noteNameIndex);


/// EarX音频引擎的Dart FFI封装
/// 提供对JUCE音频引擎的高级接口
class AudioEngine {
  // UI notifier: reflects current timbre (true=piano, false=sine)
  static final ValueNotifier<bool> timbreIsPianoNotifier = ValueNotifier<bool>(false);
  // FFI函数绑定
  static final _initialize = _dylib.lookupFunction<_InitializeC, _InitializeDart>('earx_initialize');
  static final _destroy = _dylib.lookupFunction<_DestroyC, _DestroyDart>('earx_destroy');
  static final _playNote = _dylib.lookupFunction<_PlayNoteC, _PlayNoteDart>('earx_play_note');
  static final _stopNote = _dylib.lookupFunction<_StopNoteC, _StopNoteDart>('earx_stop_note');
  static final _stopAllNotes = _dylib.lookupFunction<_StopAllNotesC, _StopAllNotesDart>('earx_stop_all_notes');
  static final _setPianoMode = _dylib.lookupFunction<_SetPianoModeC, _SetPianoModeDart>('earx_set_piano_mode');
  static final _getCurrentTimbre = _dylib.lookupFunction<_GetCurrentTimbreC, _GetCurrentTimbreDart>('earx_get_current_timbre');
  static final _setMasterVolume = _dylib.lookupFunction<_SetMasterVolumeC, _SetMasterVolumeDart>('earx_set_master_volume');
  static final _getMasterVolume = _dylib.lookupFunction<_GetMasterVolumeC, _GetMasterVolumeDart>('earx_get_master_volume');
  static final _setBpm = _dylib.lookupFunction<_SetBpmC, _SetBpmDart>('earx_set_bpm');
  static final _getBpm = _dylib.lookupFunction<_GetBpmC, _GetBpmDart>('earx_get_bpm');
  static final _setNoteDuration = _dylib.lookupFunction<_SetNoteDurationC, _SetNoteDurationDart>('earx_set_note_duration');
  static final _getNoteDuration = _dylib.lookupFunction<_GetNoteDurationC, _GetNoteDurationDart>('earx_get_note_duration');
  static final _setSemitoneActive = _dylib.lookupFunction<_SetSemitoneActiveC, _SetSemitoneActiveDart>('earx_set_semitone_active');
  static final _getSemitoneActive = _dylib.lookupFunction<_GetSemitoneActiveC, _GetSemitoneActiveDart>('earx_get_semitone_active');
  static final _clearAllSemitones = _dylib.lookupFunction<_ClearAllSemitonesC, _ClearAllSemitonesDart>('earx_clear_all_semitones');
  static final _playRandomNote = _dylib.lookupFunction<_PlayRandomNoteC, _PlayRandomNoteDart>('earx_play_random_note');
  static final _getLastPlayedNote = _dylib.lookupFunction<_GetLastPlayedNoteC, _GetLastPlayedNoteDart>('earx_get_last_played_note');
  static final _getCurrentPlayingSemitone = _dylib.lookupFunction<_GetCurrentPlayingSemitoneC, _GetCurrentPlayingSemitoneDart>('earx_get_current_playing_semitone');
  static final _isInitialized = _dylib.lookupFunction<_IsInitializedC, _IsInitializedDart>('earx_is_initialized');
  static final _arePianoSamplesLoaded = _dylib.lookupFunction<_ArePianoSamplesLoadedC, _ArePianoSamplesLoadedDart>('earx_are_piano_samples_loaded');
  
  // 自动播放控制函数绑定
  static final _startAutoPlay = _dylib.lookupFunction<_StartAutoPlayC, _StartAutoPlayDart>('earx_start_auto_play');
  static final _stopAutoPlay = _dylib.lookupFunction<_StopAutoPlayC, _StopAutoPlayDart>('earx_stop_auto_play');
  static final _isAutoPlaying = _dylib.lookupFunction<_IsAutoPlayingC, _IsAutoPlayingDart>('earx_is_auto_playing');

  // 中心音控制函数绑定
  static final _setCenterTone = _dylib.lookupFunction<_SetCenterToneC, _SetCenterToneDart>('earx_set_center_tone');
  static final _getCenterTone = _dylib.lookupFunction<_GetCenterToneC, _GetCenterToneDart>('earx_get_center_tone');
  static final _shouldPlayCenterNote = _dylib.lookupFunction<_ShouldPlayCenterNoteC, _ShouldPlayCenterNoteDart>('earx_should_play_center_note');
  static final _setShouldPlayCenterNote = _dylib.lookupFunction<_SetShouldPlayCenterNoteC, _SetShouldPlayCenterNoteDart>('earx_set_should_play_center_note');
  
  static final _setTimerEnabled = _dylib.lookupFunction<_SetTimerEnabledC, _SetTimerEnabledDart>('earx_set_timer_enabled');
  static final _getTimerEnabled = _dylib.lookupFunction<_GetTimerEnabledC, _GetTimerEnabledDart>('earx_get_timer_enabled');
  static final _setTimerDuration = _dylib.lookupFunction<_SetTimerDurationC, _SetTimerDurationDart>('earx_set_timer_duration');
  static final _getTimerDuration = _dylib.lookupFunction<_GetTimerDurationC, _GetTimerDurationDart>('earx_get_timer_duration');
  static final _getTimerRemaining = _dylib.lookupFunction<_GetTimerRemainingC, _GetTimerRemainingDart>('earx_get_timer_remaining');
  
  // 音名选择控制函数绑定
  static final _setSemitoneNoteName = _dylib.lookupFunction<_SetSemitoneNoteNameC, _SetSemitoneNoteNameDart>('earx_set_semitone_note_name');
  static final _getSemitoneNoteName = _dylib.lookupFunction<_GetSemitoneNoteNameC, _GetSemitoneNoteNameDart>('earx_get_semitone_note_name');

  static bool _initialized = false;
  static bool _ffiAvailable = true; // FFI是否可用
  static int lastInitResult = -9999; // 最近一次初始化返回码（0成功，其它为错误）

  /// 初始化音频引擎
  /// [sampleRate] 采样率，通常为44100.0
  /// 返回是否成功初始化
  static Future<bool> initialize({double sampleRate = 44100.0}) async {
    if (_initialized) return true;
    if (!_ffiAvailable) return false;
    
    try {
      final result = _initialize(sampleRate);
      lastInitResult = result;
      _initialized = (result == 0);
      return _initialized;
    } catch (e) {
      debugPrint('FFI调用失败，禁用音频功能: $e');
      _ffiAvailable = false;
      _initialized = false;
      return false;
    }
  }

  /// 销毁音频引擎，释放所有资源
  static Future<void> destroy() async {
    if (!_initialized) return;
    
    _destroy();
    _initialized = false;
  }

  /// 检查音频引擎是否已初始化
  static bool get isInitialized {
    if (!_ffiAvailable || !_initialized) return false;
    try {
      return _isInitialized() == 1;
    } catch (e) {
      debugPrint('FFI检查失败，禁用音频功能: $e');
      _ffiAvailable = false;
      return false;
    }
  }

  /// 检查钢琴采样是否已加载完成
  static bool get arePianoSamplesLoaded {
    if (!_ffiAvailable || !_initialized) return false;
    try {
      return _arePianoSamplesLoaded() == 1;
    } catch (e) {
      debugPrint('FFI检查钢琴采样状态失败: $e');
      return false;
    }
  }

  /// 播放指定MIDI音符
  /// [midiNote] MIDI音符号(0-127)
  /// [velocity] 力度(0.0-1.0)
  static Future<bool> playNote(int midiNote, {double velocity = 0.7}) async {
    if (!isInitialized) return false;
    
    final result = _playNote(midiNote, velocity);
    return result == 0;
  }

  /// 停止指定MIDI音符
  /// [midiNote] MIDI音符号(0-127)
  static Future<bool> stopNote(int midiNote) async {
    if (!isInitialized) return false;
    
    final result = _stopNote(midiNote);
    return result == 0;
  }

  /// 停止所有正在播放的音符
  static Future<bool> stopAllNotes() async {
    if (!isInitialized) return false;
    
    final result = _stopAllNotes();
    return result == 0;
  }

  /// 设置音色模式
  /// [isPianoMode] true=钢琴音色, false=正弦波音色
  static Future<bool> setPianoMode(bool isPianoMode) async {
    if (!isInitialized) return false;
    
    final result = _setPianoMode(isPianoMode ? 1 : 0);
    final ok = result == 0;
    if (ok) {
      timbreIsPianoNotifier.value = isPianoMode;
    }
    return ok;
  }

  /// 获取当前音色
  /// 返回 true=钢琴音色, false=正弦波音色
  static bool get isPianoMode {
    if (!isInitialized) return false;
    return _getCurrentTimbre() == 1;
  }

  /// 设置主音量
  /// [volume] 音量(0.0-1.0)
  static Future<bool> setMasterVolume(double volume) async {
    if (!isInitialized) return false;
    
    final result = _setMasterVolume(volume.clamp(0.0, 1.0));
    return result == 0;
  }

  /// 获取当前主音量
  static double get masterVolume {
    if (!isInitialized) return 0.0;
    return _getMasterVolume();
  }

  /// 设置BPM
  /// [bpm] 每分钟节拍数(20-200)
  static Future<bool> setBpm(double bpm) async {
    if (!isInitialized) return false;
    
    final result = _setBpm(bpm.clamp(20.0, 200.0));
    return result == 0;
  }

  /// 获取当前BPM
  static double get bpm {
    if (!_ffiAvailable || !_initialized) return 30.0;
    try {
      return _getBpm();
    } catch (e) {
      debugPrint('获取BPM失败: $e');
      return 30.0;
    }
  }

  /// 设置音符持续时间
  /// [duration] 持续时间百分比(10.0-200.0)
  static Future<bool> setNoteDuration(double duration) async {
    if (!isInitialized) return false;
    
    final result = _setNoteDuration(duration.clamp(10.0, 200.0));
    return result == 0;
  }

  /// 获取当前音符持续时间百分比
  static double get noteDuration {
    if (!isInitialized) return 100.0;
    return _getNoteDuration();
  }

  /// 设置半音是否激活
  /// [semitone] 半音索引(0-11, 0=C, 1=C#, 2=D, ...)
  /// [isActive] 是否激活
  static Future<bool> setSemitoneActive(int semitone, bool isActive) async {
    if (!isInitialized) return false;
    if (semitone < 0 || semitone > 11) return false;
    
    final result = _setSemitoneActive(semitone, isActive ? 1 : 0);
    return result == 0;
  }

  /// 检查半音是否激活
  /// [semitone] 半音索引(0-11)
  static bool isSemitoneActive(int semitone) {
    if (!isInitialized || semitone < 0 || semitone > 11) return false;
    return _getSemitoneActive(semitone) == 1;
  }

  /// 清除所有激活的半音
  static Future<bool> clearAllSemitones() async {
    if (!isInitialized) return false;
    
    final result = _clearAllSemitones();
    return result == 0;
  }

  /// 从激活的半音中随机播放一个音符
  static Future<bool> playRandomNote() async {
    if (!isInitialized) return false;
    
    final result = _playRandomNote();
    return result == 0;
  }

  /// 开始自动播放 (按BPM自动播放)
  static Future<bool> startAutoPlay() async {
    if (!isInitialized) return false;
    
    final result = _startAutoPlay();
    return result == 0;
  }

  /// 停止自动播放
  static Future<bool> stopAutoPlay() async {
    if (!isInitialized) return false;
    
    final result = _stopAutoPlay();
    return result == 0;
  }

  /// 获取自动播放状态
  static bool get isAutoPlaying {
    if (!_ffiAvailable || !_initialized) return false;
    try {
      return _isAutoPlaying() == 1;
    } catch (e) {
      debugPrint('获取自动播放状态失败: $e');
      return false;
    }
  }

  /// 获取最后播放的MIDI音符
  /// 返回-1表示没有播放过音符
  static int get lastPlayedNote {
    if (!isInitialized) return -1;
    return _getLastPlayedNote();
  }

  /// 获取当前正在播放的半音索引
  /// 返回-1表示没有音符在播放，返回0-11表示当前播放的半音
  static int get currentPlayingSemitone {
    if (!_ffiAvailable || !_initialized) return -1;
    try {
      return _getCurrentPlayingSemitone();
    } catch (e) {
      debugPrint('获取当前播放半音失败: $e');
      return -1;
    }
  }

  /// 将半音索引转换为MIDI音符(以C4=60为基准)
  /// [semitone] 半音索引(0-11)
  /// [octave] 八度(默认为4)
  static int semitoneToMidi(int semitone, {int octave = 4}) {
    return (octave + 1) * 12 + semitone;
  }

  /// 将MIDI音符转换为半音索引
  /// [midiNote] MIDI音符号
  static int midiToSemitone(int midiNote) {
    return midiNote % 12;
  }

  /// 获取半音名称
  /// [semitone] 半音索引(0-11)
  static String getSemitoneName(int semitone) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    if (semitone < 0 || semitone >= names.length) return '';
    return names[semitone];
  }

  // ======== 中心音控制函数 ========
  
  /// 设置中心音（长按功能）
  /// [semitone] 半音索引(0-11)，-1 表示取消中心音
  static Future<bool> setCenterTone(int semitone) async {
    if (!isInitialized) return false;
    if (semitone < -1 || semitone > 11) return false;
    
    final result = _setCenterTone(semitone);
    return result == 0;
  }

  /// 获取当前中心音
  /// 返回半音索引(0-11)，-1 表示没有设置中心音
  static int get centerTone {
    if (!isInitialized) return -1;
    return _getCenterTone();
  }

  /// 检查是否应该播放中心音
  static bool get shouldPlayCenterNote {
    if (!isInitialized) return false;
    return _shouldPlayCenterNote() == 1;
  }

  /// 设置是否播放中心音标志
  /// [shouldPlay] 是否应该播放中心音
  static Future<bool> setShouldPlayCenterNote(bool shouldPlay) async {
    if (!isInitialized) return false;
    
    final result = _setShouldPlayCenterNote(shouldPlay ? 1 : 0);
    return result == 0;
  }

  // ======== 设置功能 ========

  /// 设置定时器开关
  /// [enabled] 是否启用定时器
  static Future<bool> setTimerEnabled(bool enabled) async {
    if (!isInitialized) return false;
    
    final result = _setTimerEnabled(enabled ? 1 : 0);
    return result == 0;
  }

  /// 获取定时器开关状态
  static bool get timerEnabled {
    if (!isInitialized) return false;
    return _getTimerEnabled() == 1;
  }

  /// 设置定时器时长
  /// [minutes] 定时时长（分钟）
  static Future<bool> setTimerDuration(int minutes) async {
    if (!isInitialized) return false;
    if (minutes <= 0) return false;
    
    final result = _setTimerDuration(minutes);
    return result == 0;
  }

  /// 获取定时器时长
  /// 返回时长（分钟）
  static int get timerDuration {
    if (!isInitialized) return 25;
    return _getTimerDuration();
  }

  /// 获取定时器剩余时间
  /// 返回剩余时间（秒）
  static int get timerRemaining {
    if (!isInitialized) return 0;
    return _getTimerRemaining();
  }


  /// 获取指定音级的所有可选音名
  /// [semitone] 音级索引(0-11)
  /// 返回该音级的所有可选音名列表
  static List<String> getNoteNamesForSemitone(int semitone) {
    if (!isInitialized || semitone < 0 || semitone >= 12) return [];
    
    // 音名选项，按照要求的顺序：C，#C，D，bE，E，F，#F，G，bA，A，bB，B
    const List<List<String>> semitoneOptions = [
      ['C', 'B♯'],           // 0: C
      ['C♯', 'D♭'],          // 1: #C  
      ['D', 'D♮'],           // 2: D
      ['E♭', 'D♯'],          // 3: bE
      ['E', 'E♮'],           // 4: E
      ['F', 'E♯'],           // 5: F
      ['F♯', 'G♭'],          // 6: #F
      ['G', 'G♮', 'F𝄪'],      // 7: G - 添加F重升
      ['A♭', 'G♯'],          // 8: bA
      ['A', 'A♮'],           // 9: A  
      ['B♭', 'A♯'],          // 10: bB
      ['B', 'B♮', 'C♭']       // 11: B - 添加降C
    ];
    
    return semitoneOptions[semitone];
  }

  /// 设置音级的音名选择状态
  /// [semitone] 音级索引(0-11)
  /// [noteNameIndex] 音名索引
  /// [selected] 是否选择
  static Future<bool> setSemitoneNoteName(int semitone, int noteNameIndex, bool selected) async {
    if (!isInitialized || semitone < 0 || semitone >= 12 || noteNameIndex < 0) return false;
    
    final result = _setSemitoneNoteName(semitone, noteNameIndex, selected ? 1 : 0);
    return result == 0;
  }

  /// 获取音级的音名选择状态
  /// [semitone] 音级索引(0-11)
  /// [noteNameIndex] 音名索引
  /// 返回该音名是否被选择
  static bool getSemitoneNoteName(int semitone, int noteNameIndex) {
    if (!isInitialized || semitone < 0 || semitone >= 12 || noteNameIndex < 0) return false;
    
    return _getSemitoneNoteName(semitone, noteNameIndex) == 1;
  }

  /// 获取音级的选择音名显示文本
  /// [semitone] 音级索引(0-11)
  /// 返回选择的音名组合文本（用/分隔）
  static String getSelectedNoteNamesDisplay(int semitone) {
    if (!isInitialized || semitone < 0 || semitone >= 12) return '';
    
    // 按照要求的顺序返回默认音名：C，#C，D，bE，E，F，#F，G，bA，A，bB，B
    const List<String> defaultNames = [
      'C', 'C♯', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B'
    ];
    
    return defaultNames[semitone];
  }

}

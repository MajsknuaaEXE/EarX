import 'package:flutter/foundation.dart';
import 'dart:async';
import 'audio_engine.dart';

class WheelDialController extends ChangeNotifier {
  /// 选中的扇形（中间那盏 LED）
  final ValueNotifier<Set<int>> selected = ValueNotifier(<int>{});

  /// 正在播放的扇形（右侧那盏 LED）
  final ValueNotifier<Set<int>> playing = ValueNotifier(<int>{});

  /// 倒计时进度 [0..1]
  final ValueNotifier<double> countdown = ValueNotifier(0.0);

  /// 中心音（长按选中的扇形），-1表示无中心音
  final ValueNotifier<int> centerTone = ValueNotifier(-1);

  /// 当前播放的音符文本
  final ValueNotifier<String> currentPlayingNote = ValueNotifier('');

  /// 播放状态检查定时器
  Timer? _playingStateTimer;
  
  /// 音符文本清除定时器
  Timer? _noteTextClearTimer;
  
  /// 倒计时定时器
  Timer? _countdownTimer;

  /// Flutter端的音名选择状态 (每个音级的选择的音名索引列表)
  final Map<int, List<bool>> _semitoneNoteSelections = {};

  /// 预定义的音名选项，按照要求的顺序：C，C♯，D，E♭，E，F，F♯，G，A♭，A，B♭，B
  static const List<List<String>> _semitoneOptions = [
    ['C', 'B♯'],           // 0: C
    ['C♯', 'D♭'],          // 1: C♯  
    ['D', 'D♮'],           // 2: D
    ['E♭', 'D♯'],          // 3: E♭
    ['E', 'E♮'],           // 4: E
    ['F', 'E♯'],           // 5: F
    ['F♯', 'G♭'],          // 6: F♯
    ['G', 'G♮', 'F𝄪'],      // 7: G - 添加F重升
    ['A♭', 'G♯'],          // 8: A♭
    ['A', 'A♮'],           // 9: A  
    ['B♭', 'A♯'],          // 10: B♭
    ['B', 'B♮', 'C♭']       // 11: B - 添加降C
  ];


  /// 构造函数 - 初始化音名选择状态
  WheelDialController() {
    _initializeSemitoneSelections();
    _startCountdownTimer();
  }
  

  /// 初始化音名选择状态
  void _initializeSemitoneSelections() {
    for (int semitone = 0; semitone < 12; semitone++) {
      final options = _semitoneOptions[semitone];
      final selections = List<bool>.filled(options.length, false);
      
      // 默认选择第一个选项，这样会显示 C，C♯，D，E♭，E，F，F♯，G，A♭，A，B♭，B
      if (options.isNotEmpty) {
        selections[0] = true; // 选择第一个选项
      }
      
      _semitoneNoteSelections[semitone] = selections;
    }
  }

  /// 设置音级的音名选择状态
  void setSemitoneNoteName(int semitone, int noteNameIndex, bool selected) {
    if (semitone >= 0 && semitone < 12 && 
        _semitoneNoteSelections.containsKey(semitone)) {
      final selections = _semitoneNoteSelections[semitone]!;
      if (noteNameIndex >= 0 && noteNameIndex < selections.length) {
        
        // 检查是否为最后一个选择项
        final currentSelections = selections.where((s) => s).length;
        if (currentSelections == 1 && selections[noteNameIndex] && !selected) {
          // 如果是最后一个选择项，不允许取消
          return;
        }
        
        selections[noteNameIndex] = selected;
        
        // 同步到音频引擎（即使失败也不影响Flutter端的显示）
        AudioEngine.setSemitoneNoteName(semitone, noteNameIndex, selected);
        
        notifyListeners();
      }
    }
  }

  /// 获取音级的音名选择状态
  bool getSemitoneNoteName(int semitone, int noteNameIndex) {
    if (semitone >= 0 && semitone < 12 && 
        _semitoneNoteSelections.containsKey(semitone)) {
      final selections = _semitoneNoteSelections[semitone]!;
      if (noteNameIndex >= 0 && noteNameIndex < selections.length) {
        return selections[noteNameIndex];
      }
    }
    return false;
  }

  /// 获取音级的所有音名选项
  List<String> getNoteNamesForSemitone(int semitone) {
    if (semitone >= 0 && semitone < 12) {
      return _semitoneOptions[semitone];
    }
    return [];
  }

  void toggleSelected(int slice) {
    final s = Set<int>.from(selected.value);
    final wasEmpty = s.isEmpty; // 记录之前是否为空
    final isAdding = s.add(slice);
    
    // 如果这是中心音，不允许关闭普通开关
    if (!isAdding && centerTone.value == slice) {
      // 中心音开启时，该音级必须保持普通开关开启，不做移除操作
      return;
    }
    
    if (!isAdding) s.remove(slice);
    selected.value = s;
    
    // 同步到音频引擎
    _syncSemitonesToAudioEngine();
    
    // 如果之前没有选中任何音级，现在打开了第一个音级，立即播放一次
    if (wasEmpty && isAdding && AudioEngine.isInitialized) {
      // 立即播放第一个音符
      AudioEngine.playRandomNote();
    }
    
    // 根据选中状态控制连续播放
    _updateContinuousPlay();
    
    notifyListeners();
  }


  void setCountdown(double p) {
    countdown.value = p.clamp(0, 1);
    notifyListeners();
  }

  /// 设置中心音（长按功能）
  /// [slice] 扇形索引(1-12)，-1表示取消中心音
  Future<void> setCenterTone(int slice) async {
    if (slice == centerTone.value) return; // 避免重复设置
    
    centerTone.value = slice;
    
    // 同步到音频引擎
    if (slice == -1) {
      await AudioEngine.setCenterTone(-1); // 取消中心音
    } else {
      // 设置中心音时，自动激活该音级的普通开关
      final s = Set<int>.from(selected.value);
      final wasEmpty = s.isEmpty; // 记录之前是否为空
      
      if (!s.contains(slice)) {
        s.add(slice);
        selected.value = s;
        _syncSemitonesToAudioEngine();
        
        // 如果之前没有选中任何音级，现在设置了中心音，立即播放一次
        if (wasEmpty && AudioEngine.isInitialized) {
          // 立即播放第一个音符
          AudioEngine.playRandomNote();
        }
        
        _updateContinuousPlay();
      }
      
      final semitone = _sliceToSemitone(slice);
      await AudioEngine.setCenterTone(semitone);
    }
    
    notifyListeners();
  }

  /// 获取当前中心音扇形索引
  int get currentCenterTone => centerTone.value;

  void clear() {
    selected.value = {};
    playing.value = {};
    countdown.value = 0.0;
    centerTone.value = -1; // 清除中心音
    currentPlayingNote.value = ''; // 清除当前播放音符
    
    // 停止播放状态监控
    _stopPlayingStateMonitor();
    
    // 停止音符文本清除定时器
    _noteTextClearTimer?.cancel();
    _noteTextClearTimer = null;
    
    // 停止C++音频引擎的自动播放
    if (AudioEngine.isAutoPlaying) {
      AudioEngine.stopAutoPlay();
    }
    
    // 停止所有音符并清除音频引擎状态
    AudioEngine.stopAllNotes();
    AudioEngine.clearAllSemitones();
    AudioEngine.setCenterTone(-1); // 清除音频引擎中的中心音
    
    notifyListeners();
  }

  @override
  void dispose() {
    // 确保清理资源
    if (AudioEngine.isAutoPlaying) {
      AudioEngine.stopAutoPlay();
    }
    _stopPlayingStateMonitor(); // 清理播放状态监控定时器
    _noteTextClearTimer?.cancel(); // 清理音符文本定时器
    _stopCountdownTimer(); // 清理倒计时定时器
    super.dispose();
  }

  /// 刷新当前播放的音符显示（当音名选择改变时调用）
  void refreshCurrentNoteDisplay() {
    if (AudioEngine.isInitialized) {
      final currentSemitone = AudioEngine.currentPlayingSemitone;
      if (currentSemitone >= 0 && currentSemitone <= 11) {
        // 重新获取音名并更新显示
        currentPlayingNote.value = _semitoneToNoteName(currentSemitone);
        notifyListeners();
      }
    }
  }

  /// 将slice索引(1-12)转换为半音索引(0-11)
  int _sliceToSemitone(int slice) {
    return (slice - 1) % 12;
  }



  /// 更新连续播放状态 - 使用C++音频引擎的自动播放功能
  void _updateContinuousPlay() {
    if (!AudioEngine.isInitialized) return;
    
    if (selected.value.isNotEmpty) {
      // 有选中的音级，启动C++音频引擎的自动播放
      if (!AudioEngine.isAutoPlaying) {
        AudioEngine.startAutoPlay();
        // 已启动C++自动播放
      }
      // 开始监控播放状态
      _startPlayingStateMonitor();
    } else {
      // 没有选中的音级，停止自动播放
      if (AudioEngine.isAutoPlaying) {
        AudioEngine.stopAutoPlay();
        playing.value = {};
        // 已停止C++自动播放
      }
      // 停止监控播放状态
      _stopPlayingStateMonitor();
    }
  }

  /// 开始监控播放状态
  void _startPlayingStateMonitor() {
    if (_playingStateTimer != null) return; // 已经在监控
    
    _playingStateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updatePlayingStateFromCurrentSemitone();
    });
  }

  /// 停止监控播放状态
  void _stopPlayingStateMonitor() {
    _playingStateTimer?.cancel();
    _playingStateTimer = null;
  }

  /// 根据当前播放的半音更新playing状态
  void _updatePlayingStateFromCurrentSemitone() {
    if (!AudioEngine.isInitialized) return;
    
    final currentSemitone = AudioEngine.currentPlayingSemitone;
    final currentPlaying = Set<int>.from(playing.value);
    
    if (currentSemitone >= 0 && currentSemitone <= 11) {
      // 有音符在播放
      final slice = currentSemitone + 1; // 转换为slice索引(1-12)
      
      // 更新音符文本并设置延迟清除
      _updateNoteTextWithDelay(currentSemitone);
      
      // 更新playing状态
      if (!currentPlaying.contains(slice)) {
        currentPlaying.clear();
        currentPlaying.add(slice);
        playing.value = currentPlaying;
        notifyListeners();
      }
    } else {
      // 没有音符在播放
      if (currentPlaying.isNotEmpty) {
        playing.value = {};
        notifyListeners();
      }
    }
  }

  /// 更新音符文本并设置延迟清除（90%时值）
  void _updateNoteTextWithDelay(int semitone) {
    // 更新音符文本
    currentPlayingNote.value = _semitoneToNoteName(semitone);
    
    // 取消之前的清除定时器
    _noteTextClearTimer?.cancel();
    
    // 计算90%时值的延迟时间
    final bpm = AudioEngine.bpm;
    final duration = AudioEngine.noteDuration;
    final baseDuration = 60000.0 / bpm; // 一拍的时长（毫秒）
    final actualDuration = baseDuration * (duration / 100.0) * 0.9; // 90%时值
    final delayMs = actualDuration.round().clamp(200, 5000); // 最少200ms，最多5秒
    
    // 设置新的清除定时器
    _noteTextClearTimer = Timer(Duration(milliseconds: delayMs), () {
      // 无论单选还是多选，都清除音符文本
      currentPlayingNote.value = '';
      notifyListeners();
    });
  }

  /// 同步selected半音到音频引擎
  void _syncSemitonesToAudioEngine() {
    if (!AudioEngine.isInitialized) return;
    
    // 先清除所有半音
    AudioEngine.clearAllSemitones();
    
    // 重新设置选中的半音
    for (final slice in selected.value) {
      final semitone = _sliceToSemitone(slice);
      AudioEngine.setSemitoneActive(semitone, true);
    }
    
    // 音级已同步到C++音频引擎
  }

  /// 手动触发随机播放一个音符（用于测试）
  Future<void> playRandomNote() async {
    if (!AudioEngine.isInitialized || selected.value.isEmpty) return;
    
    await AudioEngine.playRandomNote();
    // 播放状态现在通过实时监控自动更新，无需手动调用更新方法
  }

  /// 将半音索引转换为音符名称
  String _semitoneToNoteName(int semitone) {
    if (!AudioEngine.isInitialized) return '';
    
    // 只使用 Custom Mode
    return _getCustomModeNoteName(semitone);
  }

  /// Custom Mode 下根据用户选择返回音名
  String _getCustomModeNoteName(int semitone) {
    if (semitone < 0 || semitone >= 12) return '';
    
    final options = _semitoneOptions[semitone];
    final selections = _semitoneNoteSelections[semitone] ?? [];
    
    final selectedNames = <String>[];
    for (int i = 0; i < options.length && i < selections.length; i++) {
      if (selections[i]) {
        selectedNames.add(options[i]);
      }
    }
    
    return selectedNames.isEmpty ? options.first : selectedNames.join('/');
  }
  
  /// 开始倒计时定时器
  void _startCountdownTimer() {
    _stopCountdownTimer(); // 确保先停止之前的定时器
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdownProgress();
    });
  }
  
  /// 停止倒计时定时器
  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
  
  /// 更新倒计时进度
  void _updateCountdownProgress() {
    if (!AudioEngine.isInitialized) return;
    
    if (AudioEngine.timerEnabled) {
      // 获取总时长（分钟）和剩余时间（秒）
      final totalMinutes = AudioEngine.timerDuration;
      final remainingSeconds = AudioEngine.timerRemaining;
      
      if (totalMinutes > 0) {
        final totalSeconds = totalMinutes * 60;
        
        // 计算剩余进度 (1.0 到 0.0) - 从满圆开始倒计时
        final progress = remainingSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
        
        setCountdown(progress);
      } else {
        setCountdown(0.0);
      }
    } else {
      // 定时器未启用时清除进度
      setCountdown(0.0);
    }
  }
  
}
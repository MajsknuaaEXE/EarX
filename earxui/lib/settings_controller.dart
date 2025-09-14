import 'package:flutter/foundation.dart';
import 'audio_engine.dart';
import 'wheel_dial_controller.dart';
import 'localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  final WheelDialController? _wheelController;
  // 模式设置 - 只支持 Custom Mode
  final ValueNotifier<int> mode = ValueNotifier<int>(1);
  
  // 音频设置
  final ValueNotifier<double> volume = ValueNotifier<double>(80.0);
  final ValueNotifier<int> soundType = ValueNotifier<int>(0); // 0: Piano, 1: Sine Wave
  
  // 播放设置
  final ValueNotifier<double> speed = ValueNotifier<double>(30.0); // BPM
  final ValueNotifier<double> duration = ValueNotifier<double>(50.0); // 时值百分比
  
  // 定时设置
  final ValueNotifier<bool> timerEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<int> timerDuration = ValueNotifier<int>(0); // 0: 25min, 1: 35min, 2: 60min
  
  // 语言设置
  // 初始化时尽量与当前本地化保持一致，避免下拉框短暂显示为中文
  final ValueNotifier<int> language = ValueNotifier<int>(localization.currentLanguage.index); // 0: 中文, 1: English, 2: 日本語, 3: Deutsch, 4: Français, 5: 한국어
  

  SettingsController({WheelDialController? wheelController}) : _wheelController = wheelController {
    _initListeners();
    _initLocalizationListener();
    _loadInitialSettings();
  }

  void _initListeners() {
    mode.addListener(_onModeChanged);
    volume.addListener(_onVolumeChanged);
    soundType.addListener(_onSoundTypeChanged);
    speed.addListener(_onSpeedChanged);
    duration.addListener(_onDurationChanged);
    timerEnabled.addListener(_onTimerEnabledChanged);
    timerDuration.addListener(_onTimerDurationChanged);
    language.addListener(_onLanguageChanged);
  }

  void _initLocalizationListener() {
    // 监听本地化管理器的语言变化，同步到设置控制器
    localization.addListener(_onLocalizationChanged);
  }

  void _onLocalizationChanged() {
    // 当本地化管理器的语言改变时，同步更新设置控制器的语言值
    final newLanguageIndex = localization.currentLanguage.index;
    if (language.value != newLanguageIndex) {
      // 暂时移除监听器，避免循环更新
      language.removeListener(_onLanguageChanged);
      language.value = newLanguageIndex;
      language.addListener(_onLanguageChanged);
      notifyListeners();
    }
  }

  void _removeListeners() {
    mode.removeListener(_onModeChanged);
    volume.removeListener(_onVolumeChanged);
    soundType.removeListener(_onSoundTypeChanged);
    speed.removeListener(_onSpeedChanged);
    duration.removeListener(_onDurationChanged);
    timerEnabled.removeListener(_onTimerEnabledChanged);
    timerDuration.removeListener(_onTimerDurationChanged);
    language.removeListener(_onLanguageChanged);
    localization.removeListener(_onLocalizationChanged);
  }

  Future<void> _loadInitialSettings() async {
    // 从音频引擎获取当前设置
    // 暂时移除监听器避免初始化时触发不必要的回调
    _removeListeners();
    
    // 确保本地化管理器完成加载
    // 直接从 SharedPreferences 获取保存的语言，确保同步
    await _loadLanguageFromPreferences();
    
    // 只支持 Custom Mode
    mode.value = 1;
    volume.value = AudioEngine.isInitialized ? AudioEngine.masterVolume * 100.0 : 80.0;
    soundType.value = AudioEngine.isInitialized ? (AudioEngine.isPianoMode ? 0 : 1) : 0;
    speed.value = AudioEngine.bpm; // 从AudioEngine读取当前BPM值
    duration.value = AudioEngine.isInitialized ? AudioEngine.noteDuration : 50.0;
    timerDuration.value = AudioEngine.isInitialized ? _getTimerIndex(AudioEngine.timerDuration) : 0;
    timerEnabled.value = AudioEngine.isInitialized ? AudioEngine.timerEnabled : false;
    // 从本地化管理器获取当前语言设置
    language.value = localization.currentLanguage.index;
    
    // 确保定时器时长在AudioEngine中正确设置
    if (AudioEngine.isInitialized) {
      final minutes = getTimerMinutes();
      await AudioEngine.setTimerDuration(minutes);
    }
    
    // 重新添加监听器
    _initListeners();
    _initLocalizationListener();

    // 通知界面刷新，确保语言下拉框选中项与当前语言一致
    notifyListeners();
  }

  // 直接从 SharedPreferences 加载语言设置并同步到本地化管理器
  Future<void> _loadLanguageFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageIndex = prefs.getInt('selected_language');
      if (languageIndex != null && 
          languageIndex >= 0 && 
          languageIndex < SupportedLanguage.values.length) {
        // 确保本地化管理器也使用正确的语言
        localization.setLanguageByIndex(languageIndex);
      }
    } catch (e) {
      debugPrint('Failed to load language preference in SettingsController: $e');
    }
  }

  // 模式设置
  void setMode(int newMode) {
    if (mode.value != newMode) {
      mode.value = newMode;
    }
  }

  void _onModeChanged() async {
    // 只支持 Custom Mode，不需要处理模式切换
    notifyListeners();
  }

  // 音量设置
  void setVolume(double newVolume) {
    if (volume.value != newVolume) {
      volume.value = newVolume;
    }
  }

  void _onVolumeChanged() async {
    if (AudioEngine.isInitialized) {
      await AudioEngine.setMasterVolume(volume.value / 100.0);
    }
    notifyListeners();
  }

  // 音色设置
  void setSoundType(int newType) {
    if (soundType.value != newType) {
      soundType.value = newType;
    }
  }

  void _onSoundTypeChanged() async {
    if (AudioEngine.isInitialized) {
      // 0: Piano, 1: Sine Wave
      await AudioEngine.setPianoMode(soundType.value == 0);
    }
    notifyListeners();
  }

  // 速度设置
  void setSpeed(double newSpeed) {
    if (speed.value != newSpeed) {
      speed.value = newSpeed;
    }
  }

  void _onSpeedChanged() async {
    if (AudioEngine.isInitialized) {
      await AudioEngine.setBpm(speed.value);
      // C++音频引擎会自动处理BPM变化，无需通知Flutter端
    }
    notifyListeners();
  }

  // 时值设置
  void setDuration(double newDuration) {
    if (duration.value != newDuration) {
      duration.value = newDuration;
    }
  }

  void _onDurationChanged() async {
    if (AudioEngine.isInitialized) {
      await AudioEngine.setNoteDuration(duration.value);
    }
    notifyListeners();
  }

  // 定时模式开关
  void setTimerEnabled(bool enabled) {
    if (timerEnabled.value != enabled) {
      timerEnabled.value = enabled;
    }
  }

  void _onTimerEnabledChanged() async {
    print("Timer enabled changed: ${timerEnabled.value}");
    if (AudioEngine.isInitialized) {
      print("AudioEngine is initialized, calling setTimerEnabled");
      final result = await AudioEngine.setTimerEnabled(timerEnabled.value);
      print("setTimerEnabled result: $result");
      
      final minutes = getTimerMinutes();
      print("Setting timer duration: $minutes minutes");
      final durationResult = await AudioEngine.setTimerDuration(minutes);
      print("setTimerDuration result: $durationResult");
      
      // 如果启用定时器，同时启动自动播放（如果有选中的音级）
      if (timerEnabled.value && _wheelController != null) {
        if (_wheelController.selected.value.isNotEmpty) {
          print("Starting auto play");
          await AudioEngine.startAutoPlay();
        }
      }
    } else {
      print("AudioEngine is not initialized!");
    }
    notifyListeners();
  }

  // 定时时长设置
  void setTimerDuration(int duration) {
    if (timerDuration.value != duration) {
      timerDuration.value = duration;
    }
  }

  void _onTimerDurationChanged() async {
    if (AudioEngine.isInitialized) {
      final minutes = getTimerMinutes();
      await AudioEngine.setTimerDuration(minutes);
    }
    notifyListeners();
  }

  // 语言设置
  void setLanguage(int newLanguage) {
    if (language.value != newLanguage) {
      language.value = newLanguage;
    }
  }

  void _onLanguageChanged() async {
    // 更新本地化管理器的语言设置
    localization.setLanguageByIndex(language.value);
    // 这里可以持久化保存语言设置
    notifyListeners();
  }

  // 获取语言选项
  List<String> getLanguageOptions() {
    return SupportedLanguage.values.map((lang) => lang.displayName).toList();
  }

  // 获取当前语言显示文本
  String getCurrentLanguageText() {
    return getLanguageOptions()[language.value];
  }

  // 获取定时时长的分钟数
  int getTimerMinutes() {
    switch (timerDuration.value) {
      case 0:
        return 25;
      case 1:
        return 35;
      case 2:
        return 60;
      default:
        return 25;
    }
  }
  
  // 获取定时时长的秒数 - 新增函数
  int getTimerSeconds() {
    switch (timerDuration.value) {
      case 0:
        return 25 * 60; // 25分钟
      case 1:
        return 35 * 60; // 35分钟
      case 2:
        return 60 * 60; // 60分钟
      default:
        return 25 * 60;
    }
  }


  // 辅助函数：从定时时长获取索引
  int _getTimerIndex(int minutes) {
    switch (minutes) {
      case 25:
        return 0;
      case 35:
        return 1;
      case 60:
        return 2;
      default:
        return 0;
    }
  }


  @override
  void dispose() {
    _removeListeners(); // 确保移除所有监听器
    mode.dispose();
    volume.dispose();
    soundType.dispose();
    speed.dispose();
    duration.dispose();
    timerEnabled.dispose();
    timerDuration.dispose();
    language.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'wheel_dial_controller.dart';

/// 极简教程管理器：无遮罩、无弹窗，仅通过底部提示卡 + 高亮扇形引导。
class TutorialManager extends ChangeNotifier {
  static final TutorialManager _instance = TutorialManager._internal();
  factory TutorialManager() => _instance;
  TutorialManager._internal();

  bool isActive = false;
  int currentStep = 0;
  Function(String)? onNavigateToSettings; // 自动跳设置页

  void startTutorial({
    required WheelDialController controller,
    Function(String)? onNavigateToSettings,
  }) {
    this.onNavigateToSettings = onNavigateToSettings;
    isActive = true;
    currentStep = 0;
    notifyListeners();
  }

  void stop() { isActive = false; notifyListeners(); }

  // 标题与说明
  String get title {
    switch (currentStep) {
      case 0: return '欢迎来到 EarX';
      case 1: return '圆盘与音级';
      case 2: return '点亮 C 大调';
      case 3: return '设置中心音 C';
      case 4: return '调整难度（速度/时值）';
      case 5: return '切换音色';
      case 6: return '升级：升C旋律小调';
      case 7: return '自定义音名';
      case 8: return '开启定时';
      case 9: return '完成';
      default: return '';
    }
  }

  String get description {
    switch (currentStep) {
      case 0: return '这是一个主动听觉训练工具。点击右上角设置可随时调节。';
      case 1: return '圆盘等分12个音级，点击开关，长按设为中心音。';
      case 2: return '请点亮 C、D、E、F、G（5个高亮音级）以继续。';
      case 3: return '长按 C 音级设为中心音（再次长按可取消）。';
      case 4: return '已自动进入设置，请调整速度/时值后返回。';
      case 5: return '已自动进入设置，请切换音色后返回。';
      case 6: return '关闭 C 大调后点亮 C、C♯、E♭、E、F♯、A♭、A。';
      case 7: return '已自动进入设置，请在“自定义音名”修改显示。';
      case 8: return '已自动进入设置，请开启定时并选择时间。';
      case 9: return '你已经掌握了操作，多唱多构唱，享受训练！';
      default: return '';
    }
  }

  // 哪些步骤需要用户操作后才能下一步
  bool needsAction() => currentStep == 2 || currentStep == 3 || currentStep == 6;

  // 能否继续（用于禁用“下一步”）
  bool canProceed(WheelDialController c) {
    if (!needsAction()) return true;
    if (currentStep == 2) {
      const req = {1,3,5,6,8};
      final s = c.selected.value;
      return s.containsAll(req) && req.containsAll(s);
    }
    if (currentStep == 3) return c.currentCenterTone == 1;
    if (currentStep == 6) {
      const req = {1,2,4,5,7,9,10};
      final s = c.selected.value;
      return s.containsAll(req) && req.containsAll(s);
    }
    return true;
  }

  // 根据控制器检查完成条件（由外部监听控制器变化时调用）
  void checkUserAction(WheelDialController c) {
    if (!isActive) return;
    if (!needsAction()) return;
    if (canProceed(c)) next();
  }

  // 高亮集合（用于 WheelDial）
  Set<int> getHighlightedSlices() {
    if (!isActive) return {};
    switch (currentStep) {
      case 2: return {1, 3, 5, 6, 8};
      case 3: return {1};
      case 6: return {1, 2, 4, 5, 7, 9, 10};
      default: return {};
    }
  }

  // 下一步
  void next() {
    if (!isActive) return;
    currentStep++;
    if (currentStep > 9) { stop(); return; }
    // 自动跳设置页
    if (currentStep == 4) onNavigateToSettings?.call('speed_duration');
    if (currentStep == 5) onNavigateToSettings?.call('timbre');
    if (currentStep == 7) onNavigateToSettings?.call('note_names');
    if (currentStep == 8) onNavigateToSettings?.call('timer');
    notifyListeners();
  }
}


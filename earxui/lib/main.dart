import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'wheel_dial.dart';
import 'wheel_dial_controller.dart';
import 'wheel_theme.dart';
import 'audio_engine.dart';
import 'settings_ui.dart';
import 'splash_screen.dart';
import 'onboarding_overlay.dart';
import 'custom_page_transition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 锁定竖屏（禁用横屏）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final controller = WheelDialController();
  bool _audioEngineInitialized = false;
  bool _showSplash = true; // 启动页显示状态（超时后也会进入主界面）

  @override
  void initState() {
    super.initState();
    _initializeAudioEngine();
  }

  @override
  void dispose() {
    if (_audioEngineInitialized) {
      AudioEngine.destroy();
    }
    super.dispose();
  }

  Future<void> _initializeAudioEngine() async {
    // 在启动界面显示时完成所有初始化工作
    print('[EarX] 开始初始化音频引擎...');
    
    try {
      // 使用超时保护，避免无限等待
      final success = await AudioEngine.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('[EarX] 音频引擎初始化超时');
          return false;
        },
      );
      
      print('[EarX] 音频引擎初始化结果: $success');
      
      if (success) {
        try {
          // 设置默认参数，确保所有组件和采样都已加载完成
          await AudioEngine.setMasterVolume(0.7).timeout(const Duration(seconds: 3));
          await AudioEngine.setBpm(30.0).timeout(const Duration(seconds: 3));
          await AudioEngine.setNoteDuration(100.0).timeout(const Duration(seconds: 3));
          await AudioEngine.setPianoMode(false).timeout(const Duration(seconds: 3));
          print('[EarX] 音频引擎参数设置完成');
          
          // 等待钢琴采样加载完成
          print('[EarX] 等待钢琴采样加载完成...');
          int waitCount = 0;
          const maxWaitSeconds = 10;
          while (!AudioEngine.arePianoSamplesLoaded && waitCount < maxWaitSeconds) {
            await Future.delayed(const Duration(milliseconds: 500));
            waitCount++;
            print('[EarX] 钢琴采样加载中... ${waitCount * 0.5}秒');
          }
          
          if (AudioEngine.arePianoSamplesLoaded) {
            print('[EarX] 钢琴采样加载完成');
          } else {
            print('[EarX] 钢琴采样加载超时，继续启动');
          }
          
        } catch (e) {
          print('[EarX] 音频引擎参数设置失败: $e');
          // 参数设置失败不影响整体初始化结果
        }
      }
      
      // 所有初始化完成后，等待0.5秒再进入主界面
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _audioEngineInitialized = success;
          _showSplash = false; // 初始化完成后才关闭启动页
        });
      }
      
    } catch (e) {
      print('[EarX] 音频引擎初始化异常: $e');
      
      // 即使初始化失败，也要在一定时间后进入主界面
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _audioEngineInitialized = false;
          _showSplash = false; // 失败后也要进入主界面
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800), // 恢复原来的800ms过渡时间
        transitionBuilder: (Widget child, Animation<double> animation) {
          return buildAudioThemeTransition(child, animation);
        },
        child: _showSplash
            ? const SplashScreen(key: ValueKey('splash'))
            : _MainPage(
                key: const ValueKey('main'),
                audioEngineInitialized: _audioEngineInitialized,
                controller: controller,
              ),
      ),
    );
  }
}

class _MainPage extends StatefulWidget {
  const _MainPage({
    super.key,
    required this.audioEngineInitialized,
    required this.controller,
  });

  final bool audioEngineInitialized;
  final WheelDialController controller;

  @override
  State<_MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<_MainPage> {
  // 教程相关的全局键
  final GlobalKey _settingsButtonKey = GlobalKey();
  final GlobalKey _helpButtonKey = GlobalKey();
  final GlobalKey _wheelDialKey = GlobalKey();
  
  // 教程改为独立欢迎页，无全程交互管理

  @override
  void initState() {
    super.initState();
    // 监听用户操作以检查教程进度
    // 无交互教程，不再监听
  }

  @override
  void dispose() {
    // 无交互教程
    super.dispose();
  }


  /// 获取当前训练模式的显示文本
  String _getModeText() {
    if (!widget.audioEngineInitialized) return 'SILENT MODE';
    
    // 暂时默认显示 CUSTOM MODE，后续可以通过AudioEngine获取实际状态
    return 'CUSTOM MODE';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const WheelTheme().bg,
      appBar: AppBar(
        backgroundColor: const WheelTheme().bg,
        elevation: 0,
        actions: [
          IconButton(
            key: _settingsButtonKey,
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(wheelController: widget.controller)),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 主要内容
          Column(
            children: [
              const Expanded(flex: 1, child: SizedBox()),
              Expanded(
                flex: 3,
                child: Center(
                  child: ValueListenableBuilder<String>(
                    valueListenable: widget.controller.currentPlayingNote,
                    builder: (context, currentNote, _) {
                      final currentBpm = widget.audioEngineInitialized ? AudioEngine.bpm : 30.0;
                      return WheelDial(
                        key: _wheelDialKey,
                        size: 360,
                        controller: widget.controller,
                        nowPlayingText: widget.audioEngineInitialized ? currentNote : '',
                        modeText: _getModeText(),
                        informationText: '${currentBpm.round()} BPM',
                        rotationDeg: -75.0,
                        lightPattern: const [
                          true, false, true, false, true, true,
                          false, true,  false, true,  false, true,
                        ],
                        highlightedSlices: const {},
                        onSliceTap: (i) => widget.controller.toggleSelected(i),
                        onSliceLongPress: (i) {
                          if (widget.controller.currentCenterTone == i) {
                            widget.controller.setCenterTone(-1);
                          } else {
                            widget.controller.setCenterTone(i);
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
              const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
          // 帮助按钮 - 位于设置按钮正下方
          Positioned(
            top: -13, // AppBar 高度约 56，所以帮助按钮在 AppBar 下方
            right: 0, // 与设置按钮对齐
            child: IconButton(
              key: _helpButtonKey,
              icon: const Icon(Icons.help_outline, color: Colors.white, size: 24),
              onPressed: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'onboarding',
                  barrierColor: Colors.transparent,
                  transitionDuration: const Duration(milliseconds: 160),
                  pageBuilder: (_, __, ___) {
                    return const Material(
                      type: MaterialType.transparency,
                      child: SizedBox.expand(
                        child: OnboardingOverlay(
                          onClose: null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


}

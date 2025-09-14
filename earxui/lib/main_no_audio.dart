import 'package:flutter/material.dart';
import 'wheel_dial.dart';
import 'wheel_dial_controller.dart';
import 'wheel_theme.dart';
// 不导入 audio_engine.dart

void main() => runApp(const App());

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final controller = WheelDialController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _MainPage(controller: controller),
    );
  }
}

class _MainPage extends StatelessWidget {
  const _MainPage({
    required this.controller,
  });

  final WheelDialController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const WheelTheme().bg,
      appBar: AppBar(
        backgroundColor: const WheelTheme().bg,
        elevation: 0,
        title: const Text('测试版本', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WheelDial(
              size: 360,
              controller: controller,
              nowPlayingText: '♪',
              modeText: 'TEST MODE',
              informationText: 'No Audio Engine',
              rotationDeg: -75.0,
              lightPattern: const [
                true, false, true, false, true, true,
                false, true,  false, true,  false, true,
              ],
              onSliceTap: (i) {
                // 测试点击，但不调用音频引擎
                controller.toggleSelected(i);
              },
              onSliceLongPress: (i) {
                // 测试长按，但不调用音频引擎
                controller.setCenterTone(i);
              },
            ),
          ],
        ),
      ),
    );
  }
}
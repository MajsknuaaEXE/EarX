import 'package:flutter/material.dart';

@immutable
class WheelTheme {
  const WheelTheme({
    this.bg = const Color(0xFF0F4C5C),
    this.sliceLight = const Color(0xFFFFFFFF),
    this.sliceDark = const Color(0xFF000000),
    this.tick = const Color(0xFFFFFFFF),
    this.ledInfo = const Color(0xFFFFCC00),
    this.ledSelected = const Color(0xFF00E5FF),
    this.ledPlaying = const Color(0xFF00FF22),
    this.countdownBack = const Color(0xFF245B66),
    this.countdownFront = const Color.fromARGB(255, 255, 89, 89),
    this.textMain = const Color(0xFFFFFFFF),
    this.textSub = const Color(0xB3FFFFFF),
  });

  final Color bg, sliceLight, sliceDark, tick;
  final Color ledInfo, ledSelected, ledPlaying;
  final Color countdownBack, countdownFront;
  final Color textMain, textSub;
}
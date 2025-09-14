import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'wheel_dial_controller.dart';
import 'wheel_theme.dart';
import 'audio_engine.dart';

class WheelDial extends StatelessWidget {
  const WheelDial({
    super.key,
    required this.controller,
    this.size = 360,
    this.theme = const WheelTheme(),
    this.nowPlayingText = 'A♭',
    this.modeText = 'CUSTOM MODE',
    this.informationText = '92 BPM',
    this.showCountdown = true,
    this.onSliceTap,
    this.onSliceLongPress,
    this.rotationDeg = 0.0,
    /// 12-length: true=light, false=dark, index 0 is slice at rotationDeg
    this.lightPattern,
    /// 教程模式下需要高亮的音级
    this.highlightedSlices = const {},
  });

  final WheelDialController controller;
  final double size;
  final WheelTheme theme;
  final String nowPlayingText, modeText, informationText;
  final bool showCountdown;
  final void Function(int sliceIndex)? onSliceTap;            // 1..12
  final void Function(int sliceIndex)? onSliceLongPress;     // 长按回调
  final double rotationDeg;
  final List<bool>? lightPattern;
  final Set<int> highlightedSlices; // 教程高亮的音级

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: AnimatedBuilder(
        // 同时监听圆盘控制器与音色变更，音色切换时也会重建
        animation: Listenable.merge([controller, AudioEngine.timbreIsPianoNotifier]),
        builder: (context, _) {
          return _WheelHitLayer(
            rotationDeg: rotationDeg,
            onSliceTap: (i) {
              onSliceTap?.call(i);
            },
            onSliceLongPress: (i) {
              onSliceLongPress?.call(i);
            },
            child: CustomPaint(
              painter: _OuterRingPainter(theme: theme, rotationDeg: rotationDeg, lightPattern: lightPattern),
              foregroundPainter: _CompositePainter(
                painters: [
                  _TicksPainter(theme: theme, rotationDeg: rotationDeg),
                  _LedRingPainter(
                    theme: theme,
                    selected: controller.selected.value,
                    playing: controller.playing.value,
                    centerTone: controller.centerTone.value, // 添加中心音状态
                    rotationDeg: rotationDeg,
                    highlightedSlices: highlightedSlices, // 传递高亮音级
                  ),
                  _CenterPainter(
                    theme: theme,
                    nowPlayingText: nowPlayingText,
                    modeText: modeText,
                    informationText: informationText,
                    countdown: showCountdown ? controller.countdown.value : 0.0,
                    showTimbreIcon: true,
                    isPianoMode: AudioEngine.isInitialized ? AudioEngine.isPianoMode : false,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ---------------- Painters ---------------- */

class _CompositePainter extends CustomPainter {
  _CompositePainter({required this.painters});
  final List<CustomPainter> painters;

  @override
  void paint(Canvas canvas, Size size) {
    for (final painter in painters) {
      painter.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant _CompositePainter old) {
    if (painters.length != old.painters.length) return true;
    for (int i = 0; i < painters.length; i++) {
      if (painters[i].shouldRepaint(old.painters[i])) return true;
    }
    return false;
  }
}

class _OuterRingPainter extends CustomPainter {
  _OuterRingPainter({required this.theme, required this.rotationDeg, this.lightPattern});
  final WheelTheme theme;
  final double rotationDeg;
  final List<bool>? lightPattern;

  static const double _ringScale = 1.0;  // SVG 里 scale(560) 的比例抽象
  static const double _innerRatio = 0.55; // centerHole r=0.55
  static const double _sweepDeg = 28.0;
  static const double _stepDeg  = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.translate(c.dx, c.dy);
    final radius = size.shortestSide * 0.5;

    // 背景
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.width, height: size.height),
      Paint()..color = theme.bg,
    );

    final outerR = radius * _ringScale;
    final innerR = outerR * _innerRatio;

    final sweep = _deg2rad(_sweepDeg);
    final step  = _deg2rad(_stepDeg);
    final startOffset = _deg2rad(rotationDeg) - sweep/2;

    final pLight = Paint()..style = PaintingStyle.fill..color = theme.sliceLight;
    final pDark  = Paint()..style = PaintingStyle.fill..color = theme.sliceDark;

    List<bool> pattern = (lightPattern != null && lightPattern!.length == 12) ? lightPattern! : List<bool>.generate(12, (i) => i % 2 == 0);

    for (int i = 0; i < 12; i++) {
      final start = startOffset + i * step;
      final path = Path()
        ..moveTo(innerR*math.cos(start), innerR*math.sin(start))
        ..arcTo(Rect.fromCircle(center: Offset.zero, radius: outerR), start, sweep, false)
        ..lineTo(innerR*math.cos(start+sweep), innerR*math.sin(start+sweep))
        ..arcTo(Rect.fromCircle(center: Offset.zero, radius: innerR), start+sweep, -sweep, false)
        ..close();
      canvas.drawPath(path, pattern[i] ? pLight : pDark);
    }
  }

  @override
  bool shouldRepaint(covariant _OuterRingPainter old) => true; // force repaint on hot-reload/param change

  double _deg2rad(double d) => d * math.pi / 180.0;
}

class _TicksPainter extends CustomPainter {
  _TicksPainter({required this.theme, required this.rotationDeg});
  final WheelTheme theme;
  final double rotationDeg;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.5;
    final outerR = radius * 0.89;            // align with _OuterRingPainter._ringScale
    final innerR = outerR * 0.55;           // same inner hole

    // Major ticks (12) just outside inner hole
    final r1Major = innerR * 1.0;          // inner end
    final r2Major = innerR * 1.08;          // outer end
    final pMajor = Paint()
      ..color = theme.tick
      ..strokeCap = StrokeCap.round
      ..strokeWidth = radius * 0.005;       // thicker

    canvas.save();
    canvas.translate(size.width/2, size.height/2);

    // Draw 12 major ticks at 30° steps
    for (int i = 0; i < 12; i++) {
      final a = _deg2rad(rotationDeg - 15.0 + i * 30.0);
      final p1 = Offset(r1Major*math.cos(a), r1Major*math.sin(a));
      final p2 = Offset(r2Major*math.cos(a), r2Major*math.sin(a));
      canvas.drawLine(p1, p2, pMajor);
    }
    canvas.restore();
    // Old single 12-tick block removed to avoid duplication
  }

  @override
  bool shouldRepaint(covariant _TicksPainter old) => true; // depends on outer ring geometry/colors

  double _deg2rad(double d) => d * math.pi / 180.0;
}

class _LedRingPainter extends CustomPainter {
  _LedRingPainter({
    required this.theme,
    required this.selected,
    required this.playing,
    required this.centerTone,
    required this.rotationDeg,
    this.highlightedSlices = const {},
  });
  final WheelTheme theme;
  final Set<int> selected;
  final Set<int> playing;
  final int centerTone; // -1 表示无中心音，1-12 表示中心音扇形
  final double rotationDeg;
  final Set<int> highlightedSlices; // 教程高亮的音级

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.5;
    final outerR = radius * 0.56;
    final rr = outerR * 0.90; // LED 半径
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.02
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(size.width/2, size.height/2);

    for (int i = 0; i < 12; i++) {
      final slice = i + 1;
      final base = rotationDeg + i * 30.0;
      final angles = [base - 10, base, base + 10];

      // LED 位置映射：j=0(左) -> LED1(selected), j=1(中) -> LED2(playing), j=2(右) -> LED0(center)
      final ledOrder = [1, 2, 0]; // 从左到右显示：LED1, LED2, LED0
      
      for (int j = 0; j < 3; j++) {
        final ledIndex = ledOrder[j]; // 获取实际的LED功能索引
        final a = _deg2rad(angles[j]);
        final pos = Offset(rr*math.cos(a), rr*math.sin(a));
        final t = a + math.pi/2;
        final half = radius * 0.012;

        Color col = Colors.transparent; // 默认关
        if (ledIndex == 1 && selected.contains(slice)) col = theme.ledSelected;  // LED1(左侧): 选中状态
        if (ledIndex == 2 && playing.contains(slice))  col = theme.ledPlaying;   // LED2(中间): 播放状态  
        if (ledIndex == 0 && slice == centerTone) col = theme.ledInfo;           // LED0(右侧): 中心音指示

        if (col.a > 0) {
          stroke.color = col;
          final p1 = pos + Offset(half*math.cos(t), half*math.sin(t));
          final p2 = pos - Offset(half*math.cos(t), half*math.sin(t));
          canvas.drawLine(p1, p2, stroke);
        }
      }

      // 教程高亮效果：在音级周围画一个高亮圆环
      if (highlightedSlices.contains(slice)) {
        final highlightPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.06
          ..color = Colors.yellow.withOpacity(0.8);
        
        final centerAngle = _deg2rad(base);
        final centerPos = Offset(rr*math.cos(centerAngle), rr*math.sin(centerAngle));
        canvas.drawCircle(centerPos, radius * 0.08, highlightPaint);
        
        // 添加脉动效果
        final pulsePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.04
          ..color = Colors.yellow.withOpacity(0.4);
        canvas.drawCircle(centerPos, radius * 0.12, pulsePaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LedRingPainter old) =>
      old.selected != selected || 
      old.playing != playing || 
      old.centerTone != centerTone ||
      old.highlightedSlices != highlightedSlices;

  double _deg2rad(double d) => d * math.pi / 180.0;
}

class _CenterPainter extends CustomPainter {
  _CenterPainter({
    required this.theme,
    required this.nowPlayingText,
    required this.modeText,
    required this.informationText,
    required this.countdown,
    this.showTimbreIcon = false,
    required this.isPianoMode,
  });

  final WheelTheme theme;
  final String nowPlayingText, modeText, informationText;
  final double countdown;
  final bool showTimbreIcon;
  final bool isPianoMode; // true=钢琴, false=正弦

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide * 0.5;
    final outerR = radius * 0.56;

    canvas.save();
    canvas.translate(size.width/2, size.height/2);

    // 背圆（与你 SVG 的 center 背板）
    canvas.drawCircle(
      Offset.zero, outerR * 0.36 / 0.56, // 折算
      Paint()..color = theme.bg,
    );

    // 倒计时细环：先背环后前景
    final ringR = outerR * 0.82;
    final back = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.023
      ..color = theme.countdownBack;
    canvas.drawCircle(Offset.zero, ringR, back);

    final front = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.023
      ..strokeCap = StrokeCap.round
      ..color = theme.countdownFront;

    final sweep = (countdown.clamp(0, 1)) * 2 * math.pi;
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: ringR),
        _deg2rad(-90), sweep, false, front,
      );
    }

    // 中心文字 - 音名用更圆滑的字体
    _paintNoteText(canvas, nowPlayingText, radius * 0.25, theme.textMain, dy: -5.0);
    _paintText(canvas, modeText, radius * 0.06, theme.textSub, dy: radius * 0.22);
    _paintText(canvas, informationText, radius * 0.06, const Color(0xFFB8ADD6), dy: radius * 0.29);

    // 音色图标（仅在启用且音频引擎初始化时显示）
    if (showTimbreIcon && AudioEngine.isInitialized) {
      _paintTimbreIcon(canvas, radius);
    }

    canvas.restore();
  }

  void _paintText(Canvas canvas, String s, double px, Color col, {double dy = 0}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: col, fontSize: px, fontFamily: 'system-ui')),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width/2, -tp.height/2 + dy));
  }

  void _paintNoteText(Canvas canvas, String s, double px, Color col, {double dy = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s, 
        style: TextStyle(
          color: col, 
          fontSize: px,
          fontFamily: 'SF Pro Rounded', // iOS 系统圆润字体
          fontWeight: FontWeight.w300, // 稍微加粗让字形更饱满
          letterSpacing: px * 0.02, // 轻微字间距让字体更透气
        )
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-tp.width/2, -tp.height/2 + dy));
  }

  void _paintTimbreIcon(Canvas canvas, double radius) {
    final iconColor = const Color(0xFFe6a4fa);
    final strokeWidth = radius * 0.003;
    final scale = radius * 0.5; // 缩放因子
    final dy = radius * 0.38; // 图标垂直位置（底部）

    canvas.save();
    canvas.translate(0, dy);

    if (isPianoMode) {
      // 绘制钢琴键图标
      _paintPianoIcon(canvas, scale, iconColor, strokeWidth);
    } else {
      // 绘制正弦波图标  
      _paintSineIcon(canvas, scale, iconColor, strokeWidth);
    }

    canvas.restore();
  }

  void _paintSineIcon(Canvas canvas, double scale, Color color, double strokeWidth) {
    // 正弦波路径：M -0.08 0 C -0.06 -0.02 -0.04 0.02 -0.02 0 C 0.00 -0.02 0.02 0.02 0.04 0 C 0.06 -0.02 0.08 0.02 0.10 0
    final path = Path();
    path.moveTo(-0.08 * scale, 0);
    
    // 第一段贝塞尔曲线
    path.cubicTo(
      -0.06 * scale, -0.04 * scale,
      -0.04 * scale, 0.04 * scale,
      -0.02 * scale, 0
    );
    
    // 第二段贝塞尔曲线
    path.cubicTo(
      0.00 * scale, -0.04 * scale,
      0.02 * scale, 0.04 * scale,
      0.04 * scale, 0
    );
    
    // 第三段贝塞尔曲线
    path.cubicTo(
      0.06 * scale, -0.04 * scale,
      0.08 * scale, 0.04 * scale,
      0.10 * scale, 0
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _paintPianoIcon(Canvas canvas, double scale, Color color, double strokeWidth) {
    // 底座矩形
    final baseRect = Rect.fromLTWH(
      -0.10 * scale, -0.035 * scale,
      0.20 * scale, 0.07 * scale
    );
    
    final basePaint = Paint()
      ..color = const Color(0xFF0B3A43)
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2;

    // 绘制底座
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, Radius.circular(0.01 * scale)), basePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, Radius.circular(0.01 * scale)), strokePaint);

    // 白键分隔线
    final linePositions = [-0.06, -0.02, 0.02, 0.06];
    for (final x in linePositions) {
      canvas.drawLine(
        Offset(x * scale, -0.035 * scale),
        Offset(x * scale, 0.035 * scale),
        strokePaint,
      );
    }

    // 黑键
    final blackKeyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final blackKeyPositions = [-0.075,0.045];
    for (final x in blackKeyPositions) {
      final blackKeyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * scale, -0.035 * scale, 0.028 * scale, 0.026 * scale),
        Radius.circular(0.004 * scale)
      );
      canvas.drawRRect(blackKeyRect, blackKeyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CenterPainter old) =>
      old.countdown != countdown || 
      old.nowPlayingText != nowPlayingText || 
      old.modeText != modeText || 
      old.informationText != informationText ||
      old.showTimbreIcon != showTimbreIcon ||
      old.isPianoMode != isPianoMode;

  double _deg2rad(double d) => d * math.pi / 180.0;
}

/* ---------- 命中层：负责手势与极坐标命中 ---------- */

class _WheelHitLayer extends StatelessWidget {
  const _WheelHitLayer({
    required this.child,
    this.onSliceTap,
    this.onSliceLongPress,
    required this.rotationDeg,
  });

  final Widget child;
  final void Function(int sliceIndex)? onSliceTap;
  final void Function(int sliceIndex)? onSliceLongPress;
  final double rotationDeg;

  static const double _ringScale = 1.0; // match _OuterRingPainter outerR

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      final s = cons.biggest.shortestSide;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final slice = _getSliceFromPosition(context, d.globalPosition, s);
          if (slice != null) {
            onSliceTap?.call(slice);
          }
        },
        onLongPressStart: (d) {
          final slice = _getSliceFromPosition(context, d.globalPosition, s);
          if (slice != null) {
            onSliceLongPress?.call(slice);
          }
        },
        child: child,
      );
    });
  }

  /// 从触摸位置计算对应的扇形索引
  int? _getSliceFromPosition(BuildContext context, Offset globalPosition, double size) {
    final box = context.findRenderObject() as RenderBox;
    final local = box.globalToLocal(globalPosition);
    final center = Offset(size/2, size/2);
    final v = local - center;
    if (v == Offset.zero) return null;

    final rUnit = v.distance / (size/2);
    final deg = _normalizedDeg(math.atan2(v.dy, v.dx) * 180 / math.pi - rotationDeg);

    // 外环扇形（r ∈ [innerR, outerR]）
    const double outerR = _ringScale;        // 1.0
    const double innerR = _ringScale * 0.55; // 0.55
    if (rUnit >= innerR && rUnit <= outerR) {
      // 以 rotationDeg 为零度，整 30° 区域都算命中
      final slice = (((deg + 15.0) / 30.0).floor() % 12) + 1; // 1..12，四舍五入到最近扇心
      return slice;
    }
    return null;
  }

  static double _normalizedDeg(double d) => (d % 360 + 360) % 360;
}

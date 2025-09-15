import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 自定义页面过渡动画，包含音频主题的视觉效果
class CustomPageTransition extends StatefulWidget {
  final Widget child;
  final Animation<double> animation;

  const CustomPageTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  State<CustomPageTransition> createState() => _CustomPageTransitionState();
}

class _CustomPageTransitionState extends State<CustomPageTransition> {
  // 简化：直接使用传入的动画，不创建额外的动画控制器

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    final maxRadius = math.sqrt(
      math.pow(screenSize.width, 2) + math.pow(screenSize.height, 2)
    );

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final progress = widget.animation.value;

        // 基于主动画进度计算各种效果
        final rippleProgress = progress * 3.0;
        final scaleProgress = Curves.easeOutBack.transform(progress);
        final rotationProgress = Curves.easeOutCubic.transform(progress);
        final maskProgress = Curves.easeInOutCubic.transform(progress);

        final scale = 0.5 + (scaleProgress * 0.5); // 0.5 到 1.0
        final rotation = -0.05 + (rotationProgress * 0.05); // -0.05 到 0.0
        final maskRadius = maskProgress * maxRadius * 1.2;

        return Stack(
          children: [
            // 背景波纹效果
            Positioned.fill(
              child: CustomPaint(
                painter: RipplePainter(
                  progress: rippleProgress,
                  center: center,
                  maxRadius: maxRadius * 0.8,
                  opacity: progress * 0.3,
                ),
              ),
            ),

            // 圆形遮罩效果
            ClipPath(
              clipper: CircularRevealClipper(
                center: center,
                radius: maskRadius,
              ),
              child: Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: rotation,
                  child: Opacity(
                    opacity: progress,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 绘制音频波纹效果的自定义画笔
class RipplePainter extends CustomPainter {
  final double progress;
  final Offset center;
  final double maxRadius;
  final double opacity;

  RipplePainter({
    required this.progress,
    required this.center,
    required this.maxRadius,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制三层同心圆波纹，模拟声波扩散
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress - i * 0.3).clamp(0.0, 1.0);
      if (rippleProgress > 0) {
        final radius = rippleProgress * maxRadius;
        final alpha = ((1.0 - rippleProgress) * opacity * 255).round().clamp(0, 255);

        // 使用应用主题色
        paint.color = Color(0xFFE6A4FA).withAlpha(alpha);

        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.opacity != opacity;
  }
}

/// 圆形揭示裁剪器
class CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircularRevealClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    if (radius > 0) {
      path.addOval(Rect.fromCircle(center: center, radius: radius));
    }
    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

/// 音频主题的页面过渡构建器
Widget buildAudioThemeTransition(Widget child, Animation<double> animation) {
  return CustomPageTransition(
    animation: animation,
    child: child,
  );
}
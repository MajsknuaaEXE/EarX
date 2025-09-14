import 'package:flutter/material.dart';
import 'localization.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localization,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F4650),
          body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App icon/logo
            SizedBox(
              width: 128,
              height: 128,
              child: Image.asset(
                'assets/app_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'EarX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '听音训练',
              style: TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            const _LoadingIndicator(),
          ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();
  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<String> _textAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _buildTextAnimation();
    
    // 监听语言变化
    localization.addListener(_onLanguageChanged);
  }
  
  void _onLanguageChanged() {
    _buildTextAnimation();
  }
  
  void _buildTextAnimation() {
    _textAnimation = _controller.drive(
      TweenSequence<String>([
        TweenSequenceItem(
          tween: ConstantTween<String>(tr('loading_init_audio')),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: ConstantTween<String>(tr('loading_samples')),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: ConstantTween<String>(tr('loading_ready')),
          weight: 30,
        ),
      ]),
    );
  }

  @override
  void dispose() {
    localization.removeListener(_onLanguageChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE6A4FA)),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _textAnimation,
          builder: (context, child) {
            return Text(
              _textAnimation.value,
              style: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            );
          },
        ),
      ],
    );
  }
}

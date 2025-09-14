import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

    // Staggered animations for 6 blocks
    _fades = List.generate(6, (i) {
      final start = 0.08 * i;
      final end = start + 0.4;
      return CurvedAnimation(parent: _ctrl, curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut));
    });
    _slides = List.generate(6, (i) {
      final start = 0.08 * i;
      final end = start + 0.4;
      return Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl, curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic)));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1A24), Color(0xFF1E1230)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBlock(0, const Text(
                  'hi，欢迎来到 EarX',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                )),
                const SizedBox(height: 8),
                _buildBlock(1, const Text(
                  'EarX 的训练不是被动听音游戏，而是主动听觉训练工具。',
                  style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
                )),
                const SizedBox(height: 20),
                _buildCard(2, children: const [
                  _Bullet('你能点亮选定的几个音级进行随机播放'),
                  _Bullet('长按音级构建以该音级为随机播放中心的系统'),
                  _Bullet('在设置界面调节速度、时值、音色等参数'),
                ]),
                const SizedBox(height: 20),
                _buildBlock(3, const Text(
                  '最后的建议',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                )),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildCard(4, children: const [
                    _NumberedBullet(
                      index: 1,
                      title: '唱或默念音名',
                      detail: '听到随机音时，不只是猜对，要在心里唱出来或轻声唱出来。',
                    ),
                    _NumberedBullet(
                      index: 2,
                      title: '培养内心听觉',
                      detail: '反复练习，逐渐能在脑中“预听”音高，而不是等声音响起才反应。',
                    ),
                    _NumberedBullet(
                      index: 3,
                      title: '被动记忆辅助',
                      detail: '可以让少量音长时间循环帮助记忆，但别把它当主要训练方法。',
                    ),
                    _NumberedBullet(
                      index: 4,
                      title: '结合真实演奏',
                      detail: '这个软件只是工具，要真正提升音感，还需要用乐器多演奏、多构唱。',
                    ),
                  ]),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('我知道了', style: TextStyle(color: Colors.white)),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(int i, Widget child) {
    return SlideTransition(position: _slides[i], child: FadeTransition(opacity: _fades[i], child: child));
  }

  Widget _buildCard(int i, {required List<Widget> children}) {
    return _buildBlock(
      i,
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.35))),
        ],
      ),
    );
  }
}

class _NumberedBullet extends StatelessWidget {
  const _NumberedBullet({required this.index, required this.title, required this.detail});
  final int index; final String title; final String detail;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24, height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
          ]),
        )
      ]),
    );
  }
}


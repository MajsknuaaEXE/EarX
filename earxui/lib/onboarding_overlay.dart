import 'package:flutter/material.dart';
import 'localization.dart';

class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key, required this.onClose});
  final VoidCallback? onClose;

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
        ..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localization,
      builder: (context, _) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
          child: Stack(
        children: [
          // 背景遮罩（更暗一点）
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.92),
                  ],
                ),
              ),
            ),
          ),
          // 中心内容卡片，最大占屏幕高度的 80%
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final maxH = c.maxHeight * 0.8;
                  final maxW = c.maxWidth;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxW > 520 ? 520 : maxW - 24,
                        maxHeight: maxH,
                      ),
                      child: Material(
                        color: Colors.white.withOpacity(0.06),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: _OverlayContent(onClose: widget.onClose),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        ],
          ),
        );
      },
    );
  }
}

class _OverlayContent extends StatefulWidget {
  const _OverlayContent({required this.onClose});
  final VoidCallback? onClose;

  @override
  State<_OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<_OverlayContent> {
  bool _titleDone = false;
  bool _subtitleDone = false;
  int _bulletsShown = 0; // 0..3
  bool _adviceHeaderDone = false;
  int _adviceShown = 0; // 0..4

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontFamily: 'PingFang SC',
      color: Colors.white,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );
    const bodyStyle = TextStyle(
      fontFamily: 'PingFang SC',
      color: Colors.white70,
      fontSize: 13,
      height: 1.4,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TypewriterText(
                tr('onboarding_welcome_title'),
                style: const TextStyle(
                  fontFamily: 'PingFang SC',
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                charDelay: const Duration(milliseconds: 28),
                onComplete: () => setState(() => _titleDone = true),
                maxLines: 2,
              ),
            ),
            const Spacer(),
                                  IconButton(
                                    onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
                                    icon: const Icon(Icons.close, color: Colors.white70),
                                  ),
          ],
        ),
        const SizedBox(height: 6),
        if (_titleDone)
          TypewriterText(
            tr('onboarding_welcome_subtitle'),
            style: const TextStyle(fontFamily: 'PingFang SC', color: Colors.white70, fontSize: 14),
            charDelay: const Duration(milliseconds: 16),
            onComplete: () => setState(() => _subtitleDone = true),
            maxLines: 3,
          ),
        const SizedBox(height: 12),
        // 可滚动正文
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(right: 6, bottom: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_subtitleDone)
                _SectionCard(children: [
                  if (_bulletsShown >= 0)
                    _Dot(tr('onboarding_feature_1'), onComplete: () => setState(() => _bulletsShown = 1), bodyStyle: bodyStyle),
                  if (_bulletsShown >= 1)
                    _Dot(tr('onboarding_feature_2'), onComplete: () => setState(() => _bulletsShown = 2), bodyStyle: bodyStyle),
                  if (_bulletsShown >= 2)
                    _Dot(tr('onboarding_feature_3'), onComplete: () => setState(() => _bulletsShown = 3), bodyStyle: bodyStyle),
                ]),
              if (_bulletsShown >= 3) const SizedBox(height: 14),
              if (_bulletsShown >= 3)
                TypewriterText(
                  tr('onboarding_advice_title'),
                  style: const TextStyle(fontFamily: 'PingFang SC', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  onComplete: () => setState(() => _adviceHeaderDone = true),
                ),
              if (_adviceHeaderDone) const SizedBox(height: 8),
              if (_adviceHeaderDone)
                _SectionCard(children: [
                  if (_adviceShown >= 0)
                    _Numbered(
                      idx: 1, title: tr('onboarding_advice_1_title'),
                      body: tr('onboarding_advice_1_body'),
                      typewriter: true, onComplete: () => setState(() => _adviceShown = 1),
                      titleStyle: titleStyle, bodyStyle: bodyStyle,
                    ),
                  if (_adviceShown >= 1)
                    _Numbered(
                      idx: 2, title: tr('onboarding_advice_2_title'),
                      body: tr('onboarding_advice_2_body'),
                      typewriter: true, onComplete: () => setState(() => _adviceShown = 2),
                      titleStyle: titleStyle, bodyStyle: bodyStyle,
                    ),
                  if (_adviceShown >= 2)
                    _Numbered(
                      idx: 3, title: tr('onboarding_advice_3_title'),
                      body: tr('onboarding_advice_3_body'),
                      typewriter: true, onComplete: () => setState(() => _adviceShown = 3),
                      titleStyle: titleStyle, bodyStyle: bodyStyle,
                    ),
                  if (_adviceShown >= 3)
                    _Numbered(
                      idx: 4, title: tr('onboarding_advice_4_title'),
                      body: tr('onboarding_advice_4_body'),
                      typewriter: true, onComplete: () => setState(() => _adviceShown = 4),
                      titleStyle: titleStyle, bodyStyle: bodyStyle,
                    ),
                ]),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
            child: Text(tr('onboarding_close_button'), style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.text, {this.onComplete, this.bodyStyle});
  final String text;
  final VoidCallback? onComplete;
  final TextStyle? bodyStyle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(width: 2),
          Expanded(
            child: TypewriterText(
              text,
              style: bodyStyle ?? const TextStyle(color: Colors.white70, fontSize: 14, height: 1.35),
              charDelay: const Duration(milliseconds: 12),
              onComplete: onComplete,
            ),
          ),
        ],
      ),
    );
  }
}

class _Numbered extends StatelessWidget {
  const _Numbered({
    required this.idx,
    required this.title,
    required this.body,
    this.typewriter = false,
    this.delayMs = 0,
    this.onComplete,
    this.titleStyle,
    this.bodyStyle,
  });
  final int idx; final String title; final String body; final bool typewriter; final int delayMs; final VoidCallback? onComplete; final TextStyle? titleStyle; final TextStyle? bodyStyle;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22, height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Text('$idx', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: titleStyle ?? const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            if (!typewriter)
              Text(body, style: bodyStyle ?? const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))
            else
              TypewriterText(
                body,
                style: bodyStyle ?? const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                charDelay: const Duration(milliseconds: 12),
                startDelay: Duration(milliseconds: 200) + Duration(milliseconds: delayMs),
                onComplete: onComplete,
              ),
          ]),
        )
      ]),
    );
  }
}
/// 终端式打字机文字
class TypewriterText extends StatefulWidget {
  const TypewriterText(
    this.text, {
    super.key,
    this.style,
    this.charDelay = const Duration(milliseconds: 20),
    this.startDelay = Duration.zero,
    this.textAlign,
    this.maxLines,
    this.onComplete,
  });
  final String text;
  final TextStyle? style;
  final Duration charDelay;
  final Duration startDelay;
  final TextAlign? textAlign;
  final int? maxLines;
  final VoidCallback? onComplete;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _len = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!mounted) return;
    await Future.delayed(widget.startDelay);
    for (int i = 1; i <= widget.text.length; i++) {
      if (!mounted) return;
      setState(() => _len = i);
      await Future.delayed(widget.charDelay);
    }
    if (mounted) {
      setState(() => _done = true);
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.text.substring(0, _len);
    return Text(
      display,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: TextOverflow.visible,
    );
  }
}

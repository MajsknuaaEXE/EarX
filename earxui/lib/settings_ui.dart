import 'package:flutter/material.dart';
import 'settings_controller.dart';
import 'about_page.dart';
import 'wheel_dial_controller.dart';
import 'note_name_selector.dart';
import 'localization.dart';

class SettingsPage extends StatefulWidget {
  final WheelDialController? wheelController;
  final String? tutorialTarget; // 教程目标页面
  
  const SettingsPage({super.key, this.wheelController, this.tutorialTarget});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsController _controller;
  final ScrollController _scrollController = ScrollController();
  
  String _hintForTarget(String t) {
    switch (t) {
      case 'speed_duration':
        return '教程：请调整 速度(BPM) 或 时值，然后返回主界面点击“下一步”。';
      case 'timbre':
        return '教程：请切换音色（钢琴/正弦波），然后返回主界面点击“下一步”。';
      case 'note_names':
        return '教程：请在音名选择区修改需要的显示，然后返回主界面点击“下一步”。';
      case 'timer':
        return '教程：请开启定时并选择时间，然后返回主界面点击“下一步”。';
      default:
        return '';
    }
  }
  
  // 教程目标组件的GlobalKey
  final GlobalKey _speedSliderKey = GlobalKey();
  final GlobalKey _durationSliderKey = GlobalKey();
  final GlobalKey _timbreToggleKey = GlobalKey();
  final GlobalKey _timerToggleKey = GlobalKey();
  final GlobalKey _noteNameSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(wheelController: widget.wheelController);
    
    // 如果有教程目标，延迟启动教程引导
    if (widget.tutorialTarget != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTutorialForTarget(widget.tutorialTarget!);
      });
    }
  }

  void _startTutorialForTarget(String target) {
    GlobalKey? targetKey;
    String title = '';
    String description = '';
    
    switch (target) {
      case 'speed_duration':
        targetKey = _speedSliderKey;
        title = '调整播放速度和音符时长';
        description = '拖动滑块可以增加BPM速度或减少音符时长，让训练更有挑战性！';
        break;
      case 'timbre':
        targetKey = _timbreToggleKey;
        title = '切换音色';
        description = '点击切换到钢琴音色，体验不同的听感！';
        break;
      case 'timer':
        targetKey = _timerToggleKey;
        title = '定时关闭';
        description = '开启定时功能，设置睡前助眠时间！';
        break;
      case 'note_names':
        targetKey = _noteNameSectionKey;
        title = '自定义音名';
        description = '点击音级卡片修改音名显示，适应不同的调性需求！';
        break;
    }
    
    if (targetKey != null) {
      // 不再显示任何指引遮罩，仅滚动到目标控件，让用户自行调节
      _ensureVisible(targetKey);
    }
  }

  Future<void> _ensureVisible(GlobalKey key) async {
    // 多次尝试，确保目标渲染并可见
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 16));
      final ctx = key.currentContext;
      if (ctx != null) {
        try {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0.2,
            curve: Curves.easeInOut,
          );
          break;
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localization,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tr('settings'), style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF2A1B3D),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2A1B3D),
          body: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.all(16.0),
                controller: _scrollController,
                children: [
                  if (widget.tutorialTarget != null && widget.tutorialTarget!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D2A4F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFB8ADD6).withOpacity(0.4)),
                      ),
                      child: Text(
                        _hintForTarget(widget.tutorialTarget!),
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  _buildModeSection(),
                  const SizedBox(height: 24),
                  _buildCustomModeSection(),
                  const SizedBox(height: 24),
                  _buildAudioSection(highlightTimbre: widget.tutorialTarget == 'timbre'),
                  const SizedBox(height: 24),
                  _buildPlaybackSection(highlightSpeedDuration: widget.tutorialTarget == 'speed_duration'),
                  const SizedBox(height: 24),
                  _buildTimerSection(highlight: widget.tutorialTarget == 'timer'),
                  const SizedBox(height: 24),
                  _buildLanguageSection(),
                  const SizedBox(height: 24),
                  _buildAboutSection(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModeSection() {
    return _buildSection(
      title: tr('mode_settings'),
      children: [
        Text(
          tr('training_mode'),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSection({bool highlightTimbre = false}) {
    return _buildSection(
      title: tr('audio_settings'),
      children: [
        _buildSlider(
          title: tr('volume'),
          value: _controller.volume.value,
          min: 0,
          max: 100,
          divisions: 100,
          unit: '%',
          onChanged: (value) => _controller.setVolume(value),
        ),
        const SizedBox(height: 16),
        _buildSegmentedControl(
          key: _timbreToggleKey,
          title: tr('sound_type'),
          value: _controller.soundType.value,
          options: [tr('piano'), tr('sine_wave')],
          onChanged: (value) => _controller.setSoundType(value),
          highlight: highlightTimbre,
        ),
      ],
    );
  }

  Widget _buildPlaybackSection({bool highlightSpeedDuration = false}) {
    return _buildSection(
      title: tr('playback_settings'),
      children: [
        _buildSlider(
          key: _speedSliderKey,
          title: tr('speed'),
          value: _controller.speed.value,
          min: 20,
          max: 200,
          divisions: 180,
          unit: ' BPM',
          onChanged: (value) => _controller.setSpeed(value),
          highlight: highlightSpeedDuration,
        ),
        const SizedBox(height: 16),
        _buildSlider(
          key: _durationSliderKey,
          title: tr('duration'),
          value: _controller.duration.value,
          min: 10,
          max: 100,
          divisions: 90,
          unit: '%',
          onChanged: (value) => _controller.setDuration(value),
          highlight: highlightSpeedDuration,
        ),
      ],
    );
  }

  Widget _buildTimerSection({bool highlight = false}) {
    return _buildSection(
      title: tr('timer_settings'),
      children: [
        _buildSwitchTile(
          key: _timerToggleKey,
          title: tr('timer_mode'),
          value: _controller.timerEnabled.value,
          onChanged: (value) => _controller.setTimerEnabled(value),
          highlight: highlight,
        ),
        if (_controller.timerEnabled.value) ...[
          const SizedBox(height: 16),
          _buildSegmentedControl(
            title: tr('timer_duration'),
            value: _controller.timerDuration.value,
            options: [tr('25min'), tr('35min'), tr('60min')],
            onChanged: (value) => _controller.setTimerDuration(value),
            highlight: highlight,
          ),
        ],
      ],
    );
  }

  Widget _buildLanguageSection() {
    return _buildSection(
      title: tr('language_settings'),
      children: [
        _buildLanguageDropdown(),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: tr('licenses'),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr('about'), style: const TextStyle(color: Colors.white, fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFFB8ADD6)),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('language'),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1B3D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF5C4A6B)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _controller.language.value,
              isExpanded: true,
              dropdownColor: const Color(0xFF3D2A4F),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFB8ADD6)),
              items: _controller.getLanguageOptions().asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (int? value) {
                if (value != null) {
                  _controller.setLanguage(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomModeSection() {
    // 只支持Custom Mode
    final highlight = widget.tutorialTarget == 'note_names';
    return Container(
      key: _noteNameSectionKey,
      decoration: highlight
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB8ADD6)),
            )
          : null,
      child: NoteNameSelector(wheelController: widget.wheelController),
    );
  }

  Widget _buildSection({Key? key, required String title, required List<Widget> children}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2A4F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5C4A6B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSlider({
    Key? key,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required Function(double) onChanged,
    bool highlight = false,
  }) {
    final content = Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '${value.round()}$unit',
              style: const TextStyle(color: Color(0xFFB8ADD6), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF8A7CA8),
            inactiveTrackColor: const Color(0xFF5C4A6B),
            thumbColor: const Color(0xFFB8ADD6),
            overlayColor: const Color(0xFF8A7CA8).withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
    if (!highlight) return content;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB8ADD6)),
      ),
      child: content,
    );
  }

  Widget _buildSegmentedControl({
    Key? key,
    required String title,
    required int value,
    required List<String> options,
    required Function(int) onChanged,
    bool highlight = false,
  }) {
    final content = Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A1B3D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: options.asMap().entries.map((entry) {
              final int index = entry.key;
              final String option = entry.value;
              final bool isSelected = value == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF8A7CA8) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFFB8ADD6),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
    if (!highlight) return content;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB8ADD6)),
      ),
      child: content,
    );
  }

  Widget _buildSwitchTile({
    Key? key,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    bool highlight = false,
  }) {
    final row = Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF8A7CA8),
          activeTrackColor: const Color(0xFF5C4A6B),
          inactiveThumbColor: const Color(0xFFB8ADD6),
          inactiveTrackColor: const Color(0xFF2A1B3D),
        ),
      ],
    );
    if (!highlight) return row;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB8ADD6)),
      ),
      child: row,
    );
  }

}

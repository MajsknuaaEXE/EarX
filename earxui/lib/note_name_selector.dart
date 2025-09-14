import 'package:flutter/material.dart';
import 'audio_engine.dart';
import 'wheel_dial_controller.dart';
import 'localization.dart';

/// 音名选择器组件 - 用于Custom Mode下选择每个音级的音名显示方式
class NoteNameSelector extends StatefulWidget {
  final WheelDialController? wheelController;
  
  const NoteNameSelector({super.key, this.wheelController});

  @override
  State<NoteNameSelector> createState() => _NoteNameSelectorState();
}

class _NoteNameSelectorState extends State<NoteNameSelector> {
  // 存储每个音级的选择状态
  final Map<int, List<bool>> _selections = {};
  
  // 音级名称（用于显示）
  static const List<String> _semitoneNames = [
    'C', 'C♯/D♭', 'D', 'D♯/E♭', 'E', 'F', 
    'F♯/G♭', 'G', 'G♯/A♭', 'A', 'A♯/B♭', 'B'
  ];

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  /// 初始化音名选择状态
  void _initializeSelections() {
    for (int semitone = 0; semitone < 12; semitone++) {
      final noteNames = widget.wheelController?.getNoteNamesForSemitone(semitone) ?? 
                       AudioEngine.getNoteNamesForSemitone(semitone);
      final selections = <bool>[];
      
      // 获取当前的选择状态
      for (int i = 0; i < noteNames.length; i++) {
        selections.add(widget.wheelController?.getSemitoneNoteName(semitone, i) ?? 
                      AudioEngine.getSemitoneNoteName(semitone, i));
      }
      
      // 如果没有任何选择，默认选择第一个
      if (!selections.contains(true) && selections.isNotEmpty) {
        selections[0] = true;
      }
      
      _selections[semitone] = selections;
    }
  }

  /// 获取音级的当前显示文本
  String _getDisplayText(int semitone) {
    if (!_selections.containsKey(semitone)) return _semitoneNames[semitone];
    
    final noteNames = widget.wheelController?.getNoteNamesForSemitone(semitone) ?? 
                     AudioEngine.getNoteNamesForSemitone(semitone);
    final selections = _selections[semitone]!;
    
    final selectedNames = <String>[];
    for (int i = 0; i < noteNames.length && i < selections.length; i++) {
      if (selections[i]) {
        selectedNames.add(noteNames[i]);
      }
    }
    
    return selectedNames.isEmpty ? _semitoneNames[semitone] : selectedNames.join('/');
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localization,
      builder: (context, _) {
        return Container(
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
                tr('note_display_settings'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('note_selection_hint'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              // 钢琴键式的音级布局
              _buildSemitoneGrid(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSemitoneGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算白键的位置
        final containerWidth = constraints.maxWidth;
        final whiteKeyWidth = 40.0;
        final blackKeyWidth = 30.0;
        final totalWhiteKeys = 7;
        final spacing = (containerWidth - (totalWhiteKeys * whiteKeyWidth)) / (totalWhiteKeys - 1);
        
        // 计算每个白键的中心位置
        List<double> whiteKeyPositions = [];
        for (int i = 0; i < totalWhiteKeys; i++) {
          final position = i * (whiteKeyWidth + spacing) + whiteKeyWidth / 2;
          whiteKeyPositions.add(position);
        }
        
        // 计算黑键位置（相邻白键中心的平均值）
        final blackKeyPositions = [
          (whiteKeyPositions[0] + whiteKeyPositions[1]) / 2 - blackKeyWidth / 2, // C♯/D♭ (C和D之间)
          (whiteKeyPositions[1] + whiteKeyPositions[2]) / 2 - blackKeyWidth / 2, // D♯/E♭ (D和E之间)
          (whiteKeyPositions[3] + whiteKeyPositions[4]) / 2 - blackKeyWidth / 2, // F♯/G♭ (F和G之间)
          (whiteKeyPositions[4] + whiteKeyPositions[5]) / 2 - blackKeyWidth / 2, // G♯/A♭ (G和A之间)
          (whiteKeyPositions[5] + whiteKeyPositions[6]) / 2 - blackKeyWidth / 2, // A♯/B♭ (A和B之间)
        ];
        
        return Column(
          children: [
            // 第一行：黑键（使用相对定位）
            Stack(
              children: [
                Container(height: 48), // 预留空间给黑键
                // C♯/D♭
                Positioned(
                  left: blackKeyPositions[0],
                  child: _buildSemitoneCard(1, isWhiteKey: false),
                ),
                // D♯/E♭  
                Positioned(
                  left: blackKeyPositions[1],
                  child: _buildSemitoneCard(3, isWhiteKey: false),
                ),
                // F♯/G♭
                Positioned(
                  left: blackKeyPositions[2],
                  child: _buildSemitoneCard(6, isWhiteKey: false),
                ),
                // G♯/A♭
                Positioned(
                  left: blackKeyPositions[3], 
                  child: _buildSemitoneCard(8, isWhiteKey: false),
                ),
                // A♯/B♭
                Positioned(
                  left: blackKeyPositions[4],
                  child: _buildSemitoneCard(10, isWhiteKey: false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 第二行：白键
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [0, 2, 4, 5, 7, 9, 11].map((semitone) {
                return _buildSemitoneCard(semitone, isWhiteKey: true);
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSemitoneCard(int semitone, {required bool isWhiteKey}) {
    final displayText = _getDisplayText(semitone);
    final noteNames = widget.wheelController?.getNoteNamesForSemitone(semitone) ?? 
                     AudioEngine.getNoteNamesForSemitone(semitone);
    final selections = _selections[semitone] ?? [];
    
    return GestureDetector(
      onTap: () => _showNoteNameOptions(semitone, noteNames, selections),
      child: Container(
        width: isWhiteKey ? 40 : 30,
        height: isWhiteKey ? 60 : 40,
        decoration: BoxDecoration(
          color: isWhiteKey ? Colors.white : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isWhiteKey ? Colors.grey.shade300 : Colors.grey.shade600,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              color: isWhiteKey ? Colors.black : Colors.white,
              fontSize: isWhiteKey ? 10 : 8, // 白键字体稍大一些
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: isWhiteKey ? 2 : 3, // 允许换行显示多个音名
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// 显示音名选择选项对话框
  void _showNoteNameOptions(int semitone, List<String> noteNames, List<bool> selections) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF3D2A4F),
              title: Text(
                '${_semitoneNames[semitone]} ${tr('note_selection_title')}',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: noteNames.asMap().entries.map((entry) {
                  final index = entry.key;
                  final noteName = entry.value;
                  final isSelected = index < selections.length ? selections[index] : false;
                  
                  return CheckboxListTile(
                    title: Text(
                      noteName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    value: isSelected,
                    activeColor: const Color(0xFF6B46C1),
                    checkColor: Colors.white,
                    onChanged: (bool? value) {
                      if (value != null) {
                        // 检查是否为最后一个选择项
                        final currentSelections = selections.where((s) => s).length;
                        if (currentSelections == 1 && isSelected) {
                          // 如果是最后一个选择项，不允许取消
                          return;
                        }
                        
                        setDialogState(() {
                          selections[index] = value;
                        });
                        
                        setState(() {
                          _selections[semitone] = selections;
                        });
                        
                        // 优先使用轮盘控制器的方法，它会自动同步到AudioEngine
                        widget.wheelController?.setSemitoneNoteName(semitone, index, value);
                        
                        // 备份：如果没有轮盘控制器，直接调用AudioEngine
                        if (widget.wheelController == null) {
                          AudioEngine.setSemitoneNoteName(semitone, index, value);
                        }
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    tr('confirm'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
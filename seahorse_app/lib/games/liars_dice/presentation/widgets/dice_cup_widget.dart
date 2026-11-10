import 'package:flutter/material.dart';
import '../../domain/dice_model.dart';
import 'dice_3d_widget.dart';

/// 骰盅小部件 - 支持“掀盖偷看”与“开盅全开”状态
class DiceCupWidget extends StatefulWidget {
  final String playerName;
  final DiceCupModel cup;
  final bool isCurrentTurn;
  final bool isSelf;
  final bool isRevealedAll; // 开盅揭晓
  final int? highlightFace;
  final bool isWild1Active;

  const DiceCupWidget({
    Key? key,
    required this.playerName,
    required this.cup,
    this.isCurrentTurn = false,
    this.isSelf = false,
    this.isRevealedAll = false,
    this.highlightFace,
    this.isWild1Active = true,
  }) : super(key: key);

  @override
  State<DiceCupWidget> createState() => _DiceCupWidgetState();
}

class _DiceCupWidgetState extends State<DiceCupWidget> {
  bool _isPeeking = false;

  @override
  Widget build(BuildContext context) {
    final isOpen = widget.isRevealedAll || (widget.isSelf && _isPeeking);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isCurrentTurn
            ? const Color(0xFFFFFBEB)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isCurrentTurn ? const Color(0xFFD97706) : const Color(0xFFCBD5E1),
          width: widget.isCurrentTurn ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 玩家名与当前回合标记
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isCurrentTurn)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.record_voice_over, color: Color(0xFFD97706), size: 16),
                ),
              Text(
                widget.playerName + (widget.isSelf ? ' (我)' : ''),
                style: TextStyle(
                  color: widget.isCurrentTurn ? const Color(0xFFB45309) : const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 骰盅展示区
          Stack(
            alignment: Alignment.center,
            children: [
              // 底层：真实骰子内容
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.cup.dice.map((d) {
                    final isMatch = widget.highlightFace != null &&
                        (d.value == widget.highlightFace ||
                            (widget.isWild1Active && d.value == 1));

                    if (!isOpen && !widget.isSelf) {
                      // 未开盅且是他人的骰子 -> 问号背骰
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: widget.isSelf ? 38 : 28,
                        height: widget.isSelf ? 38 : 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.help_outline, color: Color(0xFF94A3B8), size: 16),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: Dice3DWidget(
                        value: d.value,
                        size: widget.isSelf ? 40 : 30,
                        isHighlighted: isMatch && widget.isRevealedAll,
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 顶层遮盖：未掀开时的骰盅盖子（仅在闭盅且未自瞄时遮盖）
              if (!isOpen)
                GestureDetector(
                  onTapDown: widget.isSelf ? (_) => setState(() => _isPeeking = true) : null,
                  onTapUp: widget.isSelf ? (_) => setState(() => _isPeeking = false) : null,
                  onTapCancel: widget.isSelf ? () => setState(() => _isPeeking = false) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB45309), Color(0xFF78350F)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_off, color: Color(0xFFFDE68A), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          widget.isSelf ? '按住偷瞄骰子 👁️' : '已扣盅 (5粒)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // 自己的控制辅助条
          if (widget.isSelf && !widget.isRevealedAll) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => setState(() => _isPeeking = !_isPeeking),
              child: Text(
                _isPeeking ? '🔒 点击扣好' : '🔓 点击保持掀开',
                style: const TextStyle(color: Color(0xFF0D9488), fontSize: 11, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

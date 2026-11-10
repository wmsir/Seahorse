import 'package:flutter/material.dart';
import '../../domain/take6_card.dart';
import 'take6_card_widget.dart';

/// 谁是牛头王 - 玩家手牌托盘组件
class Take6HandWidget extends StatelessWidget {
  final List<Take6Card> handCards;
  final Take6Card? selectedCard;
  final bool canPlay;
  final ValueChanged<Take6Card> onCardSelected;
  final VoidCallback onConfirmPlay;

  const Take6HandWidget({
    super.key,
    required this.handCards,
    required this.selectedCard,
    required this.canPlay,
    required this.onCardSelected,
    required this.onConfirmPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -3),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部手牌提示与确认出牌操作栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '🎴 我的手牌',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${handCards.length} 张',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: canPlay && selectedCard != null ? onConfirmPlay : null,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  selectedCard != null ? '出牌 [${selectedCard!.number}]' : '请先选牌',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: selectedCard != null ? 3 : 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 水平平铺手牌
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: handCards.length,
              itemBuilder: (context, index) {
                final card = handCards[index];
                final isSelected = selectedCard == card;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: Take6CardWidget(
                    card: card,
                    width: 52,
                    height: 74,
                    isSelected: isSelected,
                    onTap: canPlay ? () => onCardSelected(card) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

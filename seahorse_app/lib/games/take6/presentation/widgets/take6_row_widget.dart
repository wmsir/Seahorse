import 'package:flutter/material.dart';
import '../../domain/take6_row.dart';
import 'take6_card_widget.dart';

/// 谁是牛头王 - 单移行牌台面渲染组件
class Take6RowWidget extends StatelessWidget {
  final Take6Row row;
  final bool isSelectableToTake;
  final VoidCallback? onSelectRow;

  const Take6RowWidget({
    super.key,
    required this.row,
    this.isSelectableToTake = false,
    this.onSelectRow,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = row.count >= 4;
    final isFullOverflowWarning = row.count >= 5;

    return GestureDetector(
      onTap: isSelectableToTake ? onSelectRow : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelectableToTake
              ? const Color(0xFFFEF3C7)
              : (isFullOverflowWarning
                  ? const Color(0xFFFEE2E2).withOpacity(0.6)
                  : const Color(0xFF1E293B).withOpacity(0.04)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelectableToTake
                ? const Color(0xFFD97706)
                : (isFullOverflowWarning
                    ? const Color(0xFFEF4444)
                    : (isDanger ? const Color(0xFFF59E0B) : Colors.black12)),
            width: isSelectableToTake ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // 行标号与本行牛头累计
            Container(
              width: 32,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isSelectableToTake
                    ? const Color(0xFFD97706)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${row.rowIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '🐮${row.totalBullheads}',
                    style: const TextStyle(
                      color: Color(0xFFFCD34D),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 行牌 5 格卡槽
            Expanded(
              child: Row(
                children: List.generate(5, (slotIndex) {
                  final hasCard = slotIndex < row.cards.length;
                  if (hasCard) {
                    final card = row.cards[slotIndex];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Take6CardWidget(
                        card: card,
                        width: 46,
                        height: 64,
                      ),
                    );
                  } else {
                    // 空卡槽 (第 5 格标红预警)
                    final isFifthSlot = slotIndex == 4;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 46,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isFifthSlot
                              ? const Color(0xFFFEE2E2).withOpacity(0.5)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFifthSlot
                                ? const Color(0xFFFCA5A5)
                                : Colors.black12,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isFifthSlot ? '⚠️5' : '${slotIndex + 1}',
                            style: TextStyle(
                              color: isFifthSlot
                                  ? const Color(0xFFEF4444)
                                  : Colors.black26,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                }),
              ),
            ),

            if (isSelectableToTake)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '收此行',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

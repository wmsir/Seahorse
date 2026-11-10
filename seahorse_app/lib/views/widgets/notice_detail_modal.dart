import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../services/notice_service.dart';

/// 门店规章制度与运营规范全文查阅与强提醒底部弹窗
class NoticeDetailModal {
  static void show(BuildContext context, StoreNoticeModel notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildCategoryChip(notice),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notice.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('发布方：${notice.publisher}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(width: 16),
                        Text('版本：${notice.version}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(width: 16),
                        Text('生效日期：${notice.effectiveDate}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const Divider(height: 24),
                    if (notice.requireSignature) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_note, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '✍️ 本规章制度要求全员电子签署确认，请认真通读细则并严格遵守',
                                style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (notice.summary.isNotEmpty) ...[
                      const Text('💡 核心摘要', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(notice.summary, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (notice.keyPoints.isNotEmpty) ...[
                      const Text('📌 执行红线与重点要求', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      ...notice.keyPoints.map((kp) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                Expanded(child: Text(kp, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                    const Text('📜 详细细则与章程', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        notice.content.isNotEmpty ? notice.content : '（暂无详细补充条款）',
                        style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(notice.requireSignature ? '我已通读细则，遵守执行' : '我已知悉并遵照执行'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Widget _buildCategoryChip(StoreNoticeModel notice) {
    if (notice.isUrgent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
        child: const Text('🚨 特急', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    if (notice.category == 'REGULATION' || notice.category == 'SERVICE' || notice.category == 'SAFETY') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
        child: Text(notice.categoryName.isNotEmpty ? notice.categoryName : '规章制度',
            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(notice.categoryName.isNotEmpty ? notice.categoryName : '日常公告',
          style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

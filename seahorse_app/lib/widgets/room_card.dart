import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../core/utils/formatters.dart';
import '../models/space_model.dart';
import 'status_badge.dart';

class RoomCard extends StatelessWidget {
  final SpaceModel space;
  final VoidCallback onTap;
  final VoidCallback onQuickAction;

  const RoomCard({
    Key? key,
    required this.space,
    required this.onTap,
    required this.onQuickAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: space.status.primaryColor,
                width: 3.5,
              ),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 头部：编号、名称与状态
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                space.spaceCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                space.spaceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${space.floorZone} · 可容纳 ${space.capacity} 人',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: space.status.label,
                    textColor: space.status.primaryColor,
                    backgroundColor: space.status.backgroundColor,
                  ),
                ],
              ),

              const Divider(height: 16, color: AppColors.border),

              // 中部内容区：根据状态动态呈现
              if (space.status == SpaceStatus.occupied) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              space.currentCustomerName ?? '在场顾客',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 13, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '技师: ${(space.currentTechnicianName != null && space.currentTechnicianName!.isNotEmpty) ? space.currentTechnicianName! : '专职服务老师'}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(space.currentBillAmount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '已上钟 ${space.servedMinutes} 分钟',
                          style: const TextStyle(fontSize: 11, color: AppColors.info),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (space.status == SpaceStatus.idle) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      space.minConsumeAmount > 0
                          ? '低消门槛: ${Formatters.currency(space.minConsumeAmount)}'
                          : '无门槛低消',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    ElevatedButton(
                      onPressed: onQuickAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('立即开台', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ] else if (space.status == SpaceStatus.dirty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '已离场 · 待消毒翻台',
                      style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500),
                    ),
                    OutlinedButton(
                      onPressed: onQuickAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('一键清台', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  '维修/设备检修中，暂不开放',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

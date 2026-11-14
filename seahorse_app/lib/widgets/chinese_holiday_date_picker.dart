import 'package:flutter/material.dart';
import 'chinese_holiday_calendar_dialog.dart';

/// 包含中国法定节假日与休/班工作日标记的高级预约日历选择器
/// 复用 [ChineseHolidayCalendarDialog] 与 [ChineseHolidayCalendarGrid] 统一网格实现
class ChineseHolidayDatePicker extends StatelessWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const ChineseHolidayDatePicker({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  }) : super(key: key);

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final now = DateTime.now();
    return ChineseHolidayCalendarDialog.show(
      context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(now.year, now.month, now.day),
      lastDate: lastDate ?? now.add(const Duration(days: 90)),
      title: '选择预约到店日期',
      mondayFirst: true,
      showWorkdayBadge: true,
      showTodayButton: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChineseHolidayCalendarDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: '选择预约到店日期',
      mondayFirst: true,
      showWorkdayBadge: true,
      showTodayButton: false,
    );
  }
}

import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../core/utils/chinese_date_utils.dart';

/// 包含中国法定节假日与休/班工作日标记的高级预约日历选择器
class ChineseHolidayDatePicker extends StatefulWidget {
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
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChineseHolidayDatePicker(
        initialDate: initialDate ?? now,
        firstDate: firstDate ?? DateTime(now.year, now.month, now.day),
        lastDate: lastDate ?? now.add(const Duration(days: 90)),
      ),
    );
  }

  @override
  State<ChineseHolidayDatePicker> createState() => _ChineseHolidayDatePickerState();
}

class _ChineseHolidayDatePickerState extends State<ChineseHolidayDatePicker> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final holidayName = ChineseDateUtils.getHoliday(_selectedDate);
    final isWeekend = ChineseDateUtils.isWeekend(_selectedDate);
    final isRest = holidayName != null || isWeekend;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题与关闭
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '选择预约到店日期',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 年月切换控制栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 22),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${_currentMonth.year}年 ${_currentMonth.month.toString().padLeft(2, '0')}月',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 22),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 星期表头 (周一 ~ 周日)
          Row(
            children: List.generate(7, (index) {
              final weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
              final isRestDay = index >= 5;
              return Expanded(
                child: Center(
                  child: Text(
                    weekdayNames[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isRestDay ? Colors.red.shade400 : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),

          // 日历核心网格
          _buildCalendarGrid(),

          const SizedBox(height: 16),

          // 选中日期提示卡
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRest ? Colors.orange.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRest ? Colors.orange.shade200 : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRest ? Colors.red.shade500 : Colors.green.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isRest ? '休' : '班',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ChineseDateUtils.formatFullChineseDate(_selectedDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRest
                            ? (holidayName != null
                                ? '🎉【$holidayName】法定节假日 · 建议做好客流高峰技师调配'
                                : '🏖️ 周末休息日 · 顾客集中到店高峰，建议提前锁定包厢')
                            : '💼 工作日排班 · 客流平稳，技师充裕，接待体验极佳',
                        style: TextStyle(
                          fontSize: 11,
                          color: isRest ? Colors.orange.shade900 : Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 底部操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDate),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('确定选择该日期', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    
    // weekday 1~7 (1 is Monday, 7 is Sunday)
    final startingOffset = firstDayOfMonth.weekday - 1;
    final totalCells = ((startingOffset + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.05,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (ctx, index) {
        if (index < startingOffset || index >= startingOffset + daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNum = index - startingOffset + 1;
        final cellDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);

        final isSelected = cellDate.year == _selectedDate.year &&
            cellDate.month == _selectedDate.month &&
            cellDate.day == _selectedDate.day;

        final isToday = cellDate.year == DateTime.now().year &&
            cellDate.month == DateTime.now().month &&
            cellDate.day == DateTime.now().day;

        final isPast = cellDate.isBefore(
          DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day),
        );

        final holidayName = ChineseDateUtils.getHoliday(cellDate);
        final isWeekend = ChineseDateUtils.isWeekend(cellDate);
        final isRest = holidayName != null || isWeekend;

        return InkWell(
          onTap: isPast ? null : () => setState(() => _selectedDate = cellDate),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isToday ? AppColors.primary.withOpacity(0.08) : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isToday ? AppColors.primary.withOpacity(0.4) : Colors.transparent),
              ),
            ),
            child: Stack(
              children: [
                // 右上角 "休" / "班" 徽章
                Positioned(
                  top: 2,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.25)
                          : (isRest ? Colors.red.shade50 : Colors.green.shade50),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      isRest ? '休' : '班',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isRest ? Colors.red.shade600 : Colors.green.shade700),
                      ),
                    ),
                  ),
                ),

                // 中间日期数字与节日名
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w500,
                          color: isPast
                              ? AppColors.textMuted
                              : (isSelected
                                  ? Colors.white
                                  : (isRest ? Colors.red.shade700 : AppColors.textPrimary)),
                        ),
                      ),
                      if (holidayName != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          holidayName.length > 3 ? holidayName.substring(0, 3) : holidayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white70 : Colors.red.shade700,
                          ),
                        ),
                      ] else if (isToday) ...[
                        const SizedBox(height: 1),
                        Text(
                          '今日',
                          style: TextStyle(
                            fontSize: 8,
                            color: isSelected ? Colors.white70 : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
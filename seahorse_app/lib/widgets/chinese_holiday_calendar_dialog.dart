import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../core/utils/chinese_date_utils.dart';

/// 高颜值中华节假日日历选择器弹窗
class ChineseHolidayCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const ChineseHolidayCalendarDialog({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title = '选择预约排班与履约日期',
  }) : super(key: key);

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = '选择预约排班与履约日期',
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChineseHolidayCalendarDialog(
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 90)),
        lastDate: lastDate ?? DateTime.now().add(const Duration(days: 180)),
        title: title,
      ),
    );
  }

  @override
  State<ChineseHolidayCalendarDialog> createState() => _ChineseHolidayCalendarDialogState();
}

class _ChineseHolidayCalendarDialogState extends State<ChineseHolidayCalendarDialog> {
  late DateTime _selectedDate;
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day);
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _displayMonth = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_displayMonth.year, _displayMonth.month);
    final firstDayOfWeek = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7; // 0 = Sunday
    final totalCells = firstDayOfWeek + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selectedHoliday = ChineseDateUtils.getHoliday(_selectedDate);
    final isSelectedWeekend = ChineseDateUtils.isWeekend(_selectedDate);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖动条
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 标题与操作栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_available, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.today, size: 14, color: AppColors.primary),
                label: const Text('今天', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                onPressed: _jumpToToday,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 年月切换控制栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
                  tooltip: '上一月',
                  onPressed: _prevMonth,
                ),
                Row(
                  children: [
                    Text(
                      '${_displayMonth.year}年 ${_displayMonth.month}月',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    if (_displayMonth.year == 2026 && _displayMonth.month == 9)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Text('中秋佳节月 🌕', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                      ),
                    if (_displayMonth.year == 2026 && _displayMonth.month == 10)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Text('国庆黄金周 🇨🇳', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                  tooltip: '下一月',
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 星期表头
          Row(
            children: const [
              _WeekdayHeader(text: '日', isWeekend: true),
              _WeekdayHeader(text: '一'),
              _WeekdayHeader(text: '二'),
              _WeekdayHeader(text: '三'),
              _WeekdayHeader(text: '四'),
              _WeekdayHeader(text: '五'),
              _WeekdayHeader(text: '六', isWeekend: true),
            ],
          ),

          const SizedBox(height: 6),

          // 日历网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalRows * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.95,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (ctx, index) {
              final dayIndex = index - firstDayOfWeek + 1;
              if (dayIndex < 1 || dayIndex > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(_displayMonth.year, _displayMonth.month, dayIndex);
              final isSelected = cellDate.year == _selectedDate.year &&
                  cellDate.month == _selectedDate.month &&
                  cellDate.day == _selectedDate.day;
              final isToday = cellDate.year == today.year &&
                  cellDate.month == today.month &&
                  cellDate.day == today.day;
              final holiday = ChineseDateUtils.getHoliday(cellDate);
              final isWeekend = cellDate.weekday == DateTime.saturday || cellDate.weekday == DateTime.sunday;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = cellDate;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday ? const Color(0xFFEFF6FF) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday ? AppColors.primary.withOpacity(0.5) : Colors.transparent),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 中间主公历数字 + 节假日/农历副标题
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayIndex',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isWeekend ? const Color(0xFFEA580C) : AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            holiday ?? (isWeekend ? '休' : ChineseDateUtils.getLunarDayEstimate(cellDate)),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: (holiday != null || isSelected) ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : (holiday != null
                                      ? const Color(0xFFDC2626)
                                      : (isWeekend ? const Color(0xFFF97316) : Colors.grey.shade600)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // 右上角法定假日 "休" / "今" 徽章
                      if (holiday != null)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '休',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFFDC2626) : Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (isToday)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '今',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // 选中日期详情卡片
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selectedHoliday != null ? const Color(0xFFFEE2E2) : AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      selectedHoliday != null ? '🎉' : '📅',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                        selectedHoliday != null
                            ? '法定重大传统节假日 · 门店客流预增，建议提前排班履约'
                            : (isSelectedWeekend ? '公休日 · 客流高峰期，支持到店预约与工位预占' : '正常工作日 · 优质服务档期充足'),
                        style: TextStyle(
                          fontSize: 11,
                          color: selectedHoliday != null ? const Color(0xFFDC2626) : AppColors.textSecondary,
                          fontWeight: selectedHoliday != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 确认与取消操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('确认选择该日期', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pop(context, _selectedDate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String text;
  final bool isWeekend;

  const _WeekdayHeader({
    Key? key,
    required this.text,
    this.isWeekend = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isWeekend ? const Color(0xFFEA580C) : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../core/utils/chinese_date_utils.dart';

/// 可复用的中华节假日年月切换控制栏
class ChineseHolidayMonthBar extends StatelessWidget {
  final DateTime displayMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final bool padMonth;

  const ChineseHolidayMonthBar({
    Key? key,
    required this.displayMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
    this.padMonth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthText = padMonth
        ? '${displayMonth.year}年 ${displayMonth.month.toString().padLeft(2, '0')}月'
        : '${displayMonth.year}年 ${displayMonth.month}月';

    return Container(
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
            onPressed: onPrevMonth,
          ),
          Text(
            monthText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            tooltip: '下一月',
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }
}

/// 可复用的中华节假日日历核心网格（统一星期表头 + 日期/节假日/农历/休班渲染）
class ChineseHolidayCalendarGrid extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onSelectDate;
  final bool mondayFirst;
  final bool showWorkdayBadge;

  const ChineseHolidayCalendarGrid({
    Key? key,
    required this.displayMonth,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onSelectDate,
    this.mondayFirst = false,
    this.showWorkdayBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);
    final firstWeekday = DateTime(displayMonth.year, displayMonth.month, 1).weekday;
    final leadingEmpty = mondayFirst ? (firstWeekday - 1) : (firstWeekday % 7);
    final totalRows = ((leadingEmpty + daysInMonth) / 7).ceil();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final minDay = DateTime(firstDate.year, firstDate.month, firstDate.day);
    final maxDay = DateTime(lastDate.year, lastDate.month, lastDate.day);

    final weekdays = mondayFirst
        ? const ['一', '二', '三', '四', '五', '六', '日']
        : const ['日', '一', '二', '三', '四', '五', '六'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(7, (index) {
            final isWeekendCol = mondayFirst ? index >= 5 : (index == 0 || index == 6);
            return Expanded(
              child: Center(
                child: Text(
                  weekdays[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isWeekendCol ? const Color(0xFFEA580C) : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalRows * 7,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: showWorkdayBadge ? 1.05 : 0.95,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (ctx, index) {
            final dayIndex = index - leadingEmpty + 1;
            if (dayIndex < 1 || dayIndex > daysInMonth) {
              return const SizedBox.shrink();
            }

            final cellDate = DateTime(displayMonth.year, displayMonth.month, dayIndex);
            final isOutOfRange = cellDate.isBefore(minDay) || cellDate.isAfter(maxDay);
            final isSelected = cellDate.year == selectedDate.year &&
                cellDate.month == selectedDate.month &&
                cellDate.day == selectedDate.day;
            final isToday = cellDate.year == today.year &&
                cellDate.month == today.month &&
                cellDate.day == today.day;
            final holiday = ChineseDateUtils.getHoliday(cellDate);
            final isWeekend = ChineseDateUtils.isWeekend(cellDate);
            final isRest = holiday != null || isWeekend;

            final String subtitleText = showWorkdayBadge
                ? (holiday != null
                    ? (holiday.length > 3 ? holiday.substring(0, 3) : holiday)
                    : (isToday ? '今日' : ChineseDateUtils.getLunarDayEstimate(cellDate)))
                : (holiday ?? (isWeekend ? '休' : ChineseDateUtils.getLunarDayEstimate(cellDate)));

            return InkWell(
              onTap: isOutOfRange ? null : () => onSelectDate(cellDate),
              borderRadius: BorderRadius.circular(10),
              child: Opacity(
                opacity: isOutOfRange ? 0.38 : 1.0,
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
                              color: AppColors.primary.withOpacity(0.32),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayIndex',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isRest ? const Color(0xFFEA580C) : AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitleText,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: (holiday != null || isSelected || (showWorkdayBadge && isToday))
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : (holiday != null
                                      ? const Color(0xFFDC2626)
                                      : (isToday && showWorkdayBadge
                                          ? AppColors.primary
                                          : (isWeekend ? const Color(0xFFF97316) : Colors.grey.shade600))),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      if (showWorkdayBadge)
                        Positioned(
                          top: 2,
                          right: 2.5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.25)
                                  : (isRest ? Colors.red.shade50 : Colors.green.shade50),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              isRest ? '休' : '班',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isRest ? Colors.red.shade600 : Colors.green.shade700),
                              ),
                            ),
                          ),
                        )
                      else if (holiday != null)
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
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 高颜值中华节假日日历选择器弹窗
class ChineseHolidayCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;
  final bool mondayFirst;
  final bool showWorkdayBadge;
  final bool showTodayButton;

  const ChineseHolidayCalendarDialog({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title = '选择预约排班与履约日期',
    this.mondayFirst = false,
    this.showWorkdayBadge = false,
    this.showTodayButton = true,
  }) : super(key: key);

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = '选择预约排班与履约日期',
    bool mondayFirst = false,
    bool showWorkdayBadge = false,
    bool showTodayButton = true,
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
        mondayFirst: mondayFirst,
        showWorkdayBadge: showWorkdayBadge,
        showTodayButton: showTodayButton,
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
    final today = DateTime(now.year, now.month, now.day);
    final minDay = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final maxDay = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    final clamped = today.isBefore(minDay)
        ? minDay
        : (today.isAfter(maxDay) ? maxDay : today);
    setState(() {
      _selectedDate = clamped;
      _displayMonth = DateTime(clamped.year, clamped.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                    child: Icon(
                      widget.showWorkdayBadge ? Icons.calendar_month : Icons.event_available,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              if (widget.showTodayButton)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.today, size: 14, color: AppColors.primary),
                  label: const Text('今天', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  onPressed: _jumpToToday,
                )
              else
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),

          const SizedBox(height: 14),

          ChineseHolidayMonthBar(
            displayMonth: _displayMonth,
            onPrevMonth: _prevMonth,
            onNextMonth: _nextMonth,
            padMonth: widget.showWorkdayBadge,
          ),

          const SizedBox(height: 10),

          ChineseHolidayCalendarGrid(
            displayMonth: _displayMonth,
            selectedDate: _selectedDate,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            mondayFirst: widget.mondayFirst,
            showWorkdayBadge: widget.showWorkdayBadge,
            onSelectDate: (date) => setState(() => _selectedDate = date),
          ),

          const SizedBox(height: 14),

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
                            ? '【$selectedHoliday】法定节假日 · 门店客流预增，建议提前排班履约'
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

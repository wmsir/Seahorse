import 'package:intl/intl.dart';

class ChineseDateUtils {
  static const List<String> weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  static const List<String> fullWeekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

  /// 公历固定节日字典 (月-日)
  static const Map<String, String> solarHolidays = {
    '01-01': '元旦',
    '02-14': '情人节',
    '03-08': '妇女节',
    '03-12': '植树节',
    '04-05': '清明节',
    '05-01': '五一劳动节',
    '05-04': '青年节',
    '06-01': '儿童节',
    '07-01': '建党节',
    '08-01': '建军节',
    '09-10': '教师节',
    '10-01': '国庆节',
    '10-02': '国庆假期',
    '10-03': '国庆假期',
    '12-24': '平安夜',
    '12-25': '圣诞节',
  };

  /// 常见近三年农历重大节日公历速查表 (2025 - 2027)
  static const Map<String, String> lunarHolidaysLookup = {
    // 2025
    '2025-01-28': '除夕',
    '2025-01-29': '春节',
    '2025-02-12': '元宵节',
    '2025-05-31': '端午节',
    '2025-08-29': '七夕节',
    '2025-10-06': '中秋节',
    '2025-10-29': '重阳节',
    '2026-01-01': '元旦',
    '2026-02-16': '除夕',
    '2026-02-17': '春节',
    '2026-02-18': '初二',
    '2026-02-19': '初三',
    '2026-03-03': '元宵节',
    '2026-04-05': '清明节',
    '2026-05-01': '五一劳动节',
    '2026-05-02': '五一假期',
    '2026-05-03': '五一假期',
    '2026-06-19': '端午节',
    '2026-08-19': '七夕节',
    '2026-09-10': '教师节',
    '2026-09-25': '中秋节',
    '2026-09-26': '中秋假期',
    '2026-09-27': '中秋假期',
    '2026-10-01': '国庆节',
    '2026-10-02': '国庆假期',
    '2026-10-03': '国庆假期',
    '2026-10-04': '国庆假期',
    '2026-10-05': '国庆假期',
    '2026-10-06': '国庆假期',
    '2026-10-07': '国庆假期',
    '2026-10-18': '重阳节',
    // 2027
    '2027-01-01': '元旦',
    '2027-02-05': '除夕',
    '2027-02-06': '春节',
    '2027-02-20': '元宵节',
    '2027-04-05': '清明节',
    '2027-05-01': '五一节',
    '2027-06-09': '端午节',
    '2027-08-08': '七夕节',
    '2027-09-15': '中秋节',
    '2027-10-01': '国庆节',
    '2027-10-08': '重阳节',
  };

  /// 农历日期简短名称速查 (初一~三十)
  static String getLunarDayEstimate(DateTime date) {
    // 2026年9月11日对应农历八月初一
    final ref = DateTime(2026, 9, 11);
    final diff = DateTime(date.year, date.month, date.day).difference(ref).inDays;
    int index = (diff % 30);
    if (index < 0) index += 30;

    const lunarDays = [
      '初一', '初二', '初三', '初四', '初五', '初六', '初七', '初八', '初九', '初十',
      '十一', '十二', '十三', '十四', '十五', '十六', '十七', '十八', '十九', '二十',
      '廿一', '廿二', '廿三', '廿四', '廿五', '廿六', '廿七', '廿八', '廿九', '三十'
    ];
    return lunarDays[index];
  }

  /// 是否为周末 (周六或周日)
  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// 获取指定日期的节日名称（若有返回节日名称，否则返回 null）
  static String? getHoliday(DateTime date) {
    final ymd = DateFormat('yyyy-MM-dd').format(date);
    if (lunarHolidaysLookup.containsKey(ymd)) {
      return lunarHolidaysLookup[ymd];
    }
    final md = DateFormat('MM-dd').format(date);
    if (solarHolidays.containsKey(md)) {
      return solarHolidays[md];
    }
    return null;
  }

  /// 获取周几（简短：周一 ~ 周日）
  static String getWeekdayShort(DateTime date) {
    return weekdays[date.weekday - 1];
  }

  /// 获取星期（完整：星期一 ~ 星期日）
  static String getWeekdayFull(DateTime date) {
    return fullWeekdays[date.weekday - 1];
  }

  /// 相对日期友好称呼（今天、明天、后天、昨天，包含节日或周末休息标识）
  static String getRelativeFriendlyDate(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(target.year, target.month, target.day);
    final diff = compareDate.difference(today).inDays;

    final holiday = getHoliday(target);
    final weekend = isWeekend(target);
    String statusSuffix = '';
    if (holiday != null) {
      statusSuffix = ' · $holiday';
    } else if (weekend) {
      statusSuffix = ' · 休';
    }

    if (diff == 0) {
      return '今日 (周${_chineseNumber(target.weekday)}$statusSuffix)';
    } else if (diff == 1) {
      return '明日 (周${_chineseNumber(target.weekday)}$statusSuffix)';
    } else if (diff == 2) {
      return '后天 (周${_chineseNumber(target.weekday)}$statusSuffix)';
    } else if (diff == -1) {
      return '昨日 (周${_chineseNumber(target.weekday)}$statusSuffix)';
    }

    if (holiday != null) {
      return '${target.month}月${target.day}日 · $holiday';
    }
    return '${target.month}月${target.day}日 周${_chineseNumber(target.weekday)}$statusSuffix';
  }

  /// 格式化中国完整日期：例如 "2026年9月12日 星期六 (🏖️周末休息)"
  static String formatFullChineseDate(DateTime date, {bool showHoliday = true}) {
    final holiday = showHoliday ? getHoliday(date) : null;
    final weekend = isWeekend(date);
    final weekdayStr = getWeekdayFull(date);
    if (holiday != null) {
      return '${date.year}年${date.month}月${date.day}日 $weekdayStr (🎉$holiday)';
    } else if (weekend) {
      return '${date.year}年${date.month}月${date.day}日 $weekdayStr (🏖️周末休息)';
    }
    return '${date.year}年${date.month}月${date.day}日 $weekdayStr';
  }

  /// 格式化简写中国日期：例如 "9月12日 周六 · 休"
  static String formatShortChineseDate(DateTime date, {bool showHoliday = true}) {
    final holiday = showHoliday ? getHoliday(date) : null;
    final weekend = isWeekend(date);
    final weekdayStr = getWeekdayShort(date);
    if (holiday != null) {
      return '${date.month}月${date.day}日 $weekdayStr · $holiday';
    } else if (weekend) {
      return '${date.month}月${date.day}日 $weekdayStr · 休';
    }
    return '${date.month}月${date.day}日 $weekdayStr';
  }

  /// 格式化时间段友好展示（例如 "上午 09:30" / "下午 14:00" / "晚上 20:30"）
  static String formatChineseTime(DateTime date) {
    String period = '上午';
    if (date.hour < 6) {
      period = '凌晨';
    } else if (date.hour < 12) {
      period = '上午';
    } else if (date.hour < 14) {
      period = '中午';
    } else if (date.hour < 18) {
      period = '下午';
    } else {
      period = '晚上';
    }
    final minuteStr = date.minute.toString().padLeft(2, '0');
    final hourStr = date.hour.toString().padLeft(2, '0');
    return '$period $hourStr:$minuteStr';
  }

  static String _chineseNumber(int n) {
    const list = ['一', '二', '三', '四', '五', '六', '日'];
    if (n >= 1 && n <= 7) return list[n - 1];
    return n.toString();
  }
}

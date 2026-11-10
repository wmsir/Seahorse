/**
 * 中国法定节假日、传统农历节日及周末休息判断工具
 */

export interface HolidayInfo {
  name: string
  isStatutory: boolean
}

export interface DateBadgeInfo {
  text: string
  shortText: string
  type: 'danger' | 'warning' | 'info' | 'success'
  icon: string
  isHoliday: boolean
  isWeekend: boolean
  isStatutory?: boolean
}

// 公历节日
const solarHolidays: Record<string, HolidayInfo> = {
  '01-01': { name: '元旦', isStatutory: true },
  '02-14': { name: '情人节', isStatutory: false },
  '03-08': { name: '妇女节', isStatutory: false },
  '03-12': { name: '植树节', isStatutory: false },
  '04-05': { name: '清明节', isStatutory: true },
  '05-01': { name: '劳动节', isStatutory: true },
  '05-04': { name: '青年节', isStatutory: false },
  '06-01': { name: '儿童节', isStatutory: false },
  '07-01': { name: '建党节', isStatutory: false },
  '08-01': { name: '建军节', isStatutory: false },
  '09-10': { name: '教师节', isStatutory: false },
  '10-01': { name: '国庆节', isStatutory: true },
  '10-02': { name: '国庆假期', isStatutory: true },
  '10-03': { name: '国庆假期', isStatutory: true },
  '12-24': { name: '平安夜', isStatutory: false },
  '12-25': { name: '圣诞节', isStatutory: false }
}

// 农历重大节日公历速查 (2025-2027)
const lunarHolidaysLookup: Record<string, HolidayInfo> = {
  // 2025
  '2025-01-28': { name: '除夕', isStatutory: true },
  '2025-01-29': { name: '春节', isStatutory: true },
  '2025-02-12': { name: '元宵节', isStatutory: false },
  '2025-05-31': { name: '端午节', isStatutory: true },
  '2025-08-29': { name: '七夕节', isStatutory: false },
  '2025-10-06': { name: '中秋节', isStatutory: true },
  '2025-10-29': { name: '重阳节', isStatutory: false },
  // 2026
  '2026-02-16': { name: '除夕', isStatutory: true },
  '2026-02-17': { name: '春节', isStatutory: true },
  '2026-03-03': { name: '元宵节', isStatutory: false },
  '2026-06-19': { name: '端午节', isStatutory: true },
  '2026-08-19': { name: '七夕节', isStatutory: false },
  '2026-09-25': { name: '中秋节', isStatutory: true },
  '2026-10-18': { name: '重阳节', isStatutory: false },
  // 2027
  '2027-02-05': { name: '除夕', isStatutory: true },
  '2027-02-06': { name: '春节', isStatutory: true },
  '2027-02-20': { name: '元宵节', isStatutory: false },
  '2027-06-09': { name: '端午节', isStatutory: true },
  '2027-08-08': { name: '七夕节', isStatutory: false },
  '2027-09-15': { name: '中秋节', isStatutory: true },
  '2027-10-08': { name: '重阳节', isStatutory: false }
}

const parseDate = (d: Date | string): Date => {
  if (typeof d === 'string') {
    const parts = d.split(' ')[0].split('-')
    if (parts.length === 3) {
      return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
    }
    return new Date(d)
  }
  return d
}

const formatDateKey = (d: Date): { ymd: string; md: string } => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const date = String(d.getDate()).padStart(2, '0')
  return {
    ymd: y + '-' + m + '-' + date,
    md: m + '-' + date
  }
}

/** 是否是周末 (周六或周日) */
export const isWeekend = (d: Date | string): boolean => {
  const date = parseDate(d)
  const day = date.getDay()
  return day === 0 || day === 6
}

/** 获取节假日信息 */
export const getHoliday = (d: Date | string): HolidayInfo | null => {
  const date = parseDate(d)
  const { ymd, md } = formatDateKey(date)
  if (lunarHolidaysLookup[ymd]) {
    return lunarHolidaysLookup[ymd]
  }
  if (solarHolidays[md]) {
    return solarHolidays[md]
  }
  return null
}

/** 获取日期状态徽章 */
export const getDateBadge = (d: Date | string): DateBadgeInfo => {
  const holiday = getHoliday(d)
  if (holiday) {
    return {
      text: holiday.name + (holiday.isStatutory ? ' · 节假日' : ''),
      shortText: holiday.name,
      type: 'danger',
      icon: '🎉',
      isHoliday: true,
      isWeekend: isWeekend(d),
      isStatutory: holiday.isStatutory
    }
  }

  if (isWeekend(d)) {
    return {
      text: '周末休息',
      shortText: '休',
      type: 'warning',
      icon: '🏖️',
      isHoliday: false,
      isWeekend: true
    }
  }

  return {
    text: '工作日',
    shortText: '班',
    type: 'info',
    icon: '💼',
    isHoliday: false,
    isWeekend: false
  }
}

/** 获取日期星期展示 (例如 周六、周日) */
export const getWeekdayText = (d: Date | string): string => {
  const date = parseDate(d)
  const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
  return days[date.getDay()]
}

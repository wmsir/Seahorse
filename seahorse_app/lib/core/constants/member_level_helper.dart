import 'package:flutter/material.dart';

/// 统一会员等级视觉配置
class MemberLevelStyle {
  final String levelCode;
  final String levelName;
  final Color primaryColor;
  final Color badgeTextColor;
  final Color badgeBgColor;
  final Color borderColor;
  final IconData icon;
  final bool isDarkCard;
  final List<Color> cardGradient;

  const MemberLevelStyle({
    required this.levelCode,
    required this.levelName,
    required this.primaryColor,
    required this.badgeTextColor,
    required this.badgeBgColor,
    required this.borderColor,
    required this.icon,
    this.isDarkCard = false,
    required this.cardGradient,
  });

  Color get badgeColor => primaryColor;
}

class MemberLevelHelper {
  // 1. 普卡/普通会员: 翡翠石绿 (#0D9488)
  static const MemberLevelStyle regular = MemberLevelStyle(
    levelCode: 'REGULAR',
    levelName: '普卡会员',
    primaryColor: Color(0xFF0D9488),
    badgeTextColor: Color(0xFF0F766E),
    badgeBgColor: Color(0xFFCCFBF1),
    borderColor: Color(0xFF99F6E4),
    icon: Icons.verified_user_outlined,
    isDarkCard: false,
    cardGradient: [Color(0xFF0D9488), Color(0xFF14B8A6)],
  );

  // 2. 荣耀银卡: 月华钛银 / 雅致流银 (#475569 / #64748B) - 极具金属质感的月华钛银色调，告别偏色
  static const MemberLevelStyle silver = MemberLevelStyle(
    levelCode: 'SILVER',
    levelName: '荣耀银卡',
    primaryColor: Color(0xFF475569),
    badgeTextColor: Color(0xFF1E293B),
    badgeBgColor: Color(0xFFF1F5F9),
    borderColor: Color(0xFFCBD5E1),
    icon: Icons.shield_rounded,
    isDarkCard: false,
    cardGradient: [Color(0xFF475569), Color(0xFF64748B)],
  );

  // 3. 黄金VIP卡: 璀璨琥珀赤金 (#D97706)
  static const MemberLevelStyle gold = MemberLevelStyle(
    levelCode: 'GOLD',
    levelName: '黄金VIP卡',
    primaryColor: Color(0xFFD97706),
    badgeTextColor: Color(0xFF92400E),
    badgeBgColor: Color(0xFFFEF3C7),
    borderColor: Color(0xFFFCD34D),
    icon: Icons.stars_rounded,
    isDarkCard: false,
    cardGradient: [Color(0xFFD97706), Color(0xFFFBBF24)],
  );

  // 4. VIP尊享卡: 玫瑰石榴红 (#DB2777)
  static const MemberLevelStyle vip = MemberLevelStyle(
    levelCode: 'VIP',
    levelName: 'VIP尊享卡',
    primaryColor: Color(0xFFDB2777),
    badgeTextColor: Color(0xFF9D174D),
    badgeBgColor: Color(0xFFFDF2F8),
    borderColor: Color(0xFFFBCFE8),
    icon: Icons.card_membership_rounded,
    isDarkCard: false,
    cardGradient: [Color(0xFFDB2777), Color(0xFFF472B6)],
  );

  // 5. 至尊白金卡: 皇家紫晶 (#7C3AED)
  static const MemberLevelStyle platinum = MemberLevelStyle(
    levelCode: 'PLATINUM',
    levelName: '至尊白金卡',
    primaryColor: Color(0xFF7C3AED),
    badgeTextColor: Color(0xFF5B21B6),
    badgeBgColor: Color(0xFFEDE9FE),
    borderColor: Color(0xFFC4B5FD),
    icon: Icons.diamond_rounded,
    isDarkCard: false,
    cardGradient: [Color(0xFF7C3AED), Color(0xFFA855F7)],
  );

  // 6. 黑钻至尊卡: 曜石黑金底 + 烫金边框 (#0F172A / #F59E0B)
  static const MemberLevelStyle blackDiamond = MemberLevelStyle(
    levelCode: 'DIAMOND',
    levelName: '黑钻至尊卡',
    primaryColor: Color(0xFFF59E0B),
    badgeTextColor: Color(0xFFFEF3C7),
    badgeBgColor: Color(0xFF0F172A),
    borderColor: Color(0xFFF59E0B),
    icon: Icons.workspace_premium_rounded,
    isDarkCard: true,
    cardGradient: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );

  /// 统一等级晋升阶梯规则明细
  static const List<MemberLevelRule> standardRules = [
    MemberLevelRule(
      levelCode: 'REGULAR',
      levelName: '普卡会员',
      threshold: 0,
      discount: '无折扣 (100%)',
      discountRate: 1.0,
      privileges: '进店建档、海马体偏好常态记忆、消费基础积分',
    ),
    MemberLevelRule(
      levelCode: 'SILVER',
      levelName: '荣耀银卡',
      threshold: 300,
      discount: '服务95折 / 商品98折',
      discountRate: 0.95,
      privileges: '服务95折、生日月享50元抵用券、双倍积分日',
    ),
    MemberLevelRule(
      levelCode: 'GOLD',
      levelName: '黄金VIP卡',
      threshold: 800,
      discount: '服务90折 / 商品95折',
      discountRate: 0.90,
      privileges: '服务9折、免排队预约优先通道、生日免费专属体验',
    ),
    MemberLevelRule(
      levelCode: 'VIP',
      levelName: 'VIP尊享卡',
      threshold: 1200,
      discount: '服务88折 / 商品92折',
      discountRate: 0.88,
      privileges: '服务88折、专属金牌技师优先点单、节日私享定制礼盒',
    ),
    MemberLevelRule(
      levelCode: 'PLATINUM',
      levelName: '至尊白金卡',
      threshold: 2000,
      discount: '服务85折 / 商品90折',
      discountRate: 0.85,
      privileges: '全场85折、专属私享包间、免费携1位亲友享同折',
    ),
    MemberLevelRule(
      levelCode: 'DIAMOND',
      levelName: '黑钻至尊卡',
      threshold: 3500,
      discount: '服务80折 / 商品85折',
      discountRate: 0.80,
      privileges: '全场8折、总监技师免服务费、终身顶格尊崇待遇',
    ),
  ];

  /// 获取下一等级目标 (已是黑钻返回 null)
  static MemberLevelRule? getNextRule(int points) {
    for (final r in standardRules) {
      if (r.threshold > points) {
        return r;
      }
    }
    return null;
  }

  /// 计算距下一级差多少积分/经验
  static int getPointsToNext(int points) {
    final next = getNextRule(points);
    if (next == null) return 0;
    return (next.threshold - points).clamp(0, 999999);
  }

  /// 计算等级成长进度比率 (0.0 ~ 1.0)
  static double getProgressRatio(int points) {
    final next = getNextRule(points);
    if (next == null) return 1.0;
    int currentThresh = 0;
    for (int i = standardRules.length - 1; i >= 0; i--) {
      if (points >= standardRules[i].threshold) {
        currentThresh = standardRules[i].threshold;
        break;
      }
    }
    final range = next.threshold - currentThresh;
    if (range <= 0) return 1.0;
    return ((points - currentThresh) / range).clamp(0.0, 1.0);
  }

  /// 根据后端返回的 level 或 levelName 解析匹配等级视觉方案
  static MemberLevelStyle getStyle(String? levelOrName) {
    if (levelOrName == null) return regular;
    final name = levelOrName.trim().toUpperCase();

    // 黑钻 / 黑金 / 至尊 / 钻石 / DIAMOND / BLACK_GOLD
    if (name.contains('黑钻') ||
        name.contains('黑金') ||
        name.contains('至尊') ||
        name.contains('钻') ||
        name.contains('DIAMOND') ||
        name.contains('BLACK_GOLD') ||
        name.contains('BLACK')) {
      return blackDiamond;
    }

    // 铂金 / 紫晶 / 白金 / PLATINUM
    if (name.contains('铂金') ||
        name.contains('紫晶') ||
        name.contains('白金') ||
        name.contains('紫金') ||
        name.contains('PLATINUM')) {
      return platinum;
    }

    // VIP尊享卡 / VIP
    if (name.contains('VIP') || name.contains('尊享')) {
      return vip;
    }

    // 黄金 / 金卡 / GOLD
    if (name.contains('黄金') ||
        name.contains('金卡') ||
        name.contains('金') ||
        name.contains('GOLD')) {
      return gold;
    }

    // 银卡 / 白银 / 银 / SILVER
    if (name.contains('银卡') ||
        name.contains('白银') ||
        name.contains('银') ||
        name.contains('SILVER')) {
      return silver;
    }

    // 默认普卡/普通会员 (翡翠石绿)
    return regular;
  }
}

/// 等级规则实体
class MemberLevelRule {
  final String levelCode;
  final String levelName;
  final int threshold;
  final String discount;
  final double discountRate;
  final String privileges;

  const MemberLevelRule({
    required this.levelCode,
    required this.levelName,
    required this.threshold,
    required this.discount,
    required this.discountRate,
    required this.privileges,
  });
}

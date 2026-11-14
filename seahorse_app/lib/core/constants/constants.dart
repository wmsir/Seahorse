import 'package:flutter/material.dart';

/// 行业类型枚举
enum IndustryType {
  beauty('BEAUTY', '美业造型', '💇‍♀️', '包厢/工位'),
  footSpa('FOOT_SPA', '足疗推拿SPA', '🦶', '养生包厢'),
  restaurant('RESTAURANT', '融合餐饮', '🍲', '就餐包厢/卡座'),
  auto('AUTO', '汽车养护', '🚗', '作业工位'),
  retail('RETAIL', '名品轻奢', '🛍️', '展位/专柜'),
  teaHouse('TEA_HOUSE', '茗茶空间', '🍵', '雅座/茶室'),
  pet('PET', '萌宠洗护', '🐾', '洗护工位');

  final String code;
  final String label;
  final String emoji;
  final String defaultSpaceAlias;

  const IndustryType(this.code, this.label, this.emoji, this.defaultSpaceAlias);

  static IndustryType fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized == 'DINING') return IndustryType.restaurant;
    if (normalized == 'AUTO_SERVICE' || normalized == 'AUTOSERVICE') return IndustryType.auto;
    if (normalized == 'FOOTSPA') return IndustryType.footSpa;
    if (normalized == 'TEAHOUSE') return IndustryType.teaHouse;
    for (var item in values) {
      if (item.code == normalized) return item;
    }
    return IndustryType.beauty;
  }
}

/// 空间/包厢/工位状态
enum SpaceStatus {
  idle('IDLE', '空闲可用', Color(0xFF10B981), Color(0xFFD1FAE5)),
  occupied('OCCUPIED', '在场服务中', Color(0xFF3B82F6), Color(0xFFDBEAFE)),
  dirty('DIRTY', '待清台复位', Color(0xFFF59E0B), Color(0xFFFEF3C7)),
  maintenance('MAINTENANCE', '维护停用', Color(0xFF6B7280), Color(0xFFF3F4F6));

  final String code;
  final String label;
  final Color primaryColor;
  final Color backgroundColor;

  const SpaceStatus(this.code, this.label, this.primaryColor, this.backgroundColor);

  static SpaceStatus fromCode(String code) {
    for (var item in values) {
      if (item.code == code) return item;
    }
    return SpaceStatus.idle;
  }
}

/// 预约状态
enum AppointmentStatus {
  pending('PENDING', '待到店', Color(0xFFF59E0B), Color(0xFFFEF3C7)),
  serving('SERVING', '服务中', Color(0xFF3B82F6), Color(0xFFDBEAFE)),
  completed('COMPLETED', '已完成', Color(0xFF10B981), Color(0xFFD1FAE5)),
  cancelled('CANCELLED', '已取消', Color(0xFF9CA3AF), Color(0xFFF3F4F6));

  final String code;
  final String label;
  final Color color;
  final Color bgColor;

  const AppointmentStatus(this.code, this.label, this.color, this.bgColor);

  static AppointmentStatus fromCode(String code) {
    for (var item in values) {
      if (item.code == code) return item;
    }
    return AppointmentStatus.pending;
  }
}

/// 支付方式
enum PaymentMethod {
  memberCard('MEMBER_CARD', '会员储值卡划扣', Icons.credit_card, Color(0xFFD97706)),
  timesCard('TIMES_CARD', '次卡/期限卡扣次', Icons.confirmation_num_outlined, Color(0xFF8B5CF6)),
  wechat('WECHAT', '微信扫码支付', Icons.chat_bubble_outline, Color(0xFF059669)),
  alipay('ALIPAY', '支付宝扫码付', Icons.account_balance_wallet_outlined, Color(0xFF2563EB)),
  cash('CASH', '现金/记账核销', Icons.payments_outlined, Color(0xFF4B5563));

  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const PaymentMethod(this.code, this.label, this.icon, this.color);

  static PaymentMethod fromCode(String? code) {
    if (code == null || code.isEmpty) return PaymentMethod.wechat;
    switch (code.trim().toUpperCase()) {
      case 'MEMBER_CARD':
      case 'STORED_VALUE':
        return PaymentMethod.memberCard;
      case 'TIMES_CARD':
      case 'TIME_CARD':
        return PaymentMethod.timesCard;
      case 'ALIPAY':
        return PaymentMethod.alipay;
      case 'CASH':
      case 'UNION_PAY':
        return PaymentMethod.cash;
      case 'WECHAT':
      default:
        return PaymentMethod.wechat;
    }
  }
}

/// 全局品牌主题颜色规范
class AppColors {
  // 海马智慧品牌双核色系：Apple深海翠绿 (对齐 FWPT 统一平台规范) 与 东方会员金
  static const Color primary = Color(0xFF0D9488); // 翡翠海青绿 (品牌主色)
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF0F766E);

  static const Color gold = Color(0xFFD97706); // 东方尊享会员金
  static const Color goldLight = Color(0xFFFBBF24);
  static const Color goldDark = Color(0xFFB45309);

  static const Color secondary = Color(0xFF1E293B); // 深板岩蓝
  static const Color accent = Color(0xFF0071E3); // Apple 湛蓝

  // 状态色
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0284C7);

  // 背景与表面 (Apple Canvas 规范)
  static const Color background = Color(0xFFF5F5F7); // Apple 经典底色
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color cardDark = Color(0xFF0F172A);

  // 文字颜色
  static const Color textPrimary = Color(0xFF1D1D1F); // Apple 深灰近黑
  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color textMuted = Color(0xFF86868B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
}

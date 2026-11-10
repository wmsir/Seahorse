import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformInfoUtils {
  /// 官方统一网站
  static const String officialWebsite = 'fwpt.cn';
  static const String officialWebsiteUrl = 'https://fwpt.cn';
  static const String officialName = '海马连锁门店智能管家';

  /// 动态识别当前宿主系统平台名称
  static String getPlatformName() {
    if (kIsWeb) {
      return 'Web 浏览器端';
    }
    try {
      if (Platform.isAndroid) {
        return 'Android 安卓版';
      } else if (Platform.isIOS) {
        return 'iOS 苹果版';
      } else if (Platform.isWindows) {
        return 'Windows 桌面版';
      } else if (Platform.isMacOS) {
        return 'macOS 桌面版';
      } else if (Platform.isLinux) {
        return 'Linux 桌面版';
      } else if (Platform.isFuchsia) {
        return 'Fuchsia 版';
      }
    } catch (_) {}

    return 'HarmonyOS NEXT 鸿蒙版';
  }

  /// 动态获取平台专属版本字符串（严禁跨平台错标）
  static String getFullVersionString({String version = '1.0.0'}) {
    final platform = getPlatformName();
    return 'Seahorse Store v$version ($platform 正式版)';
  }

  /// 平台徽章简称
  static String getPlatformBadge() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
    } catch (_) {}
    return 'HarmonyOS';
  }
}

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 移动端重要通知提示音乐、语音合成 (TTS) 与震动服务
/// 联动 Android 原生系统通知旋律 (RingtoneManager)、和弦声响、系统级语音播报与触感反馈
class SoundService {
  static const MethodChannel _channel = MethodChannel('com.seahorse.app/scanner_sound');

  /// 播放特别重要通知到达专属提示音乐与震动
  static Future<void> playImportantNoticeSound() async {
    try {
      await _channel.invokeMethod('playImportantNoticeSound');
    } catch (e) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }

    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// 播放新订单出单专属提示音与震动
  static Future<void> playOrderAlertSound() async {
    try {
      await _channel.invokeMethod('playOrderAlertSound');
    } catch (e) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }

    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// 调用原生 TextToSpeech 进行系统级中文语音大声朗读 (播报桌号、菜名、服务)
  static Future<void> speakText(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _channel.invokeMethod('speakText', {'text': text.trim()});
    } catch (e) {
      // ignore
    }
  }

  /// 检查某条重要通知是否已播放过提醒音，若未播放则播放并标记已播
  static Future<bool> playIfNewUrgentNotice(String noticeId, {String? broadcastText}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final playedKey = 'played_urgent_notice_$noticeId';
      final hasPlayed = prefs.getBool(playedKey) ?? false;
      if (!hasPlayed) {
        await playImportantNoticeSound();
        if (broadcastText != null && broadcastText.trim().isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 350), () {
            speakText(broadcastText.trim());
          });
        }
        await prefs.setBool(playedKey, true);
        return true;
      }
      return false;
    } catch (e) {
      await playImportantNoticeSound();
      return true;
    }
  }
}


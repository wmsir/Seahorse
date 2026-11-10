import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import 'sound_service.dart';
import 'notice_service.dart';

class ServiceCallItem {
  final String id;
  final String spaceName;
  final String spaceCode;
  final String serviceType;
  final String createTime;
  final String? notes;

  ServiceCallItem({
    required this.id,
    required this.spaceName,
    required this.spaceCode,
    required this.serviceType,
    required this.createTime,
    this.notes,
  });

  factory ServiceCallItem.fromJson(Map<String, dynamic> json) {
    return ServiceCallItem(
      id: json['id']?.toString() ?? '',
      spaceName: json['spaceName']?.toString() ?? '包厢',
      spaceCode: json['spaceCode']?.toString() ?? '',
      serviceType: json['serviceType']?.toString() ?? '呼叫服务',
      createTime: json['createTime']?.toString() ?? '',
      notes: json['notes']?.toString(),
    );
  }
}

class OrderNotificationItem {
  final String id;
  final String spaceName;
  final String spaceCode;
  final int itemsCount;
  final double totalAmount;
  final String itemNamesSummary;
  final String broadcastText;
  final String createTime;

  OrderNotificationItem({
    required this.id,
    required this.spaceName,
    required this.spaceCode,
    required this.itemsCount,
    required this.totalAmount,
    required this.itemNamesSummary,
    required this.broadcastText,
    required this.createTime,
  });

  factory OrderNotificationItem.fromJson(Map<String, dynamic> json) {
    return OrderNotificationItem(
      id: json['id']?.toString() ?? '',
      spaceName: json['spaceName']?.toString() ?? '包厢',
      spaceCode: json['spaceCode']?.toString() ?? '',
      itemsCount: int.tryParse(json['itemsCount']?.toString() ?? '1') ?? 1,
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      itemNamesSummary: json['itemNamesSummary']?.toString() ?? '点单品项',
      broadcastText: json['broadcastText']?.toString() ?? '',
      createTime: json['createTime']?.toString() ?? '',
    );
  }
}

/// 移动 APP 全局呼叫服务与新订单语音出单轮询监听引擎
class NotificationPollService {
  static final NotificationPollService _instance = NotificationPollService._internal();
  factory NotificationPollService() => _instance;
  NotificationPollService._internal() {
    _loadBroadcastCounts();
  }

  final ApiClient _client = ApiClient();
  Timer? _timer;
  bool _isRunning = false;
  int _pollTicks = 0;

  // 记录每个通知 ID 已播报的次数 (持久化存储于 LocalStorage，APP 重启绝不重播)
  final Map<String, int> _broadcastCounts = <String, int>{};

  // 租户/店长在 Web 端的播报次数配置 (默认 1 次，支持 1~5 次)
  int _targetRepeatCount = 1;
  int get targetRepeatCount => _targetRepeatCount;

  // 门店规章制度与运营规范轮询相关
  final NoticeService _noticeService = NoticeService();
  final Set<String> _knownNoticeIds = <String>{};
  bool _isNoticeInitLoaded = false;

  // 回调通知外部 UI
  Function(String title, String message)? onAlertCallback;
  Function(StoreNoticeModel notice)? onNoticeCallback;

  void _loadBroadcastCounts() {
    try {
      final raw = LocalStorage.getString('seahorse_broadcast_counts');
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        decoded.forEach((key, val) {
          if (val is num) {
            _broadcastCounts[key] = val.toInt();
          }
        });
        debugPrint('📦 [NotificationPollService] 已恢复历史语音播报记录: ${_broadcastCounts.length} 条');
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationPollService] 读取播报历史记录异常: $e');
    }
    _loadKnownNoticeIds();
  }

  void _loadKnownNoticeIds() {
    try {
      final raw = LocalStorage.getString('seahorse_known_notice_ids');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        for (final id in decoded) {
          _knownNoticeIds.add(id.toString());
        }
        debugPrint('📜 [NotificationPollService] 已恢复历史规章制度记录: ${_knownNoticeIds.length} 条');
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationPollService] 读取已知公告历史异常: $e');
    }
  }

  Future<void> _saveKnownNoticeIds() async {
    try {
      final list = _knownNoticeIds.toList();
      if (list.length > 200) {
        list.removeRange(0, list.length - 200);
      }
      await LocalStorage.setString('seahorse_known_notice_ids', jsonEncode(list));
    } catch (e) {
      debugPrint('⚠️ [NotificationPollService] 持久化已知公告失败: $e');
    }
  }

  Future<void> _saveBroadcastCounts() async {
    try {
      // 保持最多 300 条最新记录，防止历史记录无限增大
      if (_broadcastCounts.length > 300) {
        final keys = _broadcastCounts.keys.toList();
        final removeCount = keys.length - 150;
        for (int i = 0; i < removeCount; i++) {
          _broadcastCounts.remove(keys[i]);
        }
      }
      await LocalStorage.setString('seahorse_broadcast_counts', jsonEncode(_broadcastCounts));
    } catch (e) {
      debugPrint('⚠️ [NotificationPollService] 持久化播报历史失败: $e');
    }
  }

  /// 同步服务端配置的语音播报重复次数 (1~5 次)
  Future<void> fetchVoiceRepeatConfig() async {
    try {
      final res = await _client.dio.get('/notification/config');
      if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
        final cfg = res.data['data'];
        final count = cfg['voiceBroadcastRepeatCount'];
        if (count is num && count >= 1 && count <= 5) {
          _targetRepeatCount = count.toInt();
          debugPrint('📢 [NotificationPollService] 语音播报策略已同步: 重复 $_targetRepeatCount 次');
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [NotificationPollService] 使用默认语音播报次数: $_targetRepeatCount');
    }
  }

  /// 启动轮询 (默认每 4 秒查询一次)
  void startPolling({String storeId = 'S001'}) {
    if (_isRunning) return;
    _isRunning = true;
    _pollTicks = 0;
    fetchVoiceRepeatConfig();
    checkAlerts(storeId: storeId);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _pollTicks++;
      // 每 15 次轮询 (约 60 秒) 重新同步一次策略配置
      if (_pollTicks % 15 == 0) {
        fetchVoiceRepeatConfig();
      }
      checkAlerts(storeId: storeId);
    });
    debugPrint('🔔 [NotificationPollService] 移动APP强提醒与语音报单服务已启动 (门店: $storeId)');
  }

  /// 停止轮询
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// 手动或定时执行巡检
  Future<void> checkAlerts({String storeId = 'S001'}) async {
    // 1. 检查包厢呼叫服务
    try {
      final res = await _client.dio.get(
        '/space/service-calls',
        queryParameters: {'storeId': storeId, 'status': 'PENDING', 'limit': 20},
      );
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data['data'];
        if (list is List) {
          for (final item in list) {
            final call = ServiceCallItem.fromJson(item as Map<String, dynamic>);
            final count = _broadcastCounts[call.id] ?? 0;
            if (count < _targetRepeatCount) {
              _broadcastCounts[call.id] = count + 1;
              _saveBroadcastCounts();
              _handleNewServiceCall(call, repeatIndex: count + 1);
            }
          }
        }
      }
    } catch (_) {}

    // 2. 检查新订单出餐与语音报单 (报出菜品、服务名)
    try {
      final res = await _client.dio.get(
        '/space/order-notifications',
        queryParameters: {'storeId': storeId, 'status': 'PENDING', 'limit': 20},
      );
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data['data'];
        if (list is List) {
          for (final item in list) {
            final order = OrderNotificationItem.fromJson(item as Map<String, dynamic>);
            final count = _broadcastCounts[order.id] ?? 0;
            if (count < _targetRepeatCount) {
              _broadcastCounts[order.id] = count + 1;
              _saveBroadcastCounts();
              _handleNewOrderNotification(order, repeatIndex: count + 1);
            }
          }
        }
      }
    } catch (_) {}

    // 3. 检查门店最新规章制度与日常公告 (全端实时推送强提醒，无需手动下拉刷新)
    try {
      final notices = await _noticeService.getStoreNotices(storeId);
      if (notices.isNotEmpty) {
        if (!_isNoticeInitLoaded && _knownNoticeIds.isEmpty) {
          // 首次冷启动时将当前全部历史公告记为已知，避免初次开启弹窗刷屏
          for (final n in notices) {
            _knownNoticeIds.add(n.id);
          }
          await _saveKnownNoticeIds();
          _isNoticeInitLoaded = true;
        } else {
          _isNoticeInitLoaded = true;
          for (final notice in notices) {
            if (!_knownNoticeIds.contains(notice.id)) {
              _knownNoticeIds.add(notice.id);
              await _saveKnownNoticeIds();
              _handleNewStoreNotice(notice);
            }
          }
        }
      }
    } catch (_) {}
  }

  /// 处理新规章制度与运营规范发布 (响铃 + 语音播报 + 浮层弹窗通知)
  void _handleNewStoreNotice(StoreNoticeModel notice) {
    if (notice.playMusic || notice.isUrgent) {
      SoundService.playImportantNoticeSound();
      Future.delayed(const Duration(milliseconds: 350), () {
        SoundService.speakText('特急重要通知提醒：${notice.title}');
      });
    } else {
      SoundService.playImportantNoticeSound();
      Future.delayed(const Duration(milliseconds: 350), () {
        SoundService.speakText('请注意，门店发布了最新规章制度：${notice.title}');
      });
    }

    if (onNoticeCallback != null) {
      onNoticeCallback!(notice);
    }
  }

  /// 处理呼叫管家服务 (响铃 + 语音播报 + 震动)
  void _handleNewServiceCall(ServiceCallItem call, {int repeatIndex = 1}) {
    SoundService.playImportantNoticeSound();
    Future.delayed(const Duration(milliseconds: 300), () {
      SoundService.speakText('请注意，${call.spaceName}呼叫${call.serviceType}');
    });
    if (onAlertCallback != null && repeatIndex == 1) {
      onAlertCallback!(
        '🛎️ 包厢呼叫：${call.serviceType}',
        '【${call.spaceName} (${call.spaceCode})】呼叫 ${call.serviceType}，请及时处理！',
      );
    }
  }

  /// 处理新订单 (响铃 + 语音大声朗读具体菜名/服务名 + 震动)
  void _handleNewOrderNotification(OrderNotificationItem order, {int repeatIndex = 1}) {
    SoundService.playOrderAlertSound();
    Future.delayed(const Duration(milliseconds: 350), () {
      final text = order.broadcastText.isNotEmpty
          ? order.broadcastText
          : '请注意，${order.spaceName}新下单：${order.itemNamesSummary}，共${order.itemsCount}项，请及时服务出餐！';
      SoundService.speakText(text);
    });
    if (onAlertCallback != null && repeatIndex == 1) {
      onAlertCallback!(
        '🍲 新订单出单：${order.spaceName}',
        '【${order.spaceName}】新下单：${order.itemNamesSummary} (￥${order.totalAmount.toStringAsFixed(2)})',
      );
    }
  }

  /// 标记呼叫已处理
  Future<void> markServiceCallHandled(String id) async {
    try {
      await _client.dio.post('/space/service-calls/$id/handle');
    } catch (_) {}
  }

  /// 标记订单已受理出餐
  Future<void> markOrderHandled(String id) async {
    try {
      await _client.dio.post('/space/order-notifications/$id/handle');
    } catch (_) {}
  }
}

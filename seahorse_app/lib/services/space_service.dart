import '../core/constants/constants.dart';
import '../core/network/api_client.dart';
import '../models/space_model.dart';
import '../models/product_model.dart';
class SpaceService {
  final ApiClient _client = ApiClient();
  final Map<String, List<SpaceModel>> _cachedSpaces = {};

  Future<List<SpaceModel>> getSpaces(String storeId) async {
    try {
      final response = await _client.dio.get('/space/list', queryParameters: {'storeId': storeId});
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List && list.isNotEmpty) {
          final spaces = list.map((e) => SpaceModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();

          // 关联活跃服务会话 (Active Sessions)，填充当前顾客与消费金额
          try {
            final activeSessionsResp = await _client.dio.get('/session/active-list');
            if (activeSessionsResp.statusCode == 200 && activeSessionsResp.data != null) {
              final rawSessions = activeSessionsResp.data;
              final sessionList = (rawSessions is Map && rawSessions.containsKey('data')) ? rawSessions['data'] : rawSessions;
              if (sessionList is List) {
                for (var sess in sessionList) {
                  final sMap = Map<String, dynamic>.from(sess as Map);
                  final statusStr = sMap['status']?.toString();
                  if (statusStr == 'CLOSED' || statusStr == 'SETTLED_WAIT_CLEAN') {
                    continue;
                  }
                  final spaceId = sMap['spaceId'];
                  final matchIndex = spaces.indexWhere((s) => s.id == spaceId);
                  if (matchIndex != -1) {
                    final target = spaces[matchIndex];
                    target.status = SpaceStatus.occupied;
                    target.currentSessionId = (sMap['id'] as num?)?.toInt();
                    target.currentCustomerName = sMap['customerName'];
                    String? parsedTech = sMap['technicianName']?.toString();
                    if ((parsedTech == null || parsedTech.trim().isEmpty || parsedTech == '专职技师') && sMap['notes'] != null) {
                      final notesStr = sMap['notes'].toString();
                      if (notesStr.contains('|')) {
                        final p = notesStr.split('|')[0].trim();
                        if (p.isNotEmpty) parsedTech = p;
                      } else if (notesStr.trim().isNotEmpty) {
                        parsedTech = notesStr.trim();
                      }
                    }
                    if (parsedTech == null || parsedTech.trim().isEmpty) {
                      parsedTech = target.currentTechnicianName;
                    }
                    if (parsedTech == null || parsedTech.trim().isEmpty) {
                      parsedTech = '专职技师';
                    }
                    target.currentTechnicianName = parsedTech;
                    target.currentBillAmount = (sMap['totalAmount'] ?? 0.0).toDouble();
                    if (sMap['itemCount'] != null) {
                      target.currentItemCount = (sMap['itemCount'] as num).toInt();
                    }
                    if (sMap['startTime'] != null) {
                      target.serviceStartTime = DateTime.tryParse(sMap['startTime']);
                    }
                  }
                }
              }
            }
          } catch (_) {}

          _cachedSpaces[storeId] = spaces;
          return spaces;
        }
      }
    } catch (e) {
      print('SpaceService getSpaces from server: $e');
    }

    return _cachedSpaces[storeId] ?? [];
  }

  /// 开台入座
  Future<bool> openSession({
    required String storeId,
    required int spaceId,
    required String customerName,
    required String phone,
    required String technicianName,
    required String serviceItemName,
    required double servicePrice,
    int? serviceProductId,
    int peopleCount = 1,
  }) async {
    final hasInitialItem = serviceProductId != null && serviceProductId > 0 && serviceItemName.trim().isNotEmpty;
    final list = _cachedSpaces[storeId] ?? [];
    final index = list.indexWhere((s) => s.id == spaceId);
    if (index != -1) {
      final space = list[index];
      space.status = SpaceStatus.occupied;
      space.currentSessionId = DateTime.now().millisecondsSinceEpoch;
      space.currentCustomerName = customerName;
      space.currentCustomerPhone = phone;
      space.currentTechnicianName = technicianName;
      space.serviceStartTime = DateTime.now();
      space.currentBillAmount = hasInitialItem ? servicePrice : 0.0;
      space.currentItemCount = hasInitialItem ? 1 : 0;
      _cachedSpaces[storeId] = list;
    }

    try {
      final res = await _client.dio.post('/session/open', data: {
        'spaceId': spaceId,
        'customerName': customerName,
        'customerPhone': phone,
        'guestCount': peopleCount,
        'notes': serviceItemName.trim().isNotEmpty ? '$technicianName | $serviceItemName' : technicianName,
      });

      if (res.statusCode == 200 && res.data != null) {
        final raw = res.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        final sessionId = data is Map ? data['id'] : null;
        if (sessionId != null) {
          final intSessionId = (sessionId as num).toInt();
          if (index != -1) {
            list[index].currentSessionId = intSessionId;
          }
          if (hasInitialItem) {
            try {
              await _client.dio.post('/session/append', data: {
                'sessionId': intSessionId,
                'items': [
                  {
                    'productId': serviceProductId,
                    'quantity': 1,
                    'modifiers': serviceItemName,
                    'performers': [
                      {'role': 'PRIMARY', 'technicianName': technicianName}
                    ],
                  }
                ]
              });
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      print('SpaceService openSession API note: $e');
    }

    return true;
  }

  /// 翻台清扫消毒复位 -> 恢复空闲
  Future<bool> cleanAndResetSpace(String storeId, int spaceId) async {
    final list = _cachedSpaces[storeId] ?? [];
    final index = list.indexWhere((s) => s.id == spaceId);
    if (index != -1) {
      final space = list[index];
      space.status = SpaceStatus.idle;
      space.currentSessionId = null;
      space.currentCustomerName = null;
      space.currentCustomerPhone = null;
      space.currentTechnicianName = null;
      space.serviceStartTime = null;
      space.currentBillAmount = 0.0;
      space.currentItemCount = 0;
      _cachedSpaces[storeId] = list;
    }

    try {
      await _client.dio.post('/space/$spaceId/reset');
    } catch (e) {
      print('SpaceService cleanAndResetSpace API note: $e');
    }

    return true;
  }

  /// 更新工位/包厢状态 (如设为维修/待清台)
  Future<bool> updateSpaceStatus(String storeId, int spaceId, SpaceStatus newStatus) async {
    final list = _cachedSpaces[storeId] ?? [];
    final index = list.indexWhere((s) => s.id == spaceId);
    if (index != -1) {
      list[index].status = newStatus;
      _cachedSpaces[storeId] = list;
    }

    try {
      await _client.dio.post('/space/$spaceId/status', queryParameters: {'status': newStatus.code});
    } catch (e) {
      print('SpaceService updateSpaceStatus API note: $e');
    }

    return true;
  }

  /// 为包厢/工位追加消费项目（支持单品或批量一次性提交）
  Future<bool> appendItem({
    required String storeId,
    required int spaceId,
    required ProductModel product,
    int quantity = 1,
    String? modifiers,
    String? technicianName,
  }) {
    return appendItemsBatch(
      storeId: storeId,
      spaceId: spaceId,
      items: [MapEntry(product, quantity)],
      modifiers: modifiers,
      technicianName: technicianName,
    );
  }

  /// 批量追加多个项目（仅发起一次 /session/append 请求，彻底消除 3N 串行请求风暴）
  Future<bool> appendItemsBatch({
    required String storeId,
    required int spaceId,
    required List<MapEntry<ProductModel, int>> items,
    String? modifiers,
    String? technicianName,
  }) async {
    if (items.isEmpty) return false;
    final list = _cachedSpaces[storeId] ?? [];
    final index = list.indexWhere((s) => s.id == spaceId);
    if (index != -1) {
      final space = list[index];
      for (final entry in items) {
        space.currentBillAmount += (entry.key.price * entry.value);
        space.currentItemCount += entry.value;
      }
      _cachedSpaces[storeId] = list;
    }

    try {
      final space = (index != -1) ? list[index] : null;
      final sessionId = space?.currentSessionId;
      if (sessionId != null) {
        final payloadItems = items.map((entry) {
          final product = entry.key;
          final qty = entry.value;
          return {
            'productId': product.id > 0 ? product.id : 1,
            'quantity': qty,
            'modifiers': (modifiers != null && modifiers.isNotEmpty)
                ? '${product.title} ($modifiers)'
                : product.title,
          };
        }).toList();

        final res = await _client.dio.post('/session/append', data: {
          'sessionId': sessionId,
          'items': payloadItems,
          'operatorType': 'WAITER',
          'operatorName': technicianName ?? space?.currentTechnicianName ?? '服务人员',
        });
        if (res.statusCode == 200 && res.data is Map && res.data['code'] != null && res.data['code'] != 200) {
          return false;
        }
      }
    } catch (e) {
      print('SpaceService appendItemsBatch error: $e');
      return false;
    }

    return true;
  }
}

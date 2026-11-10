import '../core/storage/local_storage.dart';
import '../core/network/api_client.dart';
import '../models/member_model.dart';

class MemberService {
  final ApiClient _client = ApiClient();
  final List<MemberModel> _localMembers = [];

  Future<List<MemberModel>> getMembers({String? query, String? tenantId, String? storeId}) async {
    try {
      final savedTenantId = LocalStorage.getString('seahorse_tenant_id');
      final String curTenantId = (tenantId != null && tenantId.isNotEmpty)
          ? tenantId
          : ((savedTenantId != null && savedTenantId.isNotEmpty) ? savedTenantId : 'T001');

      final savedStoreId = LocalStorage.getString('seahorse_store_id');
      final String curStoreId = (storeId != null && storeId.isNotEmpty)
          ? storeId
          : ((savedStoreId != null && savedStoreId.isNotEmpty) ? savedStoreId : 'S001');

      final Map<String, dynamic> params = {
        'tenantId': curTenantId,
        'storeId': curStoreId,
      };
      if (query != null && query.trim().isNotEmpty) {
        params['query'] = query.trim();
      }

      final response = await _client.dio.get('/member/search', queryParameters: params);
      List<MemberModel> mapped = [];
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          mapped = list.map((e) => MemberModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }

      // 若当前分店未查到会员，仅在同一租户 (curTenantId) 内跨分店查询，严禁使用 tenantId=ALL 跨租户越权！
      if (mapped.isEmpty && (query == null || query.trim().isEmpty)) {
        try {
          final fallbackResp = await _client.dio.get('/member/search', queryParameters: {'tenantId': curTenantId});
          if (fallbackResp.statusCode == 200 && fallbackResp.data != null) {
            final dynamic raw = fallbackResp.data;
            final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
            if (list is List && list.isNotEmpty) {
              mapped = list.map((e) => MemberModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
            }
          }
        } catch (_) {}
      }

      if (mapped.isNotEmpty) {
        _localMembers.clear();
        _localMembers.addAll(mapped);
        return mapped;
      }
    } catch (e) {
      print('MemberService getMembers from server: $e');
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      return _localMembers.where((m) =>
        m.name.toLowerCase().contains(q) ||
        m.phone.contains(q) ||
        m.memberNo.toLowerCase().contains(q)
      ).toList();
    }
    return _localMembers;
  }

  /// 快速新会员建档
  Future<MemberModel> registerMember({
    required String name,
    required String phone,
    String gender = 'MALE',
    double initialBalance = 0.0,
    double initialGift = 0.0,
    String deductMode = 'PROPORTIONAL',
    String levelName = '普卡会员',
    String? storeId,
    String? tenantId,
  }) async {
    final savedTenantId = LocalStorage.getString('seahorse_tenant_id');
    final curTenantId = (tenantId != null && tenantId.isNotEmpty)
        ? tenantId
        : ((savedTenantId != null && savedTenantId.isNotEmpty) ? savedTenantId : 'T001');

    final savedStoreId = LocalStorage.getString('seahorse_store_id');
    final curStoreId = (storeId != null && storeId.isNotEmpty)
        ? storeId
        : ((savedStoreId != null && savedStoreId.isNotEmpty) ? savedStoreId : 'S001');

    final cmd = {
      'name': name,
      'phone': phone,
      'gender': gender,
      'birthday': '2000-01-01',
      'initialPrincipal': initialBalance,
      'initialGift': initialGift,
      'deductMode': deductMode,
      'level': levelName,
      'storeId': curStoreId,
      'tenantId': curTenantId,
    };

    try {
      final response = await _client.dio.post('/member/register', data: cmd);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map) {
          final created = MemberModel.fromJson(Map<String, dynamic>.from(data));
          await getMembers();
          return created;
        }
      }
    } catch (e) {
      print('MemberService registerMember API note: $e');
      rethrow;
    }

    throw Exception('会员建档失败，未收到服务端响应');
  }

  /// 会员卡充值
  Future<bool> recharge(int memberId, double amount, {double bonus = 0.0}) async {
    try {
      final response = await _client.dio.post('/member/recharge', data: {
        'memberId': memberId,
        'principalAmount': amount,
        'giftAmount': bonus,
      });
      if (response.statusCode == 200) {
        await getMembers();
        return true;
      }
    } catch (e) {
      print('MemberService recharge API note: $e');
    }
    return false;
  }

  /// 次卡核销扣减（同步云端与本地）
  Future<bool> deductTimesCard(int memberId, String cardNo) async {
    try {
      await _client.dio.post('/member/time-card/deduct', data: {
        'memberId': memberId,
        'cardNo': cardNo,
        'count': 1,
      });
    } catch (_) {}
    final memberIndex = _localMembers.indexWhere((m) => m.id == memberId);
    if (memberIndex == -1) return false;
    final member = _localMembers[memberIndex];
    final cardIndex = member.timesCards.indexWhere((c) => c.cardNo == cardNo);
    if (cardIndex == -1) return false;
    final card = member.timesCards[cardIndex];
    if (card.remainingCount > 0) {
      card.remainingCount -= 1;
      return true;
    }
    return false;
  }

  /// 修改会员档案资料（手机端与服务端保持一致）
  Future<bool> updateMember(int memberId, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/member/$memberId', data: data);
      if (response.statusCode == 200) {
        await getMembers();
        return true;
      }
    } catch (e) {
      print('MemberService updateMember API error: $e');
    }
    return false;
  }

  /// 获取会员在服务端的历史消费记录与履约流水
  Future<List<Map<String, dynamic>>> getMemberOrders(int memberId) async {
    try {
      final response = await _client.dio.get('/member/$memberId/orders');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      print('MemberService getMemberOrders API error: $e');
    }
    return [];
  }

  /// 调整会员积分
  Future<bool> adjustPoints(int memberId, int delta, String reason) async {
    try {
      final response = await _client.dio.post('/member/$memberId/adjust-points', data: {
        'pointsDelta': delta,
        'reason': reason,
      });
      if (response.statusCode == 200) {
        await getMembers();
        return true;
      }
    } catch (e) {
      print('MemberService adjustPoints API error: $e');
    }
    return false;
  }
}

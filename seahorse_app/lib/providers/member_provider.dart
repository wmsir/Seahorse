import 'package:flutter/material.dart';
import '../core/storage/local_storage.dart';
import '../models/member_model.dart';
import '../services/member_service.dart';

class MemberProvider extends ChangeNotifier {
  final MemberService _service = MemberService();

  List<MemberModel> _members = [];
  List<MemberModel> get members => _members;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _currentStoreId;
  String? get currentStoreId => _currentStoreId;

  String? _currentTenantId;
  String? get currentTenantId => _currentTenantId;

  MemberProvider({bool autoLoad = false}) {
    final hasToken = (LocalStorage.getString('seahorse_token') ?? '').isNotEmpty;
    if (autoLoad || hasToken) {
      loadMembers();
    }
  }

  Future<void> loadMembers({String? query, String? tenantId, String? storeId}) async {
    if (storeId != null && storeId.isNotEmpty) {
      _currentStoreId = storeId;
    }
    if (tenantId != null && tenantId.isNotEmpty) {
      _currentTenantId = tenantId;
    }

    _isLoading = true;
    notifyListeners();

    _searchQuery = query ?? '';
    _members = await _service.getMembers(
      query: query,
      tenantId: _currentTenantId,
      storeId: _currentStoreId,
    );
    _isLoading = false;
    notifyListeners();
  }

  /// 快速更新会员余额（如前台收银划扣或充值即时响应）
  void updateMemberBalance(int memberId, double newBalance) {
    final idx = _members.indexWhere((m) => m.id == memberId);
    if (idx != -1) {
      _members[idx].balance = newBalance;
      notifyListeners();
    }
  }

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
    final m = await _service.registerMember(
      name: name,
      phone: phone,
      gender: gender,
      initialBalance: initialBalance,
      initialGift: initialGift,
      deductMode: deductMode,
      levelName: levelName,
      storeId: storeId ?? _currentStoreId,
      tenantId: tenantId ?? _currentTenantId,
    );
    await loadMembers();
    return m;
  }

  Future<bool> recharge(int memberId, double amount, {double bonus = 0.0}) async {
    final ok = await _service.recharge(memberId, amount, bonus: bonus);
    if (ok) {
      await loadMembers();
    }
    return ok;
  }

  Future<bool> deductTimesCard(int memberId, String cardNo) async {
    final ok = await _service.deductTimesCard(memberId, cardNo);
    if (ok) {
      await loadMembers();
    }
    return ok;
  }

  /// 修改会员资料与信息
  Future<bool> updateMember(int memberId, Map<String, dynamic> data) async {
    final ok = await _service.updateMember(memberId, data);
    if (ok) {
      await loadMembers();
    }
    return ok;
  }

  /// 获取会员消费订单记录
  Future<List<Map<String, dynamic>>> getMemberOrders(int memberId) async {
    return await _service.getMemberOrders(memberId);
  }

  /// 调整会员积分
  Future<bool> adjustPoints(int memberId, int delta, String reason) async {
    final ok = await _service.adjustPoints(memberId, delta, reason);
    if (ok) {
      await loadMembers();
    }
    return ok;
  }
}

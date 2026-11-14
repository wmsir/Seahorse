import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/storage/local_storage.dart';
import '../models/store_model.dart';
import '../services/notification_poll_service.dart';
import '../services/store_service.dart';
import 'space_provider.dart';
import 'member_provider.dart';
import 'cashier_provider.dart';
import 'appointment_provider.dart';

class StoreProvider extends ChangeNotifier {
  final StoreService _storeService = StoreService();

  List<StoreModel> _stores = [];
  List<StoreModel> get stores => _stores;

  StoreModel? _currentStore;
  StoreModel? get currentStore => _currentStore;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String get currentStoreId => _currentStore?.storeId ?? _storeService.getCurrentStoreId();
  String get currentStoreName => _currentStore?.storeName ?? _storeService.getCurrentStoreName();

  String get spaceAlias {
    return _currentStore?.industry.defaultSpaceAlias ?? '养生包厢';
  }

  StoreProvider({bool autoLoad = false}) {
    final hasToken = (LocalStorage.getString('seahorse_token') ?? '').isNotEmpty;
    if (autoLoad || hasToken) {
      loadStores();
    }
  }

  Future<void> loadStores() async {
    _isLoading = true;
    notifyListeners();

    _stores = await _storeService.getStores();
    final savedId = _storeService.getCurrentStoreId();
    if (_stores.isNotEmpty) {
      _currentStore = _stores.firstWhere(
        (s) => s.storeId == savedId,
        orElse: () => _stores.first,
      );
      // 保证把当前选中的真实门店与租户持久化存储到本地，确保跨 Provider 与网络拦截器能取得真实 ID
      await _storeService.switchStore(_currentStore!.storeId, _currentStore!.storeName, tenantId: _currentStore!.tenantId);
    } else {
      _currentStore = null;
      _stores = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> switchStore(String storeId, {BuildContext? context}) async {
    if (_stores.isEmpty) return;
    final matched = _stores.firstWhere((s) => s.storeId == storeId, orElse: () => _stores.first);
    _currentStore = matched;
    await _storeService.switchStore(matched.storeId, matched.storeName, tenantId: matched.tenantId);
    NotificationPollService().updateStoreId(matched.storeId);
    notifyListeners();

    if (context != null) {
      reloadAllProviders(context);
    }
  }

  /// 集中级联驱动各个业务 Provider 刷新数据，保证数据与当前门店/租户强一致
  void reloadAllProviders(BuildContext context) {
    final sId = currentStoreId;
    final tId = _currentStore?.tenantId;
    final ind = _currentStore?.industry.code;

    try {
      context.read<SpaceProvider>().loadSpaces(sId);
    } catch (_) {}
    try {
      context.read<MemberProvider>().loadMembers(storeId: sId, tenantId: tId);
    } catch (_) {}
    try {
      context.read<CashierProvider>().loadProducts(storeId: sId);
      context.read<CashierProvider>().loadCategories(industry: ind, storeId: sId, tenantId: tId);
    } catch (_) {}
    try {
      context.read<AppointmentProvider>().loadAppointments(sId);
    } catch (_) {}
  }

  /// 超级管理员代管指定门店
  Future<void> delegateStore(StoreModel store) async {
    _currentStore = store;
    if (!_stores.any((s) => s.storeId == store.storeId)) {
      _stores = [store, ..._stores];
    }
    await _storeService.switchStore(store.storeId, store.storeName, tenantId: store.tenantId);
    NotificationPollService().updateStoreId(store.storeId);
    notifyListeners();
  }

  /// 超级管理员退出代管，清空当前门店
  void exitDelegation() {
    _currentStore = null;
    notifyListeners();
  }
}

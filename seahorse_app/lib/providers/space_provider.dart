import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../models/space_model.dart';
import '../models/product_model.dart';
import '../services/space_service.dart';

class SpaceProvider extends ChangeNotifier {
  final SpaceService _spaceService = SpaceService();

  List<SpaceModel> _spaces = [];
  List<SpaceModel> get spaces => _spaces;

  String _selectedZone = 'ALL';
  String get selectedZone => _selectedZone;

  SpaceStatus? _selectedStatus;
  SpaceStatus? get selectedStatus => _selectedStatus;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 获取当前门店所有楼层区域
  List<String> get availableZones {
    final set = <String>{};
    for (var s in _spaces) {
      if (s.floorZone.isNotEmpty) set.add(s.floorZone);
    }
    return set.toList();
  }

  /// 过滤后的空间列表
  List<SpaceModel> get filteredSpaces {
    return _spaces.where((s) {
      if (_selectedZone != 'ALL' && s.floorZone != _selectedZone) {
        return false;
      }
      if (_selectedStatus != null && s.status != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();
  }

  int get idleCount => _spaces.where((s) => s.status == SpaceStatus.idle).length;
  int get occupiedCount => _spaces.where((s) => s.status == SpaceStatus.occupied).length;
  int get dirtyCount => _spaces.where((s) => s.status == SpaceStatus.dirty).length;
  int get maintenanceCount => _spaces.where((s) => s.status == SpaceStatus.maintenance).length;

  double get occupancyRate {
    if (_spaces.isEmpty) return 0.0;
    return (occupiedCount / _spaces.length) * 100;
  }

  Future<void> loadSpaces(String storeId) async {
    _isLoading = true;
    notifyListeners();

    _spaces = await _spaceService.getSpaces(storeId);
    _isLoading = false;
    notifyListeners();
  }

  void setZone(String zone) {
    _selectedZone = zone;
    notifyListeners();
  }

  void setStatus(SpaceStatus? status) {
    _selectedStatus = status;
    notifyListeners();
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
    final success = await _spaceService.openSession(
      storeId: storeId,
      spaceId: spaceId,
      customerName: customerName,
      phone: phone,
      technicianName: technicianName,
      serviceItemName: serviceItemName,
      servicePrice: servicePrice,
      serviceProductId: serviceProductId,
      peopleCount: peopleCount,
    );
    if (success) {
      await loadSpaces(storeId);
    }
    return success;
  }

  /// 翻台清扫复位
  Future<bool> cleanAndResetSpace(String storeId, int spaceId) async {
    final success = await _spaceService.cleanAndResetSpace(storeId, spaceId);
    if (success) {
      await loadSpaces(storeId);
    }
    return success;
  }

  /// 追加项目
  Future<bool> appendItem({
    required String storeId,
    required int spaceId,
    required ProductModel product,
    int quantity = 1,
    String? modifiers,
    String? technicianName,
  }) async {
    final success = await _spaceService.appendItem(
      storeId: storeId,
      spaceId: spaceId,
      product: product,
      quantity: quantity,
      modifiers: modifiers,
      technicianName: technicianName,
    );
    if (success) {
      await loadSpaces(storeId);
    }
    return success;
  }
}

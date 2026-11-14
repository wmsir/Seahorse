import '../core/storage/local_storage.dart';
import '../core/network/api_client.dart';
import '../models/staff_model.dart';

class StaffRoleInfo {
  final String roleCode;
  final String roleName;
  final String description;
  final bool isCustom;
  final List<String> permissions;
  final List<Map<String, dynamic>> availablePermissions;

  StaffRoleInfo({
    required this.roleCode,
    required this.roleName,
    required this.description,
    this.isCustom = false,
    this.permissions = const [],
    this.availablePermissions = const [],
  });

  factory StaffRoleInfo.fromJson(Map<String, dynamic> json) {
    return StaffRoleInfo(
      roleCode: json['roleCode']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isCustom: json['isCustom'] == true,
      permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      availablePermissions: (json['availablePermissions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

class StaffService {
  final ApiClient _client = ApiClient();
  final List<StaffModel> _cachedStaff = [];
  List<StaffRoleInfo> _cachedRoles = [];

  List<StaffRoleInfo> get defaultStaffRoles => [
    StaffRoleInfo(
      roleCode: 'STORE_MANAGER',
      roleName: '店长 / 运营主管',
      description: '全面统筹日常店务运营、房态调度、技师考勤与客户满意度，拥有门店现场管理最高权限',
      isCustom: false,
      permissions: ['ORDER_WRITE', 'MEMBER_RECHARGE', 'PRICE_MODIFY', 'ROOM_CONTROL', 'STAFF_SCHEDULE', 'PERFORMANCE_VIEW', 'SETTING_VIEW'],
    ),
    StaffRoleInfo(
      roleCode: 'CASHIER',
      roleName: '前台收银员',
      description: '负责到店顾客接待迎宾、前台快速开单结账、会员办卡充值与项目核销',
      isCustom: false,
      permissions: ['ORDER_WRITE', 'MEMBER_RECHARGE', 'PRICE_MODIFY', 'ROOM_CONTROL'],
    ),
    StaffRoleInfo(
      roleCode: 'TECHNICIAN',
      roleName: '技师 / 施工人员 / 手艺人',
      description: '负责一线专业技术服务交付、施工履约、工单执行与个人业绩提成统计',
      isCustom: false,
      permissions: ['ROOM_CONTROL', 'PERFORMANCE_VIEW'],
    ),
    StaffRoleInfo(
      roleCode: 'WAITER',
      roleName: '楼面服务员',
      description: '负责前厅迎宾领位、翻台点单传菜、包厢专属管家服务与环境维系',
      isCustom: false,
      permissions: ['ORDER_WRITE', 'ROOM_CONTROL'],
    ),
  ];

  /// 获取当前商户在浏览器配置的店员权限体系角色列表 (与浏览器 StaffPermissionConfig.vue / roles-permissions 保持完全一致)
  Future<List<StaffRoleInfo>> getStaffRoles({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedRoles.isNotEmpty) {
      return _cachedRoles;
    }
    try {
      final response = await _client.dio.get('/merchant/staff/roles-permissions');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List && list.isNotEmpty) {
          final items = list.map((e) => StaffRoleInfo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          _cachedRoles = items;
          return items;
        }
      }
    } catch (e) {
      print('StaffService getStaffRoles error: $e');
    }
    if (_cachedRoles.isEmpty) {
      _cachedRoles = defaultStaffRoles;
    }
    return _cachedRoles;
  }

  /// 获取当前门店在浏览器配置的组织架构部门与在编在招岗位
  Future<Map<String, dynamic>> getStorePositionsAndDepartments({String? storeId}) async {
    try {
      final curStoreId = storeId ?? LocalStorage.getString('seahorse_store_id') ?? 'S001';
      final response = await _client.dio.get(
        '/space/public/store-detail',
        queryParameters: {'storeId': curStoreId},
      );
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map) {
          final rawDepts = data['departments'];
          final rawPositions = data['positions'];
          final List<String> departments = [];
          if (rawDepts is List) {
            for (var d in rawDepts) {
              if (d != null && d.toString().isNotEmpty) {
                departments.add(d.toString());
              }
            }
          }
          final List<Map<String, dynamic>> positions = [];
          if (rawPositions is List) {
            for (var p in rawPositions) {
              if (p is Map) {
                positions.add(Map<String, dynamic>.from(p));
              }
            }
          }
          return {
            'departments': departments,
            'positions': positions,
          };
        }
      }
    } catch (e) {
      print('StaffService getStorePositionsAndDepartments error: $e');
    }
    return {
      'departments': <String>['店务管理部', '技术服务部', '前台客服部', '楼面服务部'],
      'positions': <Map<String, dynamic>>[],
    };
  }

  Future<List<StaffModel>> getStaffList({String? storeId}) async {
    try {
      final curStoreId = storeId ?? LocalStorage.getString('seahorse_store_id') ?? 'S001';
      final Map<String, dynamic> params = {};
      if (curStoreId.isNotEmpty) {
        params['storeId'] = curStoreId;
      }
      final response = await _client.dio.get('/merchant/staff/list', queryParameters: params);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          final items = list.map((e) => StaffModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          _cachedStaff.clear();
          _cachedStaff.addAll(items);
          return items;
        }
      }
    } catch (e) {
      print('StaffService getStaffList error: $e');
    }
    return _cachedStaff;
  }

  Future<bool> updateStaffStatus(int id, String newStatus) async {
    try {
      final response = await _client.dio.put('/merchant/staff/$id', data: {
        'status': newStatus,
      });
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map && raw['code'] != null && raw['code'] != 200) {
          return false;
        }
        final index = _cachedStaff.indexWhere((s) => s.id == id);
        if (index != -1) {
          _cachedStaff[index].status = newStatus;
        }
        return true;
      }
    } catch (e) {
      print('StaffService updateStaffStatus error: $e');
    }
    return false;
  }

  Future<StaffModel?> createStaff(Map<String, dynamic> data) async {
    try {
      final curStoreId = data['storeId'] ?? LocalStorage.getString('seahorse_store_id') ?? 'S001';
      final payload = Map<String, dynamic>.from(data);
      payload['storeId'] = curStoreId;
      if (payload['defaultCommissionRate'] == null && payload['commissionRate'] != null) {
        payload['defaultCommissionRate'] = payload['commissionRate'];
      }
      final response = await _client.dio.post('/merchant/staff', data: payload);
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final map = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (map is Map) {
          final newStaff = StaffModel.fromJson(Map<String, dynamic>.from(map));
          _cachedStaff.insert(0, newStaff);
          return newStaff;
        }
      }
    } catch (e) {
      print('StaffService createStaff error: $e');
    }
    return null;
  }

  Future<List<StaffModel>> getAuditStaffList({String? storeId, String? status}) async {
    try {
      final response = await _client.dio.get('/merchant/staff/audit-list', queryParameters: {
        if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        if (status != null && status.isNotEmpty) 'status': status,
      });
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          return list.map((e) => StaffModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
    } catch (e) {
      print('StaffService getAuditStaffList error: $e');
    }
    return [];
  }

  Future<bool> approveStaffAudit(int id, {String? postName, double? baseSalary, String? department, String? role}) async {
    try {
      final response = await _client.dio.post('/merchant/staff/audit/$id/approve', data: {
        if (postName != null && postName.isNotEmpty) 'postName': postName,
        if (baseSalary != null) 'baseSalary': baseSalary,
        if (department != null && department.isNotEmpty) 'department': department,
        if (role != null && role.isNotEmpty) 'role': role,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('StaffService approveStaffAudit error: $e');
      return false;
    }
  }

  Future<bool> rejectStaffAudit(int id, {String? reason}) async {
    try {
      final response = await _client.dio.post(
        '/merchant/staff/audit/$id/reject',
        queryParameters: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print('StaffService rejectStaffAudit error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getStaffCommissions({
    int? employeeId,
    String? employeeName,
    String? storeId,
  }) async {
    try {
      final curStoreId = storeId ?? LocalStorage.getString('seahorse_store_id') ?? 'S001';
      final Map<String, dynamic> params = {};
      if (employeeId != null) params['employeeId'] = employeeId;
      if (employeeName != null && employeeName.isNotEmpty) params['employeeName'] = employeeName;
      if (curStoreId.isNotEmpty) params['storeId'] = curStoreId;

      final response = await _client.dio.get('/merchant/staff/commissions', queryParameters: params);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      print('StaffService getStaffCommissions error: $e');
    }
    return [];
  }
}

import '../core/network/api_client.dart';
import '../models/leave_model.dart';
import '../core/storage/local_storage.dart';
import 'package:intl/intl.dart';

class LeaveService {
  final ApiClient _client = ApiClient();

  // 本地/离线容错缓存 (纯净无死数据)
  static final List<LeaveApplicationModel> _localCache = [];

  /// 查询员工请假单据列表
  Future<List<LeaveApplicationModel>> getLeaveList({String? status, String? keyword}) async {
    try {
      final response = await _client.dio.get(
        '/leave/list',
        queryParameters: {
          if (status != null && status != 'ALL') 'status': status,
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          'tenantId': LocalStorage.getString('seahorse_tenant_id') ?? '',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final listData = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (listData is List) {
          final fetched = listData
              .map((item) => LeaveApplicationModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();

          // 合并本地尚未同步到远端的数据
          for (final local in _localCache) {
            if (!fetched.any((r) => r.id == local.id)) {
              fetched.add(local);
            }
          }
          return fetched;
        }
      }
    } catch (e) {
      print('LeaveService getLeaveList API error: $e, using local cache');
    }

    // 离线容错过滤
    return _localCache.where((item) {
      if (status != null && status != 'ALL' && item.status.toUpperCase() != status.toUpperCase()) {
        return false;
      }
      if (keyword != null && keyword.isNotEmpty) {
        final k = keyword.toLowerCase();
        return item.staffName.toLowerCase().contains(k) ||
            item.reason.toLowerCase().contains(k) ||
            item.postName.toLowerCase().contains(k);
      }
      return true;
    }).toList();
  }

  /// 员工发起请假申请
  Future<LeaveApplicationModel> applyLeave({
    required int staffId,
    required String staffName,
    required String phone,
    required String postName,
    required String department,
    required String leaveType,
    required String startTime,
    required String endTime,
    required double totalHours,
    required double totalDays,
    required String reason,
  }) async {
    try {
      final response = await _client.dio.post(
        '/leave/apply',
        data: {
          'staffId': staffId,
          'staffName': staffName,
          'phone': phone,
          'postName': postName,
          'department': department,
          'leaveType': leaveType,
          'startTime': startTime,
          'endTime': endTime,
          'totalHours': totalHours,
          'totalDays': totalDays,
          'reason': reason,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final map = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (map is Map) {
          final created = LeaveApplicationModel.fromJson(Map<String, dynamic>.from(map));
          _localCache.insert(0, created);
          return created;
        }
      }
    } catch (e) {
      print('LeaveService applyLeave API error: $e, using local creation');
    }

    final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final fallback = LeaveApplicationModel(
      id: 'LV-${DateTime.now().millisecondsSinceEpoch}',
      staffId: staffId,
      staffName: staffName,
      phone: phone,
      postName: postName,
      department: department,
      leaveType: leaveType,
      leaveTypeName: _getLeaveTypeName(leaveType),
      startTime: startTime,
      endTime: endTime,
      totalHours: totalHours,
      totalDays: totalDays,
      reason: reason,
      status: 'PENDING',
      applyTime: nowStr,
      currentApprover: '店长/部门主管',
      timeline: [
        AuditTimelineNode(
          stepName: '提交请假申请',
          operator: staffName,
          time: nowStr,
          status: 'SUCCESS',
          comment: reason,
        ),
        AuditTimelineNode(
          stepName: '主管/店长初审',
          operator: '店长',
          time: nowStr,
          status: 'CURRENT',
          comment: '等待审批中',
        ),
      ],
    );
    _localCache.insert(0, fallback);
    return fallback;
  }

  /// 员工撤回/撤销请假申请
  Future<LeaveApplicationModel> revokeLeave({
    required String leaveId,
    required String staffName,
    String? reason,
  }) async {
    try {
      final response = await _client.dio.post(
        '/leave/revoke',
        data: {
          'leaveId': leaveId,
          'reason': reason ?? '员工主动撤回',
          'operator': staffName,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final map = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (map is Map) {
          final updated = LeaveApplicationModel.fromJson(Map<String, dynamic>.from(map));
          _updateLocalItem(updated);
          return updated;
        }
      }
    } catch (e) {
      print('LeaveService revokeLeave API error: $e, using local update');
    }

    final index = _localCache.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final old = _localCache[index];
      final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      final updated = LeaveApplicationModel(
        id: old.id,
        staffId: old.staffId,
        staffName: old.staffName,
        phone: old.phone,
        postName: old.postName,
        department: old.department,
        leaveType: old.leaveType,
        leaveTypeName: old.leaveTypeName,
        startTime: old.startTime,
        endTime: old.endTime,
        totalHours: old.totalHours,
        totalDays: old.totalDays,
        reason: old.reason,
        status: 'REVOKED',
        applyTime: old.applyTime,
        currentApprover: old.currentApprover,
        auditTime: nowStr,
        auditNotes: '员工主动撤回申请',
        timeline: [
          ...old.timeline,
          AuditTimelineNode(
            stepName: '撤回申请',
            operator: staffName,
            time: nowStr,
            status: 'SUCCESS',
            comment: reason ?? '员工撤回申请',
          ),
        ],
      );
      _localCache[index] = updated;
      return updated;
    }
    throw Exception('未找到请假单据');
  }

  /// 员工编辑重新提交请假申请
  Future<LeaveApplicationModel> updateLeave({
    required String leaveId,
    required String leaveType,
    required String startTime,
    required String endTime,
    required double totalHours,
    required double totalDays,
    required String reason,
  }) async {
    try {
      final response = await _client.dio.post(
        '/leave/update',
        data: {
          'leaveId': leaveId,
          'leaveType': leaveType,
          'startTime': startTime,
          'endTime': endTime,
          'totalHours': totalHours,
          'totalDays': totalDays,
          'reason': reason,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final map = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (map is Map) {
          final updated = LeaveApplicationModel.fromJson(Map<String, dynamic>.from(map));
          _updateLocalItem(updated);
          return updated;
        }
      }
    } catch (e) {
      print('LeaveService updateLeave API error: $e, using local update');
    }

    final index = _localCache.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final old = _localCache[index];
      final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      final updated = LeaveApplicationModel(
        id: old.id,
        staffId: old.staffId,
        staffName: old.staffName,
        phone: old.phone,
        postName: old.postName,
        department: old.department,
        leaveType: leaveType,
        leaveTypeName: _getLeaveTypeName(leaveType),
        startTime: startTime,
        endTime: endTime,
        totalHours: totalHours,
        totalDays: totalDays,
        reason: reason,
        status: 'PENDING',
        applyTime: nowStr,
        currentApprover: old.currentApprover,
        timeline: [
          ...old.timeline,
          AuditTimelineNode(
            stepName: '修改并重新提交',
            operator: old.staffName,
            time: nowStr,
            status: 'SUCCESS',
            comment: '更新请假时间与事由，重提审批',
          ),
        ],
      );
      _localCache[index] = updated;
      return updated;
    }
    throw Exception('未找到请假单据');
  }

  /// 主管/店长审批请假
  Future<LeaveApplicationModel> auditLeave({
    required String leaveId,
    required String action, // APPROVE | REJECT
    required String approver,
    String? auditNotes,
  }) async {
    try {
      final response = await _client.dio.post(
        '/leave/audit',
        data: {
          'leaveId': leaveId,
          'action': action,
          'approver': approver,
          'auditNotes': auditNotes ?? (action == 'APPROVE' ? '同意请假' : '驳回申请'),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final map = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (map is Map) {
          final updated = LeaveApplicationModel.fromJson(Map<String, dynamic>.from(map));
          _updateLocalItem(updated);
          return updated;
        }
      }
    } catch (e) {
      print('LeaveService auditLeave API error: $e, using local update');
    }

    final index = _localCache.indexWhere((l) => l.id == leaveId);
    if (index != -1) {
      final old = _localCache[index];
      final isApprove = action == 'APPROVE';
      final nowStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      final updated = LeaveApplicationModel(
        id: old.id,
        staffId: old.staffId,
        staffName: old.staffName,
        phone: old.phone,
        postName: old.postName,
        department: old.department,
        leaveType: old.leaveType,
        leaveTypeName: old.leaveTypeName,
        startTime: old.startTime,
        endTime: old.endTime,
        totalHours: old.totalHours,
        totalDays: old.totalDays,
        reason: old.reason,
        status: isApprove ? 'APPROVED' : 'REJECTED',
        applyTime: old.applyTime,
        currentApprover: approver,
        auditTime: nowStr,
        auditNotes: auditNotes ?? (isApprove ? '同意请假申请' : '驳回申请'),
        timeline: [
          ...old.timeline,
          AuditTimelineNode(
            stepName: '店长/主管审批',
            operator: approver,
            time: nowStr,
            status: isApprove ? 'SUCCESS' : 'REJECTED',
            comment: auditNotes ?? (isApprove ? '同意请假申请' : '驳回申请'),
          ),
        ],
      );
      _localCache[index] = updated;
      return updated;
    }
    throw Exception('未找到请假单据');
  }

  void _updateLocalItem(LeaveApplicationModel item) {
    final i = _localCache.indexWhere((l) => l.id == item.id);
    if (i != -1) {
      _localCache[i] = item;
    } else {
      _localCache.insert(0, item);
    }
  }

  String _getLeaveTypeName(String type) {
    switch (type) {
      case 'PERSONAL':
        return '事假';
      case 'SICK':
        return '病假';
      case 'ANNUAL':
        return '带薪年假';
      case 'COMPENSATORY':
        return '加班调休';
      case 'MARRIAGE':
        return '婚假';
      case 'MATERNITY':
        return '产假/陪产假';
      default:
        return '其他请假';
    }
  }
}

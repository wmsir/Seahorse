import '../core/constants/constants.dart';
import '../core/network/api_client.dart';
import '../models/appointment_model.dart';
class AppointmentService {
  final ApiClient _client = ApiClient();
  final List<AppointmentModel> _localList = [];

  /// 获取真实预约排班列表 (100% 来源云端服务端数据库)
  Future<List<AppointmentModel>> getAppointments(String storeId, {String? date}) async {
    try {
      final response = await _client.dio.get('/appointment/list', queryParameters: {
        'storeId': storeId,
        'date': date,
      });
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          final mapped = list.map((e) => AppointmentModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          _localList.clear();
          _localList.addAll(mapped);
          return mapped;
        }
      }
    } catch (e) {
      print('AppointmentService getAppointments from server: $e');
    }

    if (date != null && date.isNotEmpty) {
      return _localList.where((a) => a.aptDate == date).toList();
    }
    return _localList;
  }

  /// 登记新顾客预约排班 (服务端持久化，返回真实主键)
  Future<AppointmentModel?> createAppointment({
    required String storeId,
    required String customerName,
    required String phone,
    required String serviceName,
    required double servicePrice,
    required String aptDate,
    required String aptTime,
    String? spaceCode,
    String? spaceName,
    String? staffName,
    int peopleCount = 1,
    String notes = '',
  }) async {
    final payload = {
      'storeId': storeId,
      'customerName': customerName,
      'phone': phone,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'aptDate': aptDate,
      'aptTime': aptTime,
      'spaceCode': spaceCode,
      'spaceName': spaceName,
      'staffName': staffName,
      'peopleCount': peopleCount,
      'notes': notes,
      'status': 'PENDING',
    };

    try {
      final res = await _client.dio.post('/appointment/create', data: payload);
      if (res.statusCode == 200 && res.data != null) {
        final dynamic raw = res.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map) {
          final serverApt = AppointmentModel.fromJson(Map<String, dynamic>.from(data));
          _localList.removeWhere((a) => a.id == serverApt.id || a.aptNo == serverApt.aptNo);
          _localList.insert(0, serverApt);
          return serverApt;
        }
      }
    } catch (e) {
      print('AppointmentService createAppointment API error: $e');
      rethrow;
    }
    return null;
  }

  /// 到店核销接待入座 (调用服务端原子事务，展位与预约均变服务中)
  Future<bool> checkInAppointment(int appointmentId, {int? spaceId, String? aptNo}) async {
    try {
      final res = await _client.dio.post('/appointment/$appointmentId/check-in', data: {
        if (spaceId != null) 'spaceId': spaceId,
        if (aptNo != null && aptNo.isNotEmpty) 'aptNo': aptNo,
      });
      return res.statusCode == 200;
    } catch (e) {
      print('AppointmentService checkInAppointment error: $e');
    }
    return false;
  }

  /// 到店履约与状态流转
  Future<bool> updateStatus(int appointmentId, AppointmentStatus newStatus, {String? aptNo}) async {
    final index = _localList.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _localList[index].status = newStatus;
      if (aptNo == null || aptNo.isEmpty) {
        aptNo = _localList[index].aptNo;
      }
    }
    try {
      final statusStr = newStatus == AppointmentStatus.serving
          ? 'SERVING'
          : (newStatus == AppointmentStatus.completed ? 'COMPLETED' : 'CANCELLED');
      final res = await _client.dio.post('/appointment/$appointmentId/status', data: {
        'status': statusStr,
        'aptNo': aptNo ?? '',
      });
      return res.statusCode == 200;
    } catch (e) {
      print('AppointmentService updateStatus API error: $e');
    }
    return false;
  }

  /// 取消/删除预约
  Future<bool> deleteAppointment(int appointmentId) async {
    try {
      final res = await _client.dio.delete('/appointment/$appointmentId');
      if (res.statusCode == 200) {
        _localList.removeWhere((a) => a.id == appointmentId);
        return true;
      }
    } catch (e) {
      print('AppointmentService deleteAppointment API error: $e');
    }
    return false;
  }
}

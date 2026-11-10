import '../core/storage/local_storage.dart';
import '../core/network/api_client.dart';
import '../models/attendance_model.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  final ApiClient _client = ApiClient();
  AttendanceRecordModel? _todayRecord;
  AttendanceRecordModel? get todayRecord => _todayRecord;

  /// 发起移动端定位打卡
  Future<AttendanceRecordModel?> submitCheckIn({
    required String staffName,
    required String phone,
    required String postName,
    required String type, // CHECK_IN | CHECK_OUT | FIELD_WORK
    required double latitude,
    required double longitude,
    required String locationName,
    required double distanceMeters,
    String? notes,
  }) async {
    try {
      final response = await _client.dio.post('/attendance/check-in', data: {
        'staffName': staffName,
        'phone': phone,
        'postName': postName,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'distanceMeters': distanceMeters,
        'notes': notes,
      });

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final map = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (map is Map) {
          final record = AttendanceRecordModel.fromJson(Map<String, dynamic>.from(map));
          _todayRecord = record;
          return record;
        }
      }
    } catch (e) {
      print('AttendanceService submitCheckIn API error: $e, using optimistic local state');
    }

    // 乐观离线/容错更新
    final nowTime = DateFormat('HH:mm:ss').format(DateTime.now());
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isWithin = distanceMeters <= 500.0;
    final status = !isWithin ? 'FIELD_WORK' : 'NORMAL';

    if (_todayRecord == null) {
      _todayRecord = AttendanceRecordModel(
        id: 'ATT-${DateTime.now().millisecondsSinceEpoch}',
        staffName: staffName,
        phone: phone,
        postName: postName,
        workDate: today,
        checkInTime: nowTime,
        checkInStatus: status,
        checkInLocation: locationName,
        notes: notes ?? (isWithin ? '正常店内打卡 (偏差: ${distanceMeters.toStringAsFixed(0)}米)' : '外勤打卡'),
      );
    } else {
      if (type == 'CHECK_OUT' || _todayRecord!.isCheckedIn) {
        _todayRecord!.checkOutTime = nowTime;
        _todayRecord!.checkOutStatus = 'NORMAL';
        _todayRecord!.workHours = 8.5;
      } else {
        _todayRecord!.checkInTime = nowTime;
        _todayRecord!.checkInStatus = status;
        _todayRecord!.checkInLocation = locationName;
      }
    }

    return _todayRecord;
  }

  /// 获取当前员工今日打卡状态
  Future<AttendanceRecordModel?> getMyTodayRecord({required String phone, required String staffName}) async {
    try {
      final response = await _client.dio.get('/attendance/my-today', queryParameters: {
        'phone': phone,
        'staffName': staffName,
      });
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final map = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (map is Map) {
          final record = AttendanceRecordModel.fromJson(Map<String, dynamic>.from(map));
          _todayRecord = record;
          return record;
        }
      }
    } catch (e) {
      print('AttendanceService getMyTodayRecord error: $e');
    }
    return _todayRecord;
  }

  /// 查询全员考勤流水
  Future<List<AttendanceRecordModel>> getAllRecords({String? storeId}) async {
    try {
      final curStoreId = storeId ?? LocalStorage.getString('seahorse_store_id') ?? 'S001';
      final response = await _client.dio.get('/attendance/records', queryParameters: {
        'storeId': curStoreId,
      });
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          return list.map((e) => AttendanceRecordModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
    } catch (e) {
      print('AttendanceService getAllRecords error: $e');
    }
    return [];
  }
}

import '../core/constants/constants.dart';

class SpaceModel {
  final int id;
  final String storeId;
  final String spaceCode;
  final String spaceName;
  final String spaceType; // ROOM, SEAT, STATION
  SpaceStatus status;
  final int capacity;
  final String floorZone;
  final double minConsumeAmount;
  final double hourlyFee;
  final List<String> facilities;
  final String notes;

  // 在场动态与当前会话
  int? currentSessionId;
  String? currentCustomerName;
  String? currentCustomerPhone;
  String? currentTechnicianName;
  DateTime? serviceStartTime;
  double currentBillAmount;
  int currentItemCount;

  SpaceModel({
    required this.id,
    required this.storeId,
    required this.spaceCode,
    required this.spaceName,
    this.spaceType = 'ROOM',
    this.status = SpaceStatus.idle,
    this.capacity = 4,
    this.floorZone = '一楼大厅',
    this.minConsumeAmount = 0.0,
    this.hourlyFee = 0.0,
    this.facilities = const [],
    this.notes = '',
    this.currentSessionId,
    this.currentCustomerName,
    this.currentCustomerPhone,
    this.currentTechnicianName,
    this.serviceStartTime,
    this.currentBillAmount = 0.0,
    this.currentItemCount = 0,
  });

  /// 已服务时长（分钟）
  int get servedMinutes {
    if (serviceStartTime == null) return 0;
    return DateTime.now().difference(serviceStartTime!).inMinutes;
  }

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      id: json['id'] ?? 0,
      storeId: json['storeId'] ?? '',
      spaceCode: json['spaceCode'] ?? '',
      spaceName: json['spaceName'] ?? '',
      spaceType: json['spaceType'] ?? 'ROOM',
      status: SpaceStatus.fromCode(json['status'] ?? 'IDLE'),
      capacity: json['capacity'] ?? 4,
      floorZone: json['floorZone'] ?? '一楼大厅',
      minConsumeAmount: (json['minConsumeAmount'] ?? 0).toDouble(),
      hourlyFee: (json['hourlyFee'] ?? 0).toDouble(),
      facilities: (json['facilities'] is List)
          ? List<String>.from(json['facilities'])
          : (json['facilities'] is String && (json['facilities'] as String).isNotEmpty)
              ? (json['facilities'] as String).split(',')
              : [],
      notes: json['notes'] ?? '',
      currentSessionId: json['currentSessionId'],
      currentCustomerName: json['currentCustomerName'],
      currentCustomerPhone: json['currentCustomerPhone'],
      currentTechnicianName: json['currentTechnicianName'],
      serviceStartTime: json['serviceStartTime'] != null
          ? DateTime.tryParse(json['serviceStartTime'])
          : null,
      currentBillAmount: (json['currentBillAmount'] ?? 0).toDouble(),
      currentItemCount: json['currentItemCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'spaceCode': spaceCode,
      'spaceName': spaceName,
      'spaceType': spaceType,
      'status': status.code,
      'capacity': capacity,
      'floorZone': floorZone,
      'minConsumeAmount': minConsumeAmount,
      'hourlyFee': hourlyFee,
      'facilities': facilities,
      'notes': notes,
      'currentSessionId': currentSessionId,
      'currentCustomerName': currentCustomerName,
      'currentCustomerPhone': currentCustomerPhone,
      'currentTechnicianName': currentTechnicianName,
      'serviceStartTime': serviceStartTime?.toIso8601String(),
      'currentBillAmount': currentBillAmount,
      'currentItemCount': currentItemCount,
    };
  }
}

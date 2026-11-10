class AttendanceRecordModel {
  final String id;
  final String staffName;
  final String phone;
  final String postName;
  final String workDate;
  String? checkInTime;
  String? checkInStatus; // NORMAL, LATE, FIELD_WORK, ABSENT
  String? checkOutTime;
  String? checkOutStatus; // NORMAL, EARLY, NOT_CHECKED
  double? workHours;
  String? checkInLocation;
  String platformSource;
  String? notes;

  AttendanceRecordModel({
    required this.id,
    required this.staffName,
    required this.phone,
    required this.postName,
    required this.workDate,
    this.checkInTime,
    this.checkInStatus,
    this.checkOutTime,
    this.checkOutStatus,
    this.workHours,
    this.checkInLocation,
    this.platformSource = 'APP_MOBILE',
    this.notes,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id']?.toString() ?? '',
      staffName: json['staffName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      postName: json['postName']?.toString() ?? '技师',
      workDate: json['workDate']?.toString() ?? '',
      checkInTime: json['checkInTime']?.toString(),
      checkInStatus: json['checkInStatus']?.toString(),
      checkOutTime: json['checkOutTime']?.toString(),
      checkOutStatus: json['checkOutStatus']?.toString(),
      workHours: json['workHours'] != null ? (json['workHours'] as num).toDouble() : null,
      checkInLocation: json['checkInLocation']?.toString(),
      platformSource: json['platformSource']?.toString() ?? 'APP_MOBILE',
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffName': staffName,
      'phone': phone,
      'postName': postName,
      'workDate': workDate,
      'checkInTime': checkInTime,
      'checkInStatus': checkInStatus,
      'checkOutTime': checkOutTime,
      'checkOutStatus': checkOutStatus,
      'workHours': workHours,
      'checkInLocation': checkInLocation,
      'platformSource': platformSource,
      'notes': notes,
    };
  }

  bool get isCheckedIn => checkInTime != null && checkInTime!.isNotEmpty;
  bool get isCheckedOut => checkOutTime != null && checkOutTime!.isNotEmpty;
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.accuracy = 15.0,
  });
}

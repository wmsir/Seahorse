import '../core/constants/constants.dart';

class AppointmentModel {
  int id;
  final String aptNo;
  final String storeId;
  final String customerName;
  final String phone;
  final int peopleCount;
  final String serviceName;
  final double servicePrice;
  final String? spaceCode;
  final String? spaceName;
  final String? staffName;
  final String aptDate;
  final String aptTime;
  AppointmentStatus status;
  final String notes;

  AppointmentModel({
    required this.id,
    required this.aptNo,
    required this.storeId,
    required this.customerName,
    required this.phone,
    this.peopleCount = 1,
    required this.serviceName,
    this.servicePrice = 0.0,
    this.spaceCode,
    this.spaceName,
    this.staffName,
    required this.aptDate,
    required this.aptTime,
    this.status = AppointmentStatus.pending,
    this.notes = '',
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? 0,
      aptNo: json['aptNo'] ?? '',
      storeId: json['storeId'] ?? '',
      customerName: json['customerName'] ?? json['name'] ?? '',
      phone: json['phone'] ?? '',
      peopleCount: json['peopleCount'] ?? 1,
      serviceName: json['serviceName'] ?? json['serviceItem'] ?? '经典推拿护理',
      servicePrice: (json['servicePrice'] ?? json['price'] ?? 0).toDouble(),
      spaceCode: json['spaceCode'],
      spaceName: json['spaceName'],
      staffName: json['staffName'] ?? json['technicianName'],
      aptDate: json['aptDate'] ?? '',
      aptTime: json['aptTime'] ?? '',
      status: AppointmentStatus.fromCode(json['status'] ?? 'PENDING'),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'aptNo': aptNo,
      'storeId': storeId,
      'customerName': customerName,
      'phone': phone,
      'peopleCount': peopleCount,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'spaceCode': spaceCode,
      'spaceName': spaceName,
      'staffName': staffName,
      'aptDate': aptDate,
      'aptTime': aptTime,
      'status': status.code,
      'notes': notes,
    };
  }
}

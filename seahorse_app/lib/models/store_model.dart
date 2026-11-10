import '../core/constants/constants.dart';

class StoreModel {
  final String storeId;
  final String storeName;
  final String tenantId;
  final String address;
  final String phone;
  final String openTime;
  final bool isHeadquarter;
  final IndustryType industry;
  final String industryCategoryName;
  final String managerName;
  final int totalSpaces;

  StoreModel({
    required this.storeId,
    required this.storeName,
    this.tenantId = 'T001',
    required this.address,
    required this.phone,
    required this.openTime,
    this.isHeadquarter = false,
    this.industry = IndustryType.beauty,
    this.industryCategoryName = '美业造型',
    this.managerName = '店长',
    this.totalSpaces = 10,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      storeId: json['storeId'] ?? '',
      storeName: json['storeName'] ?? '',
      tenantId: json['tenantId'] ?? 'T001',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      openTime: json['openTime'] ?? json['businessHours'] ?? '10:00 - 22:00',
      isHeadquarter: json['isHeadquarter'] ?? false,
      industry: IndustryType.fromCode(json['industry'] ?? 'BEAUTY'),
      industryCategoryName: json['industryCategoryName'] ?? '美业造型',
      managerName: json['managerName'] ?? json['manager'] ?? '店长',
      totalSpaces: json['totalSpaces'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'tenantId': tenantId,
      'address': address,
      'phone': phone,
      'openTime': openTime,
      'isHeadquarter': isHeadquarter,
      'industry': industry.code,
      'industryCategoryName': industryCategoryName,
      'managerName': managerName,
      'totalSpaces': totalSpaces,
    };
  }
}

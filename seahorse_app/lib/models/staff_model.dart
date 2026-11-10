class StaffModel {
  final int id;
  final String staffNo;
  final String storeId;
  final String realName;
  final String? nickname; // 店内称呼/艺名 (例如: 小美)
  final String phone;
  final String postName; // 店长, 技师, 发型师, 服务顾问
  final String role; // SUPER_ADMIN, MANAGER, TECHNICIAN
  final String department;
  String status; // ACTIVE, SERVING, REST
  final double commissionRate;
  final int servingOrderCount;
  String? auditStatus; // PENDING, APPROVED, REJECTED
  final bool isSelfApplied;
  final String gender;
  final double? baseSalary;

  StaffModel({
    required this.id,
    required this.staffNo,
    required this.storeId,
    required this.realName,
    this.nickname,
    required this.phone,
    required this.postName,
    this.role = 'TECHNICIAN',
    this.department = '养生技术部',
    this.status = 'ACTIVE',
    this.commissionRate = 0.35,
    this.servingOrderCount = 0,
    this.auditStatus,
    this.isSelfApplied = false,
    this.gender = 'MALE',
    this.baseSalary,
  });

  /// 获取对外展示名称 (优先店内称呼、仅店内称呼、真实姓名、两者皆展示)
  String getDisplayName([String? mode = 'NICKNAME_FIRST']) {
    final nick = nickname?.trim();
    final real = realName.trim();
    if (mode == 'NICKNAME') {
      return (nick != null && nick.isNotEmpty) ? nick : real;
    } else if (mode == 'REAL_NAME') {
      return real.isNotEmpty ? real : (nick ?? '');
    } else if (mode == 'BOTH') {
      if (nick != null && nick.isNotEmpty) {
        return '$real ($nick)';
      }
      return real;
    } else {
      // NICKNAME_FIRST (默认：优先店内称呼如小美，未录入则展示真实姓名张三)
      return (nick != null && nick.isNotEmpty) ? nick : real;
    }
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? 0,
      staffNo: json['staffNo'] ?? 'S${json['id'] ?? 101}',
      storeId: json['storeId'] ?? '',
      realName: json['realName'] ?? '',
      nickname: json['nickname'] != null && json['nickname'].toString().trim().isNotEmpty
          ? json['nickname'].toString().trim()
          : null,
      phone: json['phone'] ?? '',
      postName: json['postName'] ?? '高级技师',
      role: json['role'] ?? 'TECHNICIAN',
      department: json['department'] ?? '运营服务部',
      status: json['status'] ?? 'ACTIVE',
      commissionRate: (json['commissionRate'] ?? json['serviceCommissionRate'] ?? json['defaultCommissionRate']) != null
          ? ((json['commissionRate'] ?? json['serviceCommissionRate'] ?? json['defaultCommissionRate']) is num
              ? ((json['commissionRate'] ?? json['serviceCommissionRate'] ?? json['defaultCommissionRate']) as num).toDouble()
              : (double.tryParse((json['commissionRate'] ?? json['serviceCommissionRate'] ?? json['defaultCommissionRate']).toString()) ?? 0.25))
          : 0.25,
      servingOrderCount: json['servingOrderCount'] ?? 0,
      auditStatus: json['auditStatus'] ?? (json['status'] == 'PENDING_REVIEW' ? 'PENDING' : null),
      isSelfApplied: json['isSelfApplied'] == true || json['selfApplied'] == true,
      gender: json['gender'] ?? 'MALE',
      baseSalary: json['baseSalary'] != null
          ? (json['baseSalary'] is num
              ? (json['baseSalary'] as num).toDouble()
              : double.tryParse(json['baseSalary'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffNo': staffNo,
      'storeId': storeId,
      'realName': realName,
      'nickname': nickname,
      'phone': phone,
      'postName': postName,
      'role': role,
      'department': department,
      'status': status,
      'commissionRate': commissionRate,
      'servingOrderCount': servingOrderCount,
      'auditStatus': auditStatus,
      'isSelfApplied': isSelfApplied,
      'gender': gender,
      'baseSalary': baseSalary,
    };
  }
}

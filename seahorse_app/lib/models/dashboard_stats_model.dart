class DashboardStatsModel {
  final double todayRevenue;
  final int todayOrderCount;
  final int totalSpaces;
  final int occupiedSpaces;
  final double spaceUtilizationRate;
  final int activeSessions;
  final int totalMembers;
  final double todayCommissions;
  final int pendingAppointments;
  final int todayCustomers;
  final int dirtyCount;

  DashboardStatsModel({
    this.todayRevenue = 0.0,
    this.todayOrderCount = 0,
    this.totalSpaces = 0,
    this.occupiedSpaces = 0,
    this.spaceUtilizationRate = 0.0,
    this.activeSessions = 0,
    this.totalMembers = 0,
    this.todayCommissions = 0.0,
    this.pendingAppointments = 0,
    this.todayCustomers = 0,
    this.dirtyCount = 0,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      todayRevenue: (json['todayRevenue'] != null)
          ? double.tryParse(json['todayRevenue'].toString()) ?? 0.0
          : 0.0,
      todayOrderCount: (json['todayOrderCount'] as num?)?.toInt() ?? 0,
      totalSpaces: (json['totalSpaces'] as num?)?.toInt() ?? 0,
      occupiedSpaces: (json['occupiedSpaces'] as num?)?.toInt() ?? 0,
      spaceUtilizationRate: (json['spaceUtilizationRate'] != null)
          ? double.tryParse(json['spaceUtilizationRate'].toString()) ?? 0.0
          : 0.0,
      activeSessions: (json['activeSessions'] as num?)?.toInt() ?? 0,
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      todayCommissions: (json['todayCommissions'] != null)
          ? double.tryParse(json['todayCommissions'].toString()) ?? 0.0
          : 0.0,
      pendingAppointments: (json['pendingAppointments'] as num?)?.toInt() ?? 0,
      todayCustomers: (json['todayCustomers'] as num?)?.toInt() ?? 0,
      dirtyCount: (json['dirtyCount'] as num?)?.toInt() ?? 0,
    );
  }
}

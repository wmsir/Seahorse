import 'package:flutter/material.dart';

class AuditTimelineNode {
  final String stepName;
  final String operator;
  final String time;
  final String status; // SUCCESS | CURRENT | PENDING | REJECTED
  final String comment;

  AuditTimelineNode({
    required this.stepName,
    required this.operator,
    required this.time,
    required this.status,
    required this.comment,
  });

  factory AuditTimelineNode.fromJson(Map<String, dynamic> json) {
    return AuditTimelineNode(
      stepName: json['stepName']?.toString() ?? '',
      operator: json['operator']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      comment: json['comment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepName': stepName,
      'operator': operator,
      'time': time,
      'status': status,
      'comment': comment,
    };
  }
}

class LeaveApplicationModel {
  final String id;
  final int staffId;
  final String staffName;
  final String phone;
  final String postName;
  final String department;
  final String leaveType; // PERSONAL | SICK | ANNUAL | COMPENSATORY | MARRIAGE | MATERNITY
  final String leaveTypeName;
  final String startTime;
  final String endTime;
  final double totalHours;
  final double totalDays;
  final String reason;
  final String status; // PENDING | APPROVED | REJECTED | REVOKED
  final String applyTime;
  final String currentApprover;
  final String? auditTime;
  final String? auditNotes;
  final List<AuditTimelineNode> timeline;

  LeaveApplicationModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.phone,
    required this.postName,
    required this.department,
    required this.leaveType,
    required this.leaveTypeName,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.applyTime,
    required this.currentApprover,
    this.auditTime,
    this.auditNotes,
    required this.timeline,
  });

  factory LeaveApplicationModel.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'] as List<dynamic>? ?? [];
    return LeaveApplicationModel(
      id: json['id']?.toString() ?? '',
      staffId: json['staffId'] is int ? json['staffId'] : int.tryParse(json['staffId']?.toString() ?? '0') ?? 0,
      staffName: json['staffName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      postName: json['postName']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      leaveType: json['leaveType']?.toString() ?? 'PERSONAL',
      leaveTypeName: json['leaveTypeName']?.toString() ?? '事假',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      totalHours: (json['totalHours'] is num) ? (json['totalHours'] as num).toDouble() : 8.0,
      totalDays: (json['totalDays'] is num) ? (json['totalDays'] as num).toDouble() : 1.0,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      applyTime: json['applyTime']?.toString() ?? '',
      currentApprover: json['currentApprover']?.toString() ?? '',
      auditTime: json['auditTime']?.toString(),
      auditNotes: json['auditNotes']?.toString(),
      timeline: rawTimeline.map((node) => AuditTimelineNode.fromJson(node as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'phone': phone,
      'postName': postName,
      'department': department,
      'leaveType': leaveType,
      'leaveTypeName': leaveTypeName,
      'startTime': startTime,
      'endTime': endTime,
      'totalHours': totalHours,
      'totalDays': totalDays,
      'reason': reason,
      'status': status,
      'applyTime': applyTime,
      'currentApprover': currentApprover,
      'auditTime': auditTime,
      'auditNotes': auditNotes,
      'timeline': timeline.map((t) => t.toJson()).toList(),
    };
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF059669);
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'REJECTED':
        return const Color(0xFFDC2626);
      case 'REVOKED':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF0284C7);
    }
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return '已批准通过';
      case 'PENDING':
        return '等待审批中';
      case 'REJECTED':
        return '已驳回';
      case 'REVOKED':
        return '已撤回';
      default:
        return status;
    }
  }

  bool get canRevoke => status.toUpperCase() == 'PENDING';
  bool get canEdit => status.toUpperCase() == 'PENDING' || status.toUpperCase() == 'REJECTED';
}

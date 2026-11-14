import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../../models/staff_model.dart';
import '../../../models/attendance_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../services/staff_service.dart';
import '../../../services/attendance_service.dart';
import '../../attendance/attendance_check_in_view.dart';
import '../../../core/utils/phone_caller.dart';

class StaffManagementTab extends StatefulWidget {
  const StaffManagementTab({Key? key}) : super(key: key);

  @override
  State<StaffManagementTab> createState() => _StaffManagementTabState();
}

class _StaffManagementTabState extends State<StaffManagementTab> {
  final StaffService _staffService = StaffService();
  final AttendanceService _attendanceService = AttendanceService();
  List<StaffModel> _staffList = [];
  List<StaffModel> _auditStaffList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'ALL'; // ALL, ACTIVE, SERVING, REST
  String? _lastStoreId;

  int get _pendingAuditCount => _auditStaffList
      .where((s) => s.auditStatus == 'PENDING' || s.status == 'PENDING_REVIEW')
      .length;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.watch<StoreProvider>();
    final curStoreId = store.currentStoreId;
    if (_lastStoreId != curStoreId) {
      _lastStoreId = curStoreId;
      _loadStaff();
    }
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final store = context.read<StoreProvider>();
    final curStoreId = store.currentStoreId;
    final results = await Future.wait([
      _staffService.getStaffList(storeId: curStoreId),
      _staffService.getAuditStaffList(storeId: curStoreId),
    ]);
    if (mounted) {
      setState(() {
        _staffList = results[0];
        _auditStaffList = results[1];
        _isLoading = false;
      });
    }
  }

  void _showAuditBottomSheet() {
    final auth = context.read<AuthProvider>();
    final isManager = _isAuthorizedManager(auth);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final pendingList = _auditStaffList
                .where((s) => s.auditStatus == 'PENDING' || s.status == 'PENDING_REVIEW')
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          const Text(
                            '扫码入职审核申请',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          if (pendingList.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${pendingList.length} 人待审核',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '员工自主扫码填报后在此集中复核，核定岗位底薪后一键批准并激活工号',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: pendingList.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.done_all_outlined, size: 54, color: Colors.green),
                                SizedBox(height: 12),
                                Text('暂无待审核的扫码入职申请', style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                SizedBox(height: 6),
                                Text('新员工提交入职申请后将实时在此处显示', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: pendingList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, idx) {
                              final item = pendingList[idx];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.realName,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: (item.gender == 'FEMALE' || item.gender == '女')
                                                    ? Colors.pink.withOpacity(0.12)
                                                    : Colors.blue.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                (item.gender == 'FEMALE' || item.gender == '女') ? '女' : '男',
                                                style: TextStyle(
                                                  color: (item.gender == 'FEMALE' || item.gender == '女') ? Colors.pink : Colors.blue,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '⏳ 待店长审核',
                                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text('所属部门：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                        Text(item.department, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text('拟任岗位：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                        Text(item.postName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Text('登录手机号：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                        Text(item.phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    if (item.baseSalary != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Text('核定底薪：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                          Text('￥${item.baseSalary?.toStringAsFixed(0)} /月', style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ],
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(Icons.close, size: 14, color: Colors.red),
                                          label: const Text('驳回', style: TextStyle(fontSize: 12, color: Colors.red)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.redAccent),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          ),
                                          onPressed: !isManager
                                              ? null
                                              : () => _handleRejectApplicant(item, setSheetState),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.check, size: 14, color: Colors.white),
                                          label: const Text('审核通过', style: TextStyle(fontSize: 12, color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                          ),
                                          onPressed: !isManager
                                              ? null
                                              : () => _handleApproveApplicant(item, setSheetState),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleApproveApplicant(StaffModel applicant, StateSetter setSheetState) async {
    final roles = await _staffService.getStaffRoles();
    if (!mounted) return;

    String selectedRole = applicant.role.isNotEmpty ? applicant.role : 'TECHNICIAN';
    if (!roles.any((r) => r.roleCode == selectedRole)) {
      selectedRole = roles.isNotEmpty ? roles.first.roleCode : 'TECHNICIAN';
    }
    final postCtrl = TextEditingController(text: applicant.postName);
    final deptCtrl = TextEditingController(text: applicant.department);
    final salaryCtrl = TextEditingController(text: applicant.baseSalary?.toStringAsFixed(0) ?? '5000');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final curRole = roles.firstWhere(
              (r) => r.roleCode == selectedRole,
              orElse: () => StaffRoleInfo(roleCode: selectedRole, roleName: selectedRole, description: ''),
            );
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('核定入职 · ${applicant.realName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('请核定入职岗位与权限体系角色（与浏览器后台实时对齐）：', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deptCtrl,
                      decoration: const InputDecoration(labelText: '所属部门', isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: postCtrl,
                      decoration: const InputDecoration(labelText: '拟任岗位', isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: '核定权限体系角色 (对齐浏览器)', isDense: true, border: OutlineInputBorder()),
                      items: roles.map((r) {
                        return DropdownMenuItem(
                          value: r.roleCode,
                          child: Text('${r.roleName} (${r.roleCode})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                      child: Text(curRole.description.isNotEmpty ? curRole.description : '该角色权限已与浏览器配置一致', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: salaryCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '核定保底月薪 (元)', prefixText: '￥', isDense: true, border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('取消')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => Navigator.pop(dlgCtx, true),
                  child: const Text('批准入职并激活', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    final postVal = postCtrl.text.trim();
    final deptVal = deptCtrl.text.trim();
    final salaryVal = double.tryParse(salaryCtrl.text.trim()) ?? applicant.baseSalary;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      postCtrl.dispose();
      deptCtrl.dispose();
      salaryCtrl.dispose();
    });

    if (confirmed != true) return;

    final success = await _staffService.approveStaffAudit(
      applicant.id,
      postName: postVal.isEmpty ? applicant.postName : postVal,
      department: deptVal.isEmpty ? applicant.department : deptVal,
      role: selectedRole,
      baseSalary: salaryVal,
    );
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 员工【${applicant.realName}】入职审核已批准！已继承【$selectedRole】权限体系！'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadStaff();
      setSheetState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('审核操作失败，请重试'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectApplicant(StaffModel applicant, StateSetter setSheetState) async {
    final reasonCtrl = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('驳回【${applicant.realName}】入职申请'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: '驳回原因',
            hintText: '如：HC已满/信息不全/资历不符等',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认驳回', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    final rejectReason = reasonCtrl.text.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reasonCtrl.dispose();
    });

    if (shouldReject == true) {
      final success = await _staffService.rejectStaffAudit(applicant.id, reason: rejectReason);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已驳回员工【${applicant.realName}】的入职申请。'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        await _loadStaff();
        setSheetState(() {});
      }
    }
  }

  List<StaffModel> get _filteredStaff {
    return _staffList.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.realName.contains(_searchQuery) ||
          s.staffNo.contains(_searchQuery) ||
          s.postName.contains(_searchQuery) ||
          s.phone.contains(_searchQuery);

      if (!matchesSearch) return false;

      if (_selectedStatus == 'ALL') return true;
      return s.status == _selectedStatus;
    }).toList();
  }

  void _showStatusDialog(StaffModel staff) {
    final auth = context.read<AuthProvider>();
    final isManager = _isAuthorizedManager(auth);
    final isSelf = (auth.username.isNotEmpty && staff.phone == auth.username) ||
        (auth.realName.isNotEmpty && staff.realName == auth.realName) ||
        (auth.username.isNotEmpty && staff.staffNo == auth.username);

    if (!isManager && !isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ 权限不足：收银员仅可修改本人的在岗待工状态，其他同事状态由店长统一调度。'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('调整员工状态 · ${staff.realName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.check, color: Colors.green)),
                title: const Text('🟢 空闲待工 (可正常指派/排单)'),
                trailing: staff.status == 'ACTIVE' ? const Icon(Icons.done, color: Colors.green) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(staff, 'ACTIVE');
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.hourglass_top, color: Colors.amber)),
                title: const Text('🟡 服务中 (已占用/上钟服务)'),
                trailing: staff.status == 'SERVING' ? const Icon(Icons.done, color: Colors.amber) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(staff, 'SERVING');
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFF1F5F9), child: Icon(Icons.nightlight_outlined, color: Colors.blueGrey)),
                title: const Text('⚪ 请假休息 / 下班离岗'),
                trailing: staff.status == 'REST' ? const Icon(Icons.done, color: Colors.blueGrey) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateStatus(staff, 'REST');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(StaffModel staff, String newStatus) async {
    setState(() => staff.status = newStatus);
    final success = await _staffService.updateStaffStatus(staff.id, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '已成功将 ${staff.realName} 状态变更为 ${_getStatusLabel(newStatus)}' : '状态更新已完成'),
          duration: const Duration(seconds: 2),
        ),
      );
      _loadStaff();
    }
  }

  void _showAddStaffDialog() {
    final auth = context.read<AuthProvider>();
    if (!_isAuthorizedManager(auth)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🛡️ 权限不足：登记在册员工仅限店长或租户管理员操作。'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RegisterStaffSheet(
        staffService: _staffService,
        onSuccess: _loadStaff,
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return '空闲待工';
      case 'SERVING':
        return '服务中';
      case 'REST':
        return '请假休息';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'SERVING':
        return const Color(0xFFD97706);
      case 'REST':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }

  bool _isAuthorizedManager(AuthProvider auth) {
    final role = auth.role.toUpperCase();
    final username = auth.username.toLowerCase();
    return role == 'STORE_MANAGER' ||
        role == 'SUPER_ADMIN' ||
        role.contains('MANAGER') ||
        role.contains('ADMIN') ||
        username.contains('admin') ||
        username.contains('manager') ||
        username.contains('boss') ||
        auth.realName.contains('店长');
  }

  void _showTeamAttendanceSheet() {
    final auth = context.read<AuthProvider>();
    final isManager = _isAuthorizedManager(auth);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return FutureBuilder<List<AttendanceRecordModel>>(
          future: _attendanceService.getAllRecords(),
          builder: (context, snapshot) {
            final allRecords = snapshot.data ?? [];
            // 收银员与普通员工仅能看到自己的打卡记录，只有店长或获授权角色才能查看全员打卡大盘
            final records = isManager
                ? allRecords
                : allRecords.where((r) =>
                    (auth.username.isNotEmpty && r.phone == auth.username) ||
                    (auth.realName.isNotEmpty && r.staffName == auth.realName)
                  ).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(isManager ? Icons.badge_outlined : Icons.person_pin_circle_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            isManager ? '全店员工今日打卡大盘' : '我的今日考勤打卡明细',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (isManager) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                          child: const Text('🛡️ 租户店长管理权限', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('共获取到 ${records.length} 条全员考勤打卡流水', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.privacy_tip_outlined, size: 16, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '您当前为【收银员/普通员工】角色，仅可查阅本人的考勤打卡明细；全店打卡需店长或租户后台授权。',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 20),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            itemCount: records.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final r = records[i];
                              final isNormal = r.checkInStatus == 'NORMAL';
                              final isField = r.checkInStatus == 'FIELD_WORK';
                              final statusColor = isField ? Colors.orange : (isNormal ? Colors.green : Colors.grey);
                              final statusLabel = isField ? '外勤打卡' : (isNormal ? '正常打卡' : '迟到');

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(r.staffName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 6),
                                            Text(r.postName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('上班打卡: ${r.checkInTime ?? '未打卡'}  |  下班打卡: ${r.checkOutTime ?? '未打卡'}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                    const SizedBox(height: 3),
                                    Text('打卡地点: ${r.checkInLocation ?? '门店范围'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    if (r.notes != null) ...[
                                      const SizedBox(height: 2),
                                      Text('备注: ${r.notes}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isManager = _isAuthorizedManager(auth);
    final activeCount = _staffList.where((s) => s.status == 'ACTIVE').length;
    final servingCount = _staffList.where((s) => s.status == 'SERVING').length;
    final restCount = _staffList.where((s) => s.status == 'REST').length;

    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部在岗大盘统计
            Row(
              children: [
                Expanded(child: _buildCountBadge('在册总数', '${_staffList.length} 人', AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(child: _buildCountBadge('空闲待工', '$activeCount 人', Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildCountBadge('服务中', '$servingCount 人', const Color(0xFFD97706))),
                const SizedBox(width: 8),
                Expanded(child: _buildCountBadge('休假中', '$restCount 人', Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // 考勤打卡、打卡看板与扫码入职审核快捷操作
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.pin_drop, size: 14, color: Color(0xFFD97706)),
                    label: const Text('📍 定位打卡', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      side: const BorderSide(color: Color(0xFFFBBF24)),
                      backgroundColor: const Color(0xFFFFFBEB),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceCheckInView()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isManager ? Icons.fact_check_outlined : Icons.person_pin_circle_outlined, size: 14, color: AppColors.primary),
                    label: Text(isManager ? '📋 考勤看板' : '📋 我的打卡', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      backgroundColor: AppColors.primary.withOpacity(0.06),
                    ),
                    onPressed: _showTeamAttendanceSheet,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF047857)),
                          label: const Text('🛡️ 入职审核', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            side: const BorderSide(color: Color(0xFF6EE7B7)),
                            backgroundColor: const Color(0xFFECFDF5),
                          ),
                          onPressed: _showAuditBottomSheet,
                        ),
                      ),
                      if (_pendingAuditCount > 0)
                        Positioned(
                          right: -2,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$_pendingAuditCount',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_pendingAuditCount > 0) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: _showAuditBottomSheet,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('⏳', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '当前有 $_pendingAuditCount 位新员工扫码申请入职，点击进入审核',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFB45309)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // 2. 搜索与新增按钮
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索姓名 / 工号 / 岗位...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text('加员工', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showAddStaffDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. 状态筛选 Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('全部 (${_staffList.length})', 'ALL'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🟢 空闲 ($activeCount)', 'ACTIVE'),
                  const SizedBox(width: 8),
                  _buildFilterChip('🟡 服务中 ($servingCount)', 'SERVING'),
                  const SizedBox(width: 8),
                  _buildFilterChip('⚪ 休息 ($restCount)', 'REST'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. 员工卡片列表
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_filteredStaff.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: const [
                    Icon(Icons.person_search_outlined, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('暂无符合筛选条件的员工', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredStaff.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final staff = _filteredStaff[index];
                  final statusColor = _getStatusColor(staff.status);

                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                child: Text(
                                  staff.realName.isNotEmpty ? staff.realName.substring(0, 1) : '技',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          staff.realName,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            staff.postName,
                                            style: const TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildRoleBadge(staff.role),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '工号: ${staff.staffNo} · ${staff.department} · 📱 ${staff.phone}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              // 状态标签（点击可切换）
                              InkWell(
                                onTap: () => _showStatusDialog(staff),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(radius: 4, backgroundColor: statusColor),
                                      const SizedBox(width: 5),
                                      Text(
                                        _getStatusLabel(staff.status),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(Icons.keyboard_arrow_down, size: 14, color: statusColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '提成比例: ${(staff.commissionRate * 100).toStringAsFixed(0)}%  |  今日带单: ${staff.servingOrderCount} 笔',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Row(
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.phone_outlined, size: 14),
                                    label: const Text('联系', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                     onPressed: () {
                                       PhoneCaller.call(context, staff.phone, targetName: staff.realName);
                                     },
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.swap_horiz, size: 14),
                                    label: const Text('调配', style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => _showStatusDialog(staff),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: AppColors.primary.withOpacity(0.15),
      backgroundColor: Colors.white,
      onSelected: (_) => setState(() => _selectedStatus = status),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    String label;
    switch (role.toUpperCase()) {
      case 'STORE_MANAGER':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7C3AED);
        label = '店长';
        break;
      case 'CASHIER':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        label = '收银员';
        break;
      case 'WAITER':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = '服务员';
        break;
      case 'TECHNICIAN':
      default:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = '技师';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

/// 登记新在册员工底部弹窗，权限体系角色与浏览器配置完全实时一致
class _RegisterStaffSheet extends StatefulWidget {
  final StaffService staffService;
  final VoidCallback onSuccess;

  const _RegisterStaffSheet({
    Key? key,
    required this.staffService,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_RegisterStaffSheet> createState() => _RegisterStaffSheetState();
}

class _RegisterStaffSheetState extends State<_RegisterStaffSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _postCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _baseSalaryCtrl;
  late final TextEditingController _commissionCtrl;

  String _selectedGender = 'MALE';
  String _selectedRole = 'TECHNICIAN';
  bool _isLoadingConfig = true;
  bool _isSubmitting = false;

  List<StaffRoleInfo> _roles = [];
  List<String> _departments = [];
  List<Map<String, dynamic>> _positions = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _nicknameCtrl = TextEditingController();
    _postCtrl = TextEditingController(text: '高级服务技师');
    _deptCtrl = TextEditingController(text: '技术服务部');
    _baseSalaryCtrl = TextEditingController(text: '5000');
    _commissionCtrl = TextEditingController(text: '0.35');
    _loadConfig();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nicknameCtrl.dispose();
    _postCtrl.dispose();
    _deptCtrl.dispose();
    _baseSalaryCtrl.dispose();
    _commissionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final curStoreId = context.read<StoreProvider>().currentStoreId;
      final results = await Future.wait([
        widget.staffService.getStaffRoles(),
        widget.staffService.getStorePositionsAndDepartments(storeId: curStoreId),
      ]);
      if (mounted) {
        setState(() {
          _roles = results[0] as List<StaffRoleInfo>;
          final storeData = results[1] as Map<String, dynamic>;
          _departments = (storeData['departments'] as List?)?.cast<String>() ?? [];
          _positions = (storeData['positions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (_departments.isNotEmpty && !_departments.contains(_deptCtrl.text)) {
            _deptCtrl.text = _departments.first;
          }
          if (_roles.isNotEmpty && !_roles.any((r) => r.roleCode == _selectedRole)) {
            _selectedRole = _roles.first.roleCode;
          }
          _isLoadingConfig = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _roles = widget.staffService.defaultStaffRoles;
          _isLoadingConfig = false;
        });
      }
    }
  }

  void _applyPosition(Map<String, dynamic> pos) {
    setState(() {
      if (pos['postName'] != null && pos['postName'].toString().isNotEmpty) {
        _postCtrl.text = pos['postName'].toString();
      }
      if (pos['department'] != null && pos['department'].toString().isNotEmpty) {
        _deptCtrl.text = pos['department'].toString();
      }
      final role = pos['role']?.toString() ?? '';
      if (role.isNotEmpty && _roles.any((r) => r.roleCode == role)) {
        _selectedRole = role;
      }
      if (pos['baseSalary'] != null) {
        _baseSalaryCtrl.text = pos['baseSalary'].toString();
      }
      if (pos['commissionRate'] != null) {
        _commissionCtrl.text = pos['commissionRate'].toString();
      }
    });
  }

  IconData _getRoleIcon(String roleCode) {
    switch (roleCode.toUpperCase()) {
      case 'STORE_MANAGER':
        return Icons.admin_panel_settings_outlined;
      case 'CASHIER':
        return Icons.point_of_sale_outlined;
      case 'TECHNICIAN':
        return Icons.construction_outlined;
      case 'WAITER':
        return Icons.room_service_outlined;
      default:
        return Icons.badge_outlined;
    }
  }

  Color _getRoleColor(String roleCode) {
    switch (roleCode.toUpperCase()) {
      case 'STORE_MANAGER':
        return const Color(0xFF7C3AED);
      case 'CASHIER':
        return const Color(0xFF0284C7);
      case 'TECHNICIAN':
        return const Color(0xFF059669);
      case 'WAITER':
        return const Color(0xFFD97706);
      default:
        return AppColors.primary;
    }
  }

  String _getPermissionLabel(String permCode) {
    switch (permCode) {
      case 'ORDER_WRITE':
        return '开台收银';
      case 'MEMBER_RECHARGE':
        return '开卡储值';
      case 'PRICE_MODIFY':
        return '改价打折';
      case 'ROOM_CONTROL':
        return '房态调度';
      case 'STAFF_SCHEDULE':
        return '排班考勤';
      case 'PERFORMANCE_VIEW':
        return '业绩提成';
      case 'SETTING_VIEW':
        return '店务配置';
      default:
        return permCode;
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请录入员工真实姓名'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (phone.isEmpty || phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请录入正确的11位员工手机号码'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final curStoreId = context.read<StoreProvider>().currentStoreId;
    final newStaff = await widget.staffService.createStaff({
      'realName': name,
      'nickname': _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
      'phone': phone,
      'gender': _selectedGender,
      'department': _deptCtrl.text.trim().isEmpty ? '技术服务部' : _deptCtrl.text.trim(),
      'postName': _postCtrl.text.trim().isEmpty ? '技师' : _postCtrl.text.trim(),
      'role': _selectedRole,
      'baseSalary': double.tryParse(_baseSalaryCtrl.text.trim()),
      'commissionRate': double.tryParse(_commissionCtrl.text.trim()) ?? 0.35,
      'defaultCommissionRate': double.tryParse(_commissionCtrl.text.trim()) ?? 0.35,
      'status': 'ACTIVE',
      'storeId': curStoreId,
    });
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (newStaff != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 员工【${newStaff.realName}】登记成功！已自动继承浏览器【$_selectedRole】权限体系。'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('员工登记失败，请检查网络或确认手机号是否重复'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final curRole = _roles.firstWhere(
      (r) => r.roleCode == _selectedRole,
      orElse: () => StaffRoleInfo(
        roleCode: _selectedRole,
        roleName: _selectedRole,
        description: '系统在册岗位员工',
      ),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '登记新在册员工',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '录入员工档案，权限角色与浏览器后台完全实时一致',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 表单内容区
          Expanded(
            child: _isLoadingConfig
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('正在同步浏览器角色权限与在编岗位...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 14,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. 门店在编岗位快捷选用 (若浏览器有配置)
                        if (_positions.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 6),
                              const Text(
                                '门店在编岗位快速选用',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '共${_positions.length}岗·点选联动角色',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _positions.map((pos) {
                                final pName = pos['postName']?.toString() ?? '';
                                final pDept = pos['department']?.toString() ?? '';
                                final isChosen = _postCtrl.text == pName;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ActionChip(
                                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    avatar: Icon(
                                      isChosen ? Icons.check_circle : Icons.work_outline,
                                      size: 14,
                                      color: isChosen ? Colors.white : AppColors.primary,
                                    ),
                                    label: Text('$pName ($pDept)'),
                                    labelStyle: TextStyle(
                                      fontSize: 11.5,
                                      color: isChosen ? Colors.white : AppColors.textPrimary,
                                      fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    backgroundColor: isChosen ? AppColors.primary : const Color(0xFFF1F5F9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: isChosen ? AppColors.primary : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    onPressed: () => _applyPosition(pos),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 2. 身份基本信息
                        _buildSectionHeader(Icons.badge_outlined, '员工身份基本资料'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: '真实姓名 *',
                                  hintText: '例如: 王金牌',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: '性别',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'MALE', child: Text('男 👨')),
                                  DropdownMenuItem(value: 'FEMALE', child: Text('女 👩')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedGender = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: '登录手机号 *',
                                  hintText: '11位手机号 (用于账号登录)',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone_android_outlined, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _nicknameCtrl,
                                decoration: const InputDecoration(
                                  labelText: '店内艺名 / 称谓',
                                  hintText: '如: 小美 / 8号老师',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.face_outlined, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 3. 组织部门与岗位头衔
                        _buildSectionHeader(Icons.corporate_fare_outlined, '组织归属与岗位编制'),
                        const SizedBox(height: 10),
                        if (_departments.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _departments.map((dept) {
                              final isCurDept = _deptCtrl.text == dept;
                              return ChoiceChip(
                                label: Text(dept),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: isCurDept ? Colors.white : AppColors.textPrimary,
                                ),
                                selected: isCurDept,
                                selectedColor: AppColors.primary,
                                onSelected: (sel) {
                                  if (sel) setState(() => _deptCtrl.text = dept);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _deptCtrl,
                                decoration: const InputDecoration(
                                  labelText: '归属部门',
                                  hintText: '如: 店务管理部 / 技术服务部',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _postCtrl,
                                decoration: const InputDecoration(
                                  labelText: '岗位头衔',
                                  hintText: '如: 资深理疗师 / 首席总监',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 4. 权限体系角色 (核心：与浏览器配置完全一致)
                        _buildSectionHeader(Icons.security_outlined, '权限体系角色 (与浏览器配置完全一致)'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedRole,
                                decoration: InputDecoration(
                                  labelText: '选择权限体系角色',
                                  isDense: true,
                                  border: const OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    _getRoleIcon(_selectedRole),
                                    color: _getRoleColor(_selectedRole),
                                  ),
                                ),
                                items: _roles.map((r) {
                                  return DropdownMenuItem<String>(
                                    value: r.roleCode,
                                    child: Row(
                                      children: [
                                        Icon(_getRoleIcon(r.roleCode), size: 16, color: _getRoleColor(r.roleCode)),
                                        const SizedBox(width: 8),
                                        Text(
                                          r.roleName,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: r.isCustom
                                                ? const Color(0xFFFEF3C7)
                                                : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            r.isCustom ? '已自定义' : '默认模板',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              color: r.isCustom ? const Color(0xFFB45309) : AppColors.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedRole = val);
                                },
                              ),
                              const SizedBox(height: 10),
                              // 角色权限详细说明看板
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '🛡️ 权限范围：${curRole.roleName}',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: _getRoleColor(curRole.roleCode),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${curRole.roleCode})',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      curRole.description.isNotEmpty ? curRole.description : '该角色权限继承自商户后台配置',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: curRole.permissions.map((p) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(curRole.roleCode).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: _getRoleColor(curRole.roleCode).withOpacity(0.25)),
                                          ),
                                          child: Text(
                                            _getPermissionLabel(p),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: _getRoleColor(curRole.roleCode),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 6),
                                    const Row(
                                      children: [
                                        Icon(Icons.sync, size: 12, color: Colors.green),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '已与浏览器端【店员角色与查看权限配置】完全对齐',
                                            style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. 薪资底薪与服务提成
                        _buildSectionHeader(Icons.monetization_on_outlined, '薪资核定与服务提成'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _baseSalaryCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '核定保底月薪 (元/月)',
                                  hintText: '例如: 5000',
                                  prefixText: '￥',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _commissionCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '服务提成比例 (0~1.0)',
                                  hintText: '如 0.35 代表 35%',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),

          // 底部固定操作栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Text('确认登记新员工', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

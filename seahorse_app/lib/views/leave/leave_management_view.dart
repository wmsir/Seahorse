import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../models/leave_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/leave_service.dart';

class LeaveManagementView extends StatefulWidget {
  final int initialTabIndex;
  final bool isEmbedded;

  const LeaveManagementView({Key? key, this.initialTabIndex = 0, this.isEmbedded = false}) : super(key: key);

  @override
  State<LeaveManagementView> createState() => _LeaveManagementViewState();
}

class _LeaveManagementViewState extends State<LeaveManagementView> with SingleTickerProviderStateMixin {
  final LeaveService _leaveService = LeaveService();
  late TabController _tabController;

  List<LeaveApplicationModel> _allLeaves = [];
  bool _isLoading = false;
  String _auditFilterStatus = 'PENDING';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final tabCount = _isManager(auth) ? 2 : 1;
    final initialIndex = widget.initialTabIndex < tabCount ? widget.initialTabIndex : 0;
    _tabController = TabController(length: tabCount, vsync: this, initialIndex: initialIndex);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isManager(AuthProvider auth) {
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _leaveService.getLeaveList();
      if (mounted) {
        setState(() {
          _allLeaves = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _ensureTabControllerSynced(bool isMgr) {
    final targetLength = isMgr ? 2 : 1;
    if (_tabController.length != targetLength) {
      final prevIndex = _tabController.index;
      _tabController.dispose();
      _tabController = TabController(
        length: targetLength,
        vsync: this,
        initialIndex: prevIndex < targetLength ? prevIndex : 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMgr = _isManager(auth);
    _ensureTabControllerSynced(isMgr);

    final myLeaves = _allLeaves.where((l) {
      final myPhone = auth.username.trim();
      final myName = auth.realName.trim();
      if (myPhone.isNotEmpty && l.phone.trim() == myPhone) return true;
      if (myName.isNotEmpty && l.staffName.trim() == myName) return true;
      if (myPhone.isNotEmpty && l.staffName.trim() == myPhone) return true;
      return false; // 严格个人隔离：每个人只能看到自己提交的请假单，绝不展示其他人的单据
    }).toList();

    final pendingAuditCount = _allLeaves.where((l) => l.status.toUpperCase() == 'PENDING').length;

    // isEmbedded 时不渲染独立 AppBar，由父级 TabBarView 管理导航
    if (widget.isEmbedded) {
      return Column(
        children: [
          // Tab 导航条（仅管理员显示审批 tab）
          if (isMgr)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorWeight: 3,
                tabs: [
                  const Tab(text: '我的请假'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('请假审批'),
                        if (pendingAuditCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingAuditCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (isMgr
                        ? TabBarView(
                            controller: _tabController,
                            children: [
                              _buildMyLeaveTab(myLeaves, auth),
                              _buildAuditTab(_allLeaves, auth),
                            ],
                          )
                        : _buildMyLeaveTab(myLeaves, auth)),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('申请请假', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () => _openApplyLeaveDialog(auth),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('员工请假与审批'),
        bottom: isMgr
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorWeight: 3,
                tabs: [
                  const Tab(text: '我的请假'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('请假审批'),
                        if (pendingAuditCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingAuditCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('申请请假', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _openApplyLeaveDialog(auth),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (isMgr
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyLeaveTab(myLeaves, auth),
                    _buildAuditTab(_allLeaves, auth),
                  ],
                )
              : _buildMyLeaveTab(myLeaves, auth)),
    );
  }

  Widget _buildMyLeaveTab(List<LeaveApplicationModel> leaves, AuthProvider auth) {
    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('暂无请假申请记录', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('发起新请假', style: TextStyle(color: Colors.white)),
              onPressed: () => _openApplyLeaveDialog(auth),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
        itemCount: leaves.length,
        itemBuilder: (ctx, index) {
          final item = leaves[index];
          return _buildLeaveCard(item, isMyLeave: true, auth: auth);
        },
      ),
    );
  }

  Widget _buildAuditTab(List<LeaveApplicationModel> allLeaves, AuthProvider auth) {
    final filtered = allLeaves.where((l) {
      if (_auditFilterStatus == 'ALL') return true;
      return l.status.toUpperCase() == _auditFilterStatus;
    }).toList();

    return Column(
      children: [
        // 审批状态过滤条
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              _buildFilterChip('待审批', 'PENDING'),
              const SizedBox(width: 8),
              _buildFilterChip('已通过', 'APPROVED'),
              const SizedBox(width: 8),
              _buildFilterChip('已驳回', 'REJECTED'),
              const SizedBox(width: 8),
              _buildFilterChip('全部', 'ALL'),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('暂无相关审批记录', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      return _buildLeaveCard(item, isMyLeave: false, auth: auth);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _auditFilterStatus == value;
    return InkWell(
      onTap: () => setState(() => _auditFilterStatus = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveCard(LeaveApplicationModel item, {required bool isMyLeave, required AuthProvider auth}) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部类型与状态
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.leaveTypeName,
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.totalDays}天 (${item.totalHours}小时)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: item.statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    item.statusText,
                    style: TextStyle(color: item.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 员工信息 (主管审核视角)
            if (!isMyLeave) ...[
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${item.staffName} · ${item.postName}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 8),
                  Text(item.department, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // 请假起止时间
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${item.startTime} 至 ${item.endTime}',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 请假事由
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '事由: ${item.reason}',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
              ),
            ),

            // 审批反馈批注
            if (item.auditNotes != null && item.auditNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.statusColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '审批意见: ${item.auditNotes} (${item.currentApprover})',
                  style: TextStyle(fontSize: 11.5, color: item.statusColor, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),

            // 操作栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 查看进度流程
                TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                  icon: const Icon(Icons.timeline, size: 16, color: AppColors.primary),
                  label: const Text('流转进度', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  onPressed: () => _showTimelineDialog(item),
                ),

                // 动作按钮群
                Row(
                  children: [
                    // 员工视角操作：撤销申请
                    if (isMyLeave && item.canRevoke) ...[
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        onPressed: () => _confirmRevokeLeave(item, auth),
                        child: const Text('撤销申请', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // 员工视角操作：编辑重新提交
                    if (isMyLeave && item.canEdit) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _openEditLeaveDialog(item),
                        child: const Text('修改重提', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ],

                    // 店长/主管视角操作：审批 (同意/驳回)
                    if (!isMyLeave && item.status.toUpperCase() == 'PENDING') ...[
                      if ((auth.realName.isNotEmpty && item.staffName == auth.realName) ||
                          (auth.username.isNotEmpty && (item.phone == auth.username || item.staffName == auth.username))) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Text('本人申请 (禁止自批)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                        ),
                      ] else ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          onPressed: () => _openAuditDialog(item, 'REJECT', auth),
                          child: const Text('驳回', style: TextStyle(fontSize: 12, color: AppColors.error)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _openAuditDialog(item, 'APPROVE', auth),
                          child: const Text('同意通过', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 1. 发起请假申请弹窗
  void _openApplyLeaveDialog(AuthProvider auth) {
    String selectedType = 'PERSONAL';
    DateTime startDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    DateTime endDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
    final reasonCtrl = TextEditingController();
    double totalDays = 1.0;
    double totalHours = 8.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final startStr = '${DateFormat('yyyy-MM-dd').format(startDate)} ${startTime.format(context)}';
            final endStr = '${DateFormat('yyyy-MM-dd').format(endDate)} ${endTime.format(context)}';

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('📝 员工请假申请单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 请假类型选择
                    const Text('请假类型 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTypeOption('事假', 'PERSONAL', selectedType, (v) => setSheetState(() => selectedType = v)),
                        _buildTypeOption('病假', 'SICK', selectedType, (v) => setSheetState(() => selectedType = v)),
                        _buildTypeOption('带薪年假', 'ANNUAL', selectedType, (v) => setSheetState(() => selectedType = v)),
                        _buildTypeOption('加班调休', 'COMPENSATORY', selectedType, (v) => setSheetState(() => selectedType = v)),
                        _buildTypeOption('婚假', 'MARRIAGE', selectedType, (v) => setSheetState(() => selectedType = v)),
                        _buildTypeOption('产假/陪产', 'MATERNITY', selectedType, (v) => setSheetState(() => selectedType = v)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 开始时间选择
                    const Text('请假开始时间 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(context: context, initialTime: startTime);
                          if (pickedTime != null) {
                            setSheetState(() {
                              startDate = pickedDate;
                              startTime = pickedTime;
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(startStr, style: const TextStyle(fontSize: 13)),
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 结束时间选择
                    const Text('请假结束时间 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(context: context, initialTime: endTime);
                          if (pickedTime != null) {
                            setSheetState(() {
                              endDate = pickedDate;
                              endTime = pickedTime;
                              final diff = endDate.difference(startDate).inDays;
                              totalDays = diff <= 0 ? 1.0 : (diff + 1).toDouble();
                              totalHours = totalDays * 8.0;
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(endStr, style: const TextStyle(fontSize: 13)),
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 时长与天数核算
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('请假天数 (天)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              TextFormField(
                                initialValue: totalDays.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                onChanged: (v) => totalDays = double.tryParse(v) ?? totalDays,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('换算工时 (小时)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              TextFormField(
                                initialValue: totalHours.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                onChanged: (v) => totalHours = double.tryParse(v) ?? totalHours,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 请假事由
                    const Text('请假具体事由 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: '请详述请假原因及交接安排',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 审批流程节点预览
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.account_tree_outlined, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text('请假审批流程节点链路', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            ],
                          ),
                          const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildStepBadge('1. 提交申请', '员工发起', true),
                                const Icon(Icons.arrow_forward_ios, size: 11, color: Colors.grey),
                                _buildStepBadge('2. 门店初审', '门店店长', false),
                                const Icon(Icons.arrow_forward_ios, size: 11, color: Colors.grey),
                                _buildStepBadge('3. 归档生效', '人事备案', false),
                              ],
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            '📌 规则说明：提交后将流转至店长审批队列，发起人本人不可审批自己的请假单。',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 提交按钮
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final reason = reasonCtrl.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写请假事由')));
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            final myPhone = auth.username.trim();
                            final myName = auth.realName.trim().isNotEmpty ? auth.realName.trim() : myPhone;
                            final created = await _leaveService.applyLeave(
                              staffId: 1,
                              staffName: myName,
                              phone: myPhone,
                              postName: auth.role == 'STORE_MANAGER' ? '店长' : '专业技师',
                              department: '门店服务部',
                              leaveType: selectedType,
                              startTime: startStr,
                              endTime: endStr,
                              totalHours: totalHours,
                              totalDays: totalDays,
                              reason: reason,
                            );
                            if (mounted) {
                              setState(() {
                                _allLeaves.removeWhere((l) => l.id == created.id);
                                _allLeaves.insert(0, created);
                              });
                              if (_isManager(auth)) {
                                _tabController.animateTo(0);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('🎉 请假申请已提交，等待主管审批！'), backgroundColor: AppColors.success),
                              );
                              await _loadData();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e')));
                            }
                          }
                        },
                        child: const Text('立即提交审批', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reasonCtrl.dispose();
      });
    });
  }

  Widget _buildTypeOption(String label, String value, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155), fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (_) => onSelect(value),
    );
  }

  Widget _buildStepBadge(String title, String sub, bool isCurrent) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isCurrent ? AppColors.primary : Colors.grey.shade300),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCurrent ? Colors.white : const Color(0xFF334155)),
            ),
          ),
          const SizedBox(height: 2),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // 2. 撤销请假申请确认
  void _confirmRevokeLeave(LeaveApplicationModel item, AuthProvider auth) {
    final reasonCtrl = TextEditingController(text: '个人计划调整，撤销此次请假');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Text('撤销请假确认', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('确定撤回【${item.leaveTypeName}】(${item.startTime} 至 ${item.endTime}) 的申请吗？'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: '撤回说明',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                Navigator.pop(ctx);
                try {
                  await _leaveService.revokeLeave(
                    leaveId: item.id,
                    staffName: auth.realName.isNotEmpty ? auth.realName : auth.username,
                    reason: reason,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ 请假申请已撤回'), backgroundColor: AppColors.success),
                  );
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('撤回失败: $e')));
                }
              },
              child: const Text('确认撤回', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reasonCtrl.dispose();
      });
    });
  }

  // 3. 编辑请假申请
  void _openEditLeaveDialog(LeaveApplicationModel item) {
    String selectedType = item.leaveType;
    final reasonCtrl = TextEditingController(text: item.reason);
    double totalDays = item.totalDays;
    double totalHours = item.totalHours;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('✏️ 修改请假申请并重提', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTypeOption('事假', 'PERSONAL', selectedType, (v) => setSheetState(() => selectedType = v)),
                        _buildTypeOption('病假', 'SICK', selectedType, (v) => setSheetState(() => selectedType = v)),
                        _buildTypeOption('带薪年假', 'ANNUAL', selectedType, (v) => setSheetState(() => selectedType = v)),
                        _buildTypeOption('加班调休', 'COMPENSATORY', selectedType, (v) => setSheetState(() => selectedType = v)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('当前时间段: ${item.startTime} 至 ${item.endTime}', style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                    const SizedBox(height: 12),
                    const Text('修改事由说明 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () async {
                          final newReason = reasonCtrl.text.trim();
                          if (newReason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('事由不能为空')));
                            return;
                          }
                          Navigator.pop(ctx);
                          try {
                            await _leaveService.updateLeave(
                              leaveId: item.id,
                              leaveType: selectedType,
                              startTime: item.startTime,
                              endTime: item.endTime,
                              totalHours: totalHours,
                              totalDays: totalDays,
                              reason: newReason,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ 申请已重新提交审批'), backgroundColor: AppColors.success),
                            );
                            _loadData();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e')));
                          }
                        },
                        child: const Text('确认并重新提交', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        reasonCtrl.dispose();
      });
    });
  }

  // 4. 主管审批弹窗 (同意/驳回)
  void _openAuditDialog(LeaveApplicationModel item, String action, AuthProvider auth) {
    if (!_isManager(auth)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('权限受限：普通员工无权审批他人请假工单！'), backgroundColor: AppColors.error),
      );
      return;
    }
    final isSelf = (auth.realName.isNotEmpty && item.staffName == auth.realName) ||
                   (auth.username.isNotEmpty && (item.phone == auth.username || item.staffName == auth.username));
    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('权限受限：员工不可自行审批本人发起的请假申请！'), backgroundColor: AppColors.error),
      );
      return;
    }

    final isApprove = action == 'APPROVE';
    final notesCtrl = TextEditingController(text: isApprove ? '同意请假申请，请提前交接好手头客户' : '因当天门店预约客流高峰，建议顺延调休');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(
                isApprove ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isApprove ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(isApprove ? '同意请假审批' : '驳回请假审批', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('申请人：${item.staffName} (${item.postName})'),
              const SizedBox(height: 4),
              Text('类型：${item.leaveTypeName} · ${item.totalDays}天'),
              const SizedBox(height: 4),
              Text('事由：${item.reason}'),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: isApprove ? '审批批注 (选填)' : '驳回原因 (必填)',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isApprove ? AppColors.success : AppColors.error),
              onPressed: () async {
                final notes = notesCtrl.text.trim();
                Navigator.pop(ctx);
                final userName = auth.realName.isNotEmpty ? auth.realName : (auth.username.isNotEmpty ? auth.username : '店长');
                final userRole = (auth.role == 'SUPER_ADMIN' || auth.role == 'TENANT_ADMIN') ? '总负责人/老板' : '店长';
                final approverStr = (userName.contains('(') || userName.contains('（')) ? userName : '$userName ($userRole)';
                try {
                  await _leaveService.auditLeave(
                    leaveId: item.id,
                    action: action,
                    approver: approverStr,
                    auditNotes: notes,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isApprove ? '🎉 已同意该请假申请' : '✓ 已驳回该请假申请'),
                      backgroundColor: isApprove ? AppColors.success : AppColors.error,
                    ),
                  );
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('审批操作失败: $e')));
                }
              },
              child: Text(isApprove ? '确认同意' : '确认驳回', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notesCtrl.dispose();
      });
    });
  }

  // 5. 流转进度查看
  void _showTimelineDialog(LeaveApplicationModel item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.account_tree_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('审批流程跟踪 · ${item.leaveTypeName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: item.timeline.length,
              itemBuilder: (ctx, i) {
                final node = item.timeline[i];
                final isSuccess = node.status == 'SUCCESS';
                final isCurrent = node.status == 'CURRENT';
                final isReject = node.status == 'REJECTED';

                Color dotColor = Colors.grey.shade400;
                IconData dotIcon = Icons.circle;
                if (isSuccess) {
                  dotColor = AppColors.success;
                  dotIcon = Icons.check_circle;
                } else if (isCurrent) {
                  dotColor = AppColors.warning;
                  dotIcon = Icons.timelapse;
                } else if (isReject) {
                  dotColor = AppColors.error;
                  dotIcon = Icons.cancel;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(dotIcon, size: 20, color: dotColor),
                        if (i < item.timeline.length - 1)
                          Container(width: 2, height: 40, color: Colors.grey.shade300),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(node.stepName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(node.time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('操作人: ${node.operator}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          if (node.comment.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(node.comment, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                          ],
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
          ],
        );
      },
    );
  }
}

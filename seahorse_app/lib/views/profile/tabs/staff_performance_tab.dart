import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../providers/space_provider.dart';
import '../../../services/staff_service.dart';
import '../../../models/space_model.dart';
import 'package:provider/provider.dart';
import '../../attendance/attendance_check_in_view.dart';

class StaffPerformanceTab extends StatefulWidget {
  const StaffPerformanceTab({Key? key}) : super(key: key);

  @override
  State<StaffPerformanceTab> createState() => _StaffPerformanceTabState();
}

class _StaffPerformanceTabState extends State<StaffPerformanceTab> {
  final StaffService _staffService = StaffService();
  bool _isOnDuty = true;
  bool _isUpdatingDuty = false;
  int? _currentStaffId;
  bool _isLoadingCommissions = false;
  List<Map<String, dynamic>> _commissionRecords = [];
  String? _lastStoreId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.watch<StoreProvider>();
    if (_lastStoreId != store.currentStoreId) {
      _lastStoreId = store.currentStoreId;
      _loadPerformance();
    }
  }

  Future<void> _loadPerformance() async {
    if (!mounted) return;
    setState(() => _isLoadingCommissions = true);
    try {
      final auth = context.read<AuthProvider>();
      final store = context.read<StoreProvider>();
      final results = await Future.wait([
        _staffService.getStaffCommissions(
          employeeName: auth.realName,
          storeId: store.currentStoreId,
        ),
        _staffService.getStaffList(storeId: store.currentStoreId),
      ]);
      final list = results[0] as List<Map<String, dynamic>>;
      final staffList = results[1] as List;
      int? matchedId;
      bool? matchedDuty;
      for (final dynamic item in staffList) {
        final sUsername = (item.username ?? '').toString();
        final sPhone = (item.phone ?? '').toString();
        final sRealName = (item.realName ?? '').toString();
        if ((auth.username.isNotEmpty && (sUsername == auth.username || sPhone == auth.username)) ||
            (auth.realName.isNotEmpty && sRealName == auth.realName)) {
          matchedId = item.id as int?;
          final st = (item.status ?? 'ACTIVE').toString().toUpperCase();
          matchedDuty = st != 'REST' && st != 'OFF_DUTY' && st != 'DISABLED' && st != 'INACTIVE';
          break;
        }
      }
      if (mounted) {
        setState(() {
          _commissionRecords = list;
          if (matchedId != null) {
            _currentStaffId = matchedId;
          }
          if (matchedDuty != null) {
            _isOnDuty = matchedDuty;
          }
          _isLoadingCommissions = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCommissions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreProvider>();
    final spaceProv = context.watch<SpaceProvider>();
    final displayName = auth.realName.isNotEmpty ? auth.realName : '在册员工 (我)';
    final roleName = auth.role == 'TECHNICIAN'
        ? '专业技师'
        : (auth.role == 'WAITER' ? '楼面主管' : (auth.role == 'STORE_MANAGER' ? '店长' : '门店服务专家'));

    // 计算今日真实业绩与提成
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final todayRecords = _commissionRecords.where((r) {
      final ca = (r['createdAt'] ?? '').toString();
      return ca.startsWith(todayStr);
    }).toList();

    final todayCount = todayRecords.length;
    final todayCommission = todayRecords.fold<double>(
      0.0,
      (sum, r) => sum + ((r['commissionAmount'] as num?)?.toDouble() ?? 0.0),
    );
    final todayBaseAmount = todayRecords.fold<double>(
      0.0,
      (sum, r) => sum + ((r['baseAmount'] as num?)?.toDouble() ?? 0.0),
    );
    final totalCommissions = _commissionRecords.fold<double>(
      0.0,
      (sum, r) => sum + ((r['commissionAmount'] as num?)?.toDouble() ?? 0.0),
    );

    // 检索当前正在服务的工位 (严格匹配当前员工姓名或账号，绝不误展示其他员工工位)
    final occupiedSpaces = spaceProv.spaces.where((s) => s.status == SpaceStatus.occupied).toList();
    SpaceModel? activeServingSpace;
    for (final s in occupiedSpaces) {
      if ((auth.realName.isNotEmpty && s.currentTechnicianName == auth.realName) ||
          (auth.username.isNotEmpty && s.currentTechnicianName == auth.username)) {
        activeServingSpace = s;
        break;
      }
    }

    return RefreshIndicator(
      onRefresh: _loadPerformance,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 个人在岗名片与打卡状态
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(
                            displayName.isNotEmpty ? displayName.substring(0, 1) : '工',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      roleName,
                                      style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '门店: ${store.currentStoreName} · 账号: ${auth.username}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primary, size: 20),
                          tooltip: '刷新提成流水',
                          onPressed: _loadPerformance,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isOnDuty ? Icons.check_circle : Icons.pause_circle_outline,
                              color: _isOnDuty ? Colors.green : Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnDuty ? '当前在岗状态：🟢 空闲待工 (随时可排班接单)' : '当前在岗状态：🟡 暂离休息 (暂不排单)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isOnDuty ? Colors.green.shade800 : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isOnDuty,
                          activeColor: Colors.green,
                          onChanged: _isUpdatingDuty
                              ? null
                              : (val) async {
                                  final prev = _isOnDuty;
                                  setState(() {
                                    _isOnDuty = val;
                                    _isUpdatingDuty = true;
                                  });
                                  bool ok = true;
                                  if (_currentStaffId != null && _currentStaffId! > 0) {
                                    ok = await _staffService.updateStaffStatus(
                                      _currentStaffId!,
                                      val ? 'ACTIVE' : 'REST',
                                    );
                                  }
                                  if (!mounted) return;
                                  setState(() => _isUpdatingDuty = false);
                                  if (!ok) {
                                    setState(() => _isOnDuty = prev);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('同步在岗状态至服务器失败，请稍后重试'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(val ? '已同步状态为：🟢 空闲在岗' : '已同步状态为：🟡 暂离休息'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. 门店定位考勤打卡快捷入口
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pin_drop, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 门店高精度定位考勤打卡',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '有效半径 500米 · 支持上下班与外勤报备',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendanceCheckInView()),
                      );
                    },
                    child: const Text('去打卡', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. 今日真实服务与业绩统计
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💼 今日真实业绩与提成看板',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (_isLoadingCommissions)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    '今日完工接单',
                    '$todayCount 钟次',
                    Icons.timer_outlined,
                    AppColors.primary,
                    todayCount > 0 ? '完成 $todayCount 单服务履约' : '今日暂无结单记钟',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    '今日预计提成',
                    '¥${todayCommission.toStringAsFixed(2)}',
                    Icons.monetization_on_outlined,
                    AppColors.success,
                    totalCommissions > 0 ? '累计提成 ¥${totalCommissions.toStringAsFixed(2)}' : '真实结账分成自动入账',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    '服务业绩基数',
                    '¥${todayBaseAmount.toStringAsFixed(2)}',
                    Icons.account_balance_wallet_outlined,
                    const Color(0xFFD97706),
                    todayBaseAmount > 0 ? '产生实收消费流水' : '按实际结账项目核算',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    '出勤与在岗状态',
                    _isOnDuty ? '🟢 正常在岗' : '🟡 暂离休息',
                    Icons.verified_user_outlined,
                    Colors.teal,
                    '工号在册 · 随时可派单',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 4. 当前服务工位 (动态读取房态)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.room_service_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('当前正在服务的工位', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (activeServingSpace != null ? Colors.amber : Colors.green).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activeServingSpace != null ? '服务进行中' : '空闲可排单',
                            style: TextStyle(
                              color: activeServingSpace != null ? const Color(0xFFD97706) : Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (activeServingSpace != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.meeting_room, color: AppColors.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${activeServingSpace.spaceName} (${activeServingSpace.floorZone})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '顾客: ${activeServingSpace.currentCustomerName ?? "现场到店客户"} · 已上钟 ${activeServingSpace.servedMinutes} 分钟 · 消费账单 ¥${activeServingSpace.currentBillAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '当前在册工位均处于空闲状态，随时可为新到店顾客接单排钟！',
                                style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. 真实完结工单与分成记录
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, color: AppColors.secondary, size: 20),
                            SizedBox(width: 8),
                            Text('完工清单与实结提成流水', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          '共 ${_commissionRecords.length} 笔记录',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingCommissions)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_commissionRecords.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                        child: Column(
                          children: const [
                            Icon(Icons.assignment_turned_in_outlined, size: 40, color: AppColors.textMuted),
                            SizedBox(height: 10),
                            Text(
                              '今日暂无结单提成记录',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '前台或APP收银完成订单划付结算后，您的分成流水将在此毫秒级同步入账！',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _commissionRecords.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (ctx, idx) {
                          final r = _commissionRecords[idx];
                          final timeStr = (r['createdAt'] ?? '').toString();
                          final displayTime = timeStr.length >= 16 ? timeStr.substring(11, 16) : '-';
                          final title = r['notes'] ?? '服务项目会话工单分成';
                          final orderNo = r['billingOrderId'] != null ? '单号 #${r['billingOrderId']}' : '收银核销';
                          final comm = ((r['commissionAmount'] as num?)?.toDouble() ?? 0.0);
                          final statusText = r['status'] == 'SETTLED' ? '已核发' : '已入账';
                          return _buildOrderItem(displayTime, title, orderNo, comm.toStringAsFixed(2), statusText);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(String time, String title, String room, String commission, String status) {
    return Row(
      children: [
        Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$room · 状态: $status', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('+$commission', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
            const Text('提成入账', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }
}

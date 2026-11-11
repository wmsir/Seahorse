import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/chinese_date_utils.dart';
import '../../models/dashboard_stats_model.dart';
import '../../services/dashboard_service.dart';
import '../scanner/camera_scanner_view.dart';
import '../../providers/store_provider.dart';
import '../../providers/space_provider.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/status_badge.dart';
import '../spaces/open_space_sheet.dart';
import '../spaces/space_detail_dialog.dart';
import '../appointments/create_appointment_sheet.dart';
import '../appointments/appointments_view.dart';
import '../members/member_create_dialog.dart';
import '../members/members_view.dart';
import '../cashier/cashier_view.dart';

class DashboardView extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const DashboardView({Key? key, this.onNavigateTab}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final DashboardService _dashboardService = DashboardService();
  DashboardStatsModel _stats = DashboardStatsModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = context.read<StoreProvider>().currentStoreId;
      context.read<SpaceProvider>().loadSpaces(storeId);
      context.read<AppointmentProvider>().loadAppointments(storeId);
      _loadDashboardStats();
    });
  }

  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    final storeId = context.read<StoreProvider>().currentStoreId;
    final stats = await _dashboardService.getStats(storeId: storeId);
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  void _showStoreSwitcher() {
    final storeProv = context.read<StoreProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🏬 切换当前经营门店', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...storeProv.stores.map((s) {
                final isSelected = s.storeId == storeProv.currentStoreId;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(s.industry.emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  title: Text(s.storeName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text('${s.industryCategoryName} · ${s.address}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await storeProv.switchStore(s.storeId, context: context);
                    if (mounted) {
                      _loadDashboardStats();
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final spaceProv = context.watch<SpaceProvider>();
    final aptProv = context.watch<AppointmentProvider>();
    final stats = _stats;

    final activeSpaces = spaceProv.spaces.where((s) => s.status == SpaceStatus.occupied).toList();
    final todayPendingApts = aptProv.appointments.where((a) => a.status == AppointmentStatus.pending).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          onTap: _showStoreSwitcher,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(store.currentStore?.industry.emoji ?? '🏬', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    store.currentStoreName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: '切换门店',
            onPressed: _showStoreSwitcher,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDashboardStats();
          await spaceProv.loadSpaces(store.currentStoreId);
          await aptProv.loadAppointments(store.currentStoreId);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 中国日期与传统节日欢迎条
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_note, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ChineseDateUtils.formatFullChineseDate(DateTime.now()),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('正常营业中', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // 核心运行大盘 2x2 指标卡 (实时服务端真实计算)
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: '今日营业流水',
                      value: Formatters.currency(stats.todayRevenue),
                      subtitle: '已核销 ${stats.todayOrderCount} 笔订单',
                      icon: Icons.monetization_on_outlined,
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      title: '在场服务履约',
                      value: '${stats.activeSessions} 场在服',
                      subtitle: '今日完成 ${stats.todayOrderCount} 笔结算',
                      icon: Icons.groups_outlined,
                      iconColor: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: '在场${store.spaceAlias}',
                      value: '${spaceProv.occupiedCount} / ${spaceProv.spaces.length}',
                      subtitle: '使用率 ${spaceProv.occupancyRate.toStringAsFixed(1)}%',
                      icon: Icons.hotel_outlined,
                      iconColor: AppColors.success,
                      onTap: () => widget.onNavigateTab?.call(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MetricCard(
                      title: '会员与提成',
                      value: '${stats.totalMembers} 位会员',
                      subtitle: '今日提成 ${Formatters.currency(stats.todayCommissions)}',
                      icon: Icons.credit_card_outlined,
                      iconColor: AppColors.warning,
                      onTap: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(3);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersView()));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 快捷业务操作中枢
              const Text('⚡ 快捷店务办理中枢', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionItem(
                    icon: Icons.meeting_room,
                    label: '快速开台',
                    color: AppColors.primary,
                    onTap: () {
                      if (spaceProv.spaces.isNotEmpty) {
                        final idleSpace = spaceProv.spaces.firstWhere(
                          (s) => s.status == SpaceStatus.idle,
                          orElse: () => spaceProv.spaces.first,
                        );
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => OpenSpaceSheet(space: idleSpace),
                        );
                      }
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.calendar_month,
                    label: '登记预约',
                    color: AppColors.info,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const CreateAppointmentSheet(),
                      );
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.point_of_sale,
                    label: '结账收银',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CashierView()));
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.person_add_alt_1,
                    label: '会员开卡',
                    color: AppColors.warning,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const MemberCreateDialog(),
                      );
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.qr_code_scanner,
                    label: '扫码盒子',
                    color: Colors.purple,
                    onTap: () async {
                      final res = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CameraScannerView(purpose: ScanPurpose.payment)),
                      );
                      if (res != null && res['success'] == true && mounted) {
                        final typeDesc = res['scanType'] ?? (res['isMemberCode'] == true ? '会员专属码' : '条码/付款码');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📷 扫码盒子识别成功: $typeDesc [${res['code']}]'),
                            backgroundColor: res['isMemberCode'] == true ? const Color(0xFF0D9488) : AppColors.success,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 在场服务动态实时监控
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🛎️ 在场服务中 (${activeSpaces.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => widget.onNavigateTab?.call(1),
                    child: const Text('查看全部房态 >'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (activeSpaces.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(child: Text('当前暂无服务中包厢，全部工位随时可接客')),
                )
              else
                ...activeSpaces.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.info.withOpacity(0.12),
                      child: Text(s.spaceCode, style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    title: Text('${s.spaceName} · ${s.currentCustomerName}'),
                    subtitle: Text('技师: ${s.currentTechnicianName} · 已上钟 ${s.servedMinutes} 分钟'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Formatters.currency(s.currentBillAmount),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => SpaceDetailDialog(space: s),
                      );
                      if (context.mounted) {
                        final storeId = context.read<StoreProvider>().currentStoreId;
                        context.read<SpaceProvider>().loadSpaces(storeId);
                        _loadDashboardStats();
                      }
                    },
                  ),
                )),

              const SizedBox(height: 24),

              // 今日待到店预约排班
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📅 近期预约排班 (${aptProv.pendingCount} 待到店)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsView()));
                    },
                    child: const Text('查看完整排班 >'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (todayPendingApts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text('今日暂无待到店预约排班', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('快速登记预约'),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const CreateAppointmentSheet(),
                          );
                        },
                      ),
                    ],
                  ),
                )
              else
                ...todayPendingApts.map((a) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                      child: Text(a.aptTime, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                    title: Text('${a.customerName} · ${a.serviceName}'),
                    subtitle: Text('技师: ${a.staffName} · 预留: ${a.spaceName}'),
                    trailing: StatusBadge(
                      label: a.status.label,
                      textColor: a.status.color,
                      backgroundColor: a.status.bgColor,
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsView()));
                    },
                  ),
                )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

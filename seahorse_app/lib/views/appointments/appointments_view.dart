import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/chinese_date_utils.dart';
import '../../models/appointment_model.dart';
import '../../models/space_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/space_provider.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/chinese_holiday_calendar_dialog.dart';
import '../../core/utils/phone_caller.dart';
import 'create_appointment_sheet.dart';

class AppointmentsView extends StatefulWidget {
  const AppointmentsView({Key? key}) : super(key: key);

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeId = context.read<StoreProvider>().currentStoreId;
      context.read<AppointmentProvider>().loadAppointments(storeId);
      context.read<SpaceProvider>().loadSpaces(storeId);
    });
  }

  bool _isQuickChip(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    return diff >= 0 && diff <= 2;
  }

  void _openCreateSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateAppointmentSheet(),
    );
    if (result == true) {
      final storeId = context.read<StoreProvider>().currentStoreId;
      context.read<AppointmentProvider>().loadAppointments(storeId);
    }
  }

  void _checkInCustomer(AppointmentModel apt) async {
    final store = context.read<StoreProvider>();
    final spaceProv = context.read<SpaceProvider>();
    final aptProv = context.read<AppointmentProvider>();

    SpaceModel? targetSpace;
    if (spaceProv.spaces.isNotEmpty) {
      targetSpace = spaceProv.spaces.firstWhere(
        (s) => s.spaceCode == apt.spaceCode,
        orElse: () => spaceProv.spaces.first,
      );
    }

    if (targetSpace == null) {
      await spaceProv.loadSpaces(store.currentStoreId);
      if (spaceProv.spaces.isNotEmpty) {
        targetSpace = spaceProv.spaces.first;
      }
    }

    final ok = await aptProv.checkIn(
      apt.id,
      spaceId: targetSpace?.id,
      aptNo: apt.aptNo,
      storeId: store.currentStoreId,
    );

    if (ok) {
      await spaceProv.loadSpaces(store.currentStoreId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('顾客【${apt.customerName}】已核销到店并安排入座【${targetSpace?.spaceName ?? "默认展位"}】！展位与预约已同步变为【服务中】。'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('到店接待失败，请检查网络或核对预约记录'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _finishService(AppointmentModel apt) async {
    final storeId = context.read<StoreProvider>().currentStoreId;
    await context.read<AppointmentProvider>().updateStatus(apt.id, AppointmentStatus.completed, storeId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('预约工单【${apt.aptNo}】已完成服务！'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final aptProv = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('预约排班与到店履约'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => aptProv.loadAppointments(store.currentStoreId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('登记新预约', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openCreateSheet,
      ),
      body: Column(
        children: [
          // 日期横向快捷选择栏
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDateChip(ChineseDateUtils.getRelativeFriendlyDate(DateTime.now()), DateTime.now(), aptProv, store.currentStoreId),
                  const SizedBox(width: 8),
                  _buildDateChip(ChineseDateUtils.getRelativeFriendlyDate(DateTime.now().add(const Duration(days: 1))), DateTime.now().add(const Duration(days: 1)), aptProv, store.currentStoreId),
                  const SizedBox(width: 8),
                  _buildDateChip(ChineseDateUtils.getRelativeFriendlyDate(DateTime.now().add(const Duration(days: 2))), DateTime.now().add(const Duration(days: 2)), aptProv, store.currentStoreId),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.event_note, size: 16),
                    label: Text(
                      _isQuickChip(aptProv.selectedDate)
                          ? '节假日日历 📅'
                          : ChineseDateUtils.formatShortChineseDate(aptProv.selectedDate),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isQuickChip(aptProv.selectedDate) ? const Color(0xFFF1F5F9) : AppColors.primary,
                      foregroundColor: _isQuickChip(aptProv.selectedDate) ? AppColors.textPrimary : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _isQuickChip(aptProv.selectedDate) ? const Color(0xFFCBD5E1) : AppColors.primary,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await ChineseHolidayCalendarDialog.show(
                        context,
                        initialDate: aptProv.selectedDate,
                        title: '预约排班与履约 · 中华节假日日历',
                      );
                      if (picked != null) {
                        aptProv.setDate(picked, store.currentStoreId);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // 状态筛选 Tab
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Row(
              children: [
                _buildStatusTab('全部 (${aptProv.appointments.length})', null, aptProv),
                const SizedBox(width: 8),
                _buildStatusTab('待到店 (${aptProv.pendingCount})', AppointmentStatus.pending, aptProv),
                const SizedBox(width: 8),
                _buildStatusTab('服务中 (${aptProv.servingCount})', AppointmentStatus.serving, aptProv),
                const SizedBox(width: 8),
                _buildStatusTab('已完成 (${aptProv.completedCount})', AppointmentStatus.completed, aptProv),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // 预约工单列表
          Expanded(
            child: aptProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : aptProv.filteredAppointments.isEmpty
                    ? EmptyState(
                        title: '当日暂无对应预约工单',
                        subtitle: '点击右下角按钮即可快速登记到店新预约',
                        icon: Icons.calendar_today_outlined,
                        actionLabel: '+ 登记新预约',
                        onAction: _openCreateSheet,
                      )
                    : RefreshIndicator(
                        onRefresh: () => aptProv.loadAppointments(store.currentStoreId),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: aptProv.filteredAppointments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final apt = aptProv.filteredAppointments[idx];
                            return _buildAppointmentCard(apt);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, DateTime date, AppointmentProvider aptProv, String storeId) {
    final isSelected = aptProv.selectedDate.year == date.year &&
        aptProv.selectedDate.month == date.month &&
        aptProv.selectedDate.day == date.day;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => aptProv.setDate(date, storeId),
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatusTab(String label, AppointmentStatus? status, AppointmentProvider aptProv) {
    final isSelected = aptProv.filterStatus == status;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => aptProv.setStatusFilter(status),
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel apt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：单号、预约时间与状态
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        apt.aptTime,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      apt.aptNo,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                StatusBadge(
                  label: apt.status.label,
                  textColor: apt.status.color,
                  backgroundColor: apt.status.bgColor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 顾客与服务项目
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${apt.customerName} (${Formatters.maskPhone(apt.phone)})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    if (apt.phone.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => PhoneCaller.call(context, apt.phone, targetName: apt.customerName),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.phone_in_talk, size: 13, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                    if (apt.peopleCount > 1) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(3)),
                        child: Text('${apt.peopleCount}人', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ),
                    ],
                  ],
                ),
                Text(
                  Formatters.currency(apt.servicePrice),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('项目：${apt.serviceName}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('技师：${apt.staffName ?? '未指定'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(width: 16),
                Text('预留：${apt.spaceName ?? '未分配'}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            if (apt.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('备注：${apt.notes}', style: const TextStyle(fontSize: 12, color: AppColors.warning)),
            ],

            const Divider(height: 18),

            // 操作栏
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (apt.status == AppointmentStatus.pending) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('顾客到店 · 一键开台入座'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () => _checkInCustomer(apt),
                  ),
                ] else if (apt.status == AppointmentStatus.serving) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('完成服务'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    onPressed: () => _finishService(apt),
                  ),
                ] else ...[
                  const Text('已完成履约', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

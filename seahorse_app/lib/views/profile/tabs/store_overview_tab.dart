import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/phone_caller.dart';
import '../../../models/store_model.dart';
import '../../../models/dashboard_stats_model.dart';
import '../../../providers/store_provider.dart';
import '../../../services/dashboard_service.dart';
import '../../../services/notice_service.dart';
import '../../../services/sound_service.dart';
import '../../../services/notification_poll_service.dart';
import '../../widgets/notice_detail_modal.dart';
import '../../leave/leave_management_view.dart';
import '../../members/members_view.dart';

class StoreOverviewTab extends StatefulWidget {
  final StoreModel? currentStore;
  final VoidCallback onShowStoreSwitcher;

  const StoreOverviewTab({
    Key? key,
    required this.currentStore,
    required this.onShowStoreSwitcher,
  }) : super(key: key);

  @override
  State<StoreOverviewTab> createState() => _StoreOverviewTabState();
}

class _StoreOverviewTabState extends State<StoreOverviewTab> {
  final DashboardService _dashboardService = DashboardService();
  final NoticeService _noticeService = NoticeService();

  DashboardStatsModel? _stats;
  List<StoreNoticeModel> _notices = [];
  bool _loadingStats = true;
  bool _loadingNotices = true;
  String _lastLoadedStoreId = '';
  Function(StoreNoticeModel notice)? _prevNoticeCallback;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
    _prevNoticeCallback = NotificationPollService().onNoticeCallback;
    NotificationPollService().onNoticeCallback = (notice) {
      if (_prevNoticeCallback != null) {
        _prevNoticeCallback!(notice);
      }
      if (mounted) {
        _reloadNoticesOnly();
      }
    };
  }

  @override
  void dispose() {
    NotificationPollService().onNoticeCallback = _prevNoticeCallback;
    super.dispose();
  }

  Future<void> _reloadNoticesOnly() async {
    final storeProv = Provider.of<StoreProvider>(context, listen: false);
    final storeId = widget.currentStore?.storeId ?? storeProv.currentStoreId;
    final notices = await _noticeService.getStoreNotices(storeId);
    if (mounted) {
      setState(() {
        _notices = notices;
        _loadingNotices = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant StoreOverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentStoreId = widget.currentStore?.storeId ?? '';
    if (currentStoreId != _lastLoadedStoreId) {
      _loadStoreData();
    }
  }

  Future<void> _loadStoreData() async {
    final storeProv = Provider.of<StoreProvider>(context, listen: false);
    final storeId = widget.currentStore?.storeId ?? storeProv.currentStoreId;
    _lastLoadedStoreId = storeId;

    setState(() {
      _loadingStats = true;
      _loadingNotices = true;
    });

    // 1. 获取真实经营简报数据 (清空写死的假数据)
    final stats = await _dashboardService.getStoreDashboardStats(storeId);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }

    // 2. 获取门店运营规范与日常公告
    final notices = await _noticeService.getStoreNotices(storeId);
    if (mounted) {
      setState(() {
        _notices = notices;
        _loadingNotices = false;
      });
    }

    // 3. 检查是否有未播报的特急重要通知，若有则播放提示音乐并弹窗
    _checkAndTriggerUrgentNotice(storeId);
  }

  Future<void> _checkAndTriggerUrgentNotice(String storeId) async {
    final urgentNotice = await _noticeService.getLatestUrgentNotice(storeId);
    if (urgentNotice != null && urgentNotice.isUrgent && mounted) {
      final played = await SoundService.playIfNewUrgentNotice(
        urgentNotice.id,
        broadcastText: '重要通知提醒：${urgentNotice.title}',
      );
      if (played && mounted) {
        _showUrgentNoticeDialog(urgentNotice);
      }
    }
  }

  void _showUrgentNoticeDialog(StoreNoticeModel notice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '🚨 门店特急重要通知',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Text(
                  notice.summary,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '发布方：${notice.publisher} · 生效日期：${notice.effectiveDate}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showNoticeDetailModal(notice);
              },
              child: const Text('查看详细条款'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('我已知晓'),
            ),
          ],
        );
      },
    );
  }

  void _showNoticeDetailModal(StoreNoticeModel notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildCategoryChip(notice),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notice.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('发布方：${notice.publisher}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 16),
                      Text('版本：${notice.version}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(width: 16),
                      Text('生效日期：${notice.effectiveDate}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const Divider(height: 24),
                  if (notice.summary.isNotEmpty) ...[
                    const Text('💡 核心摘要', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(notice.summary, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (notice.keyPoints.isNotEmpty) ...[
                    const Text('📌 执行红线与重点要求', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    ...notice.keyPoints.map((kp) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              Expanded(child: Text(kp, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                  const Text('📜 详细细则与章程', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      notice.content.isNotEmpty ? notice.content : '（暂无详细补充条款）',
                      style: const TextStyle(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('已阅读并遵照执行'),
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

  Widget _buildCategoryChip(StoreNoticeModel notice) {
    if (notice.isUrgent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
        child: const Text('🚨 特急', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    if (notice.category == 'REGULATION') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
        child: Text(notice.categoryName.isNotEmpty ? notice.categoryName : '运营规范',
            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(notice.categoryName.isNotEmpty ? notice.categoryName : '日常公告',
          style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeProv = context.watch<StoreProvider>();
    final storeName = storeProv.currentStoreName;
    final industryName = widget.currentStore?.industryCategoryName ?? '智慧商业';
    final address = widget.currentStore?.address ?? '门店详细地址';
    final phone = widget.currentStore?.phone ?? '服务热线';
    final openTime = widget.currentStore?.openTime ?? '09:00 - 22:00';
    final manager = widget.currentStore?.managerName ?? '店长/负责人';

    return RefreshIndicator(
      onRefresh: _loadStoreData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 门店核心基础信息卡
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              widget.currentStore?.industry.emoji ?? '🏬',
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      industryName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '编号: ${storeProv.currentStoreId}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 3, backgroundColor: Colors.green),
                              SizedBox(width: 4),
                              Text('营业中', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _buildDetailRow(
                      context,
                      Icons.location_on_outlined,
                      '门店地址',
                      address,
                      actionIcon: Icons.copy,
                      actionTooltip: '复制地址',
                      onAction: () {
                        Clipboard.setData(ClipboardData(text: address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制门店详细地址到剪贴板')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      Icons.phone_outlined,
                      '联系电话',
                      phone,
                      actionIcon: Icons.phone_in_talk,
                      actionTooltip: '呼叫',
                      onAction: () {
                        PhoneCaller.call(context, phone, targetName: storeName);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, Icons.access_time_outlined, '营业时段', openTime),
                    const SizedBox(height: 12),
                    _buildDetailRow(context, Icons.manage_accounts_outlined, '总店长', manager),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('切换当前连锁经营门店'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: widget.onShowStoreSwitcher,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. 今日经营快报 (接入真实数据，废除垃圾数据)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📈 今日经营简报 (实时动态)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (_loadingStats)
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
                    '今日接待客流',
                    '${_stats?.todayCustomers ?? 0} 人次',
                    Icons.people_alt_outlined,
                    AppColors.primary,
                    '在场会话与结单人次',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    '工位实时占用',
                    '${_stats?.occupiedSpaces ?? 0} / ${_stats?.totalSpaces ?? 0} 间/位',
                    Icons.meeting_room_outlined,
                    AppColors.warning,
                    '翻台率 ${(_stats?.spaceUtilizationRate ?? 0.0).toStringAsFixed(1)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    '今日服务实收',
                    '¥${(_stats?.todayRevenue ?? 0.0).toStringAsFixed(2)}',
                    Icons.account_balance_wallet_outlined,
                    AppColors.success,
                    '已结单 ${_stats?.todayOrderCount ?? 0} 笔',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    '预约待到店',
                    '${_stats?.pendingAppointments ?? 0} 单',
                    Icons.calendar_month_outlined,
                    AppColors.secondary,
                    '今日排班待核销',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2.5 员工常用人事管理通道
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.beach_access, color: AppColors.primary, size: 22),
                ),
                title: const Text('员工请假与审批流', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('支持事假/调休/年假在线申报与店长审批', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaveManagementView()),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // 会员中心与储值次卡快捷入口
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.card_membership, color: Colors.purple, size: 22),
                ),
                title: const Text('会员中心与储值次卡', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text('会员建档、双轨储值充值、次卡核销与海马档案', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MembersView()),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // 3. 门店运营规范与公告 (动态加载云端配置，支持特急提示音测试)
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
                        Row(
                          children: const [
                            Icon(Icons.campaign_outlined, color: AppColors.warning, size: 20),
                            SizedBox(width: 8),
                            Text('门店运营规范与日常公告', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            // 提示音乐与语音播报试听测试按钮
                            InkWell(
                              onTap: () async {
                                await SoundService.playOrderAlertSound();
                                await Future.delayed(const Duration(milliseconds: 350));
                                await SoundService.speakText('测试订单语音播报：请注意，A01包厢新下单：龙井虾仁、清蒸桂鱼，共两项，请及时备餐出单！');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('🔔 正在播放测试通知铃声与菜品语音报单...'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.volume_up, color: Colors.amber, size: 14),
                                    SizedBox(width: 2),
                                    Text('🔊 试听报单与语音', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loadingNotices)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    else if (_notices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '暂无现行规范与公告，店长或租户老板可在后台【规章制度】统一发布。',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      )
                    else
                      ..._notices.map((notice) => _buildNoticeCardItem(notice)),
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

  Widget _buildNoticeCardItem(StoreNoticeModel notice) {
    return InkWell(
      onTap: () => NoticeDetailModal.show(context, notice),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: notice.isUrgent ? Colors.red.withOpacity(0.04) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: notice.isUrgent ? Colors.red.withOpacity(0.3) : Colors.grey[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCategoryChip(notice),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    notice.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: notice.isUrgent ? Colors.red[800] : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              notice.summary,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('发布方：${notice.publisher}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(notice.effectiveDate, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    IconData? actionIcon,
    String? actionTooltip,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label：', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionIcon != null && onAction != null)
          IconButton(
            icon: Icon(actionIcon, size: 16, color: AppColors.primary),
            tooltip: actionTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onAction,
          ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
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
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

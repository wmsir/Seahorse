import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import 'tabs/store_overview_tab.dart';
import 'tabs/product_entry_tab.dart';
import 'tabs/category_management_tab.dart';
import 'tabs/staff_management_tab.dart';
import 'tabs/staff_performance_tab.dart';
import 'tabs/account_settings_tab.dart';
import '../attendance/attendance_check_in_view.dart';
import '../leave/leave_management_view.dart';

class ProfileView extends StatefulWidget {
  final bool isSuperAdmin;
  final VoidCallback? onSwitchToAdmin;

  const ProfileView({
    Key? key,
    this.isSuperAdmin = false,
    this.onSwitchToAdmin,
  }) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _tabController = TabController(length: _getTargetTabCount(auth), vsync: this);
  }

  int _getTargetTabCount(AuthProvider auth) {
    if (_isManager(auth)) return 7;
    if (_isCashier(auth)) return 6;
    return 4;
  }

  void _ensureTabControllerSynced(AuthProvider auth) {
    final desired = _getTargetTabCount(auth);
    if (_tabController.length != desired) {
      final old = _tabController;
      _tabController = TabController(length: desired, vsync: this);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        old.dispose();
      });
    }
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

  bool _isCashier(AuthProvider auth) {
    final role = auth.role.toUpperCase();
    final username = auth.username.toLowerCase();
    return role == 'CASHIER' ||
        role.contains('CASHIER') ||
        username.contains('cashier') ||
        auth.realName.contains('收银') ||
        username == '13880010106';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showStoreSwitcher(BuildContext context) {
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
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreProvider>();
    final current = store.currentStore;
    final isManager = _isManager(auth);
    final isCashier = _isCashier(auth);

    _ensureTabControllerSynced(auth);

    String roleBadgeText;
    Color roleBadgeColor;
    if (isManager) {
      roleBadgeText = '店长/管理';
      roleBadgeColor = AppColors.warning;
    } else if (isCashier) {
      roleBadgeText = '前台收银';
      roleBadgeColor = AppColors.success;
    } else {
      roleBadgeText = '员工/技师';
      roleBadgeColor = AppColors.secondary;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(current?.industry.emoji ?? '🏬', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                store.currentStoreName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleBadgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: roleBadgeColor.withOpacity(0.4)),
              ),
              child: Text(
                roleBadgeText,
                style: TextStyle(fontSize: 10, color: roleBadgeColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
            tooltip: '切换门店',
            onPressed: () => _showStoreSwitcher(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              tabs: isManager
                  ? const [
                      Tab(iconMargin: EdgeInsets.zero, text: '门店概况'),
                      Tab(iconMargin: EdgeInsets.zero, text: '商品管理'),
                      Tab(iconMargin: EdgeInsets.zero, text: '分类管理'),
                      Tab(iconMargin: EdgeInsets.zero, text: '员工管理'),
                      Tab(iconMargin: EdgeInsets.zero, text: '员工请假'),
                      Tab(iconMargin: EdgeInsets.zero, text: '我的考勤'),
                      Tab(iconMargin: EdgeInsets.zero, text: '账号设置'),
                    ]
                  : (isCashier
                      ? const [
                          Tab(iconMargin: EdgeInsets.zero, text: '门店概况'),
                          Tab(iconMargin: EdgeInsets.zero, text: '商品管理'),
                          Tab(iconMargin: EdgeInsets.zero, text: '分类管理'),
                          Tab(iconMargin: EdgeInsets.zero, text: '员工请假'),
                          Tab(iconMargin: EdgeInsets.zero, text: '我的考勤'),
                          Tab(iconMargin: EdgeInsets.zero, text: '账号设置'),
                        ]
                      : const [
                          Tab(iconMargin: EdgeInsets.zero, text: '门店概况'),
                          Tab(iconMargin: EdgeInsets.zero, text: '我的业绩'),
                          Tab(iconMargin: EdgeInsets.zero, text: '我的考勤'),
                          Tab(iconMargin: EdgeInsets.zero, text: '账号设置'),
                        ]),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: isManager
            ? [
                StoreOverviewTab(
                  currentStore: current,
                  onShowStoreSwitcher: () => _showStoreSwitcher(context),
                ),
                const ProductEntryTab(),
                const CategoryManagementTab(),
                const StaffManagementTab(),
                const LeaveManagementView(isEmbedded: true),
                const AttendanceCheckInView(isEmbedded: true),
                AccountSettingsTab(
                  isSuperAdmin: widget.isSuperAdmin,
                  onSwitchToAdmin: widget.onSwitchToAdmin,
                ),
              ]
            : (isCashier
                ? [
                    StoreOverviewTab(
                      currentStore: current,
                      onShowStoreSwitcher: () => _showStoreSwitcher(context),
                    ),
                    const ProductEntryTab(),
                    const CategoryManagementTab(),
                    const LeaveManagementView(isEmbedded: true),
                    const AttendanceCheckInView(isEmbedded: true),
                    AccountSettingsTab(
                      isSuperAdmin: widget.isSuperAdmin,
                      onSwitchToAdmin: widget.onSwitchToAdmin,
                    ),
                  ]
                : [
                    StoreOverviewTab(
                      currentStore: current,
                      onShowStoreSwitcher: () => _showStoreSwitcher(context),
                    ),
                    const StaffPerformanceTab(),
                    const AttendanceCheckInView(isEmbedded: true),
                    AccountSettingsTab(
                      isSuperAdmin: widget.isSuperAdmin,
                      onSwitchToAdmin: widget.onSwitchToAdmin,
                    ),
                  ]),
      ),
    );
  }
}

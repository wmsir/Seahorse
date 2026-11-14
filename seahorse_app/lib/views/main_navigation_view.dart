import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../models/store_model.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import 'dashboard/dashboard_view.dart';
import 'spaces/spaces_view.dart';
import 'appointments/appointments_view.dart';
import 'cashier/cashier_view.dart';
import 'members/members_view.dart';
import 'profile/profile_view.dart';
import 'admin/platform_admin_view.dart';
import 'login/login_view.dart';
import '../services/notification_poll_service.dart';
import '../services/notice_service.dart';
import 'widgets/notice_detail_modal.dart';

class MainNavigationView extends StatefulWidget {
  final bool startInAdminMode;

  const MainNavigationView({Key? key, this.startInAdminMode = false}) : super(key: key);

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;
  Map<String, dynamic>? _delegatedStore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final store = context.read<StoreProvider>();
      await store.loadStores();
      if (!mounted) return;
      store.reloadAllProviders(context);
      final storeId = store.currentStoreId.isNotEmpty ? store.currentStoreId : 'S001';
      NotificationPollService().startPolling(storeId: storeId);
      NotificationPollService().onAlertCallback = (title, message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.amber, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(message, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: '知道了',
              textColor: Colors.amber,
              onPressed: () {},
            ),
          ),
        );
      };

      // 监听门店新规章制度与日常公告实时推送 (全端免刷新直接弹窗强提醒)
      NotificationPollService().onNoticeCallback = (notice) {
        if (!mounted) return;
        _showNoticeAlert(notice);
      };
    });
  }

  /// 弹出规章制度与运营规范强提醒 (SnackBar + 强制签署/特急弹窗)
  void _showNoticeAlert(StoreNoticeModel notice) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(notice.isUrgent ? Icons.warning_amber_rounded : Icons.menu_book, color: Colors.amber, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.isUrgent ? '🚨 门店特急通知：${notice.title}' : '📜 门店新规章发布：${notice.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    notice.summary.isNotEmpty ? notice.summary : notice.title,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 15),
        action: SnackBarAction(
          label: '立即查阅',
          textColor: Colors.amber,
          onPressed: () {
            NoticeDetailModal.show(context, notice);
          },
        ),
      ),
    );

    // 如果是特急通知或强制手写签署确认，直接自动弹出全屏细则底板
    if (notice.isUrgent || notice.requireSignature) {
      NoticeDetailModal.show(context, notice);
    }
  }

  @override
  void dispose() {
    final poll = NotificationPollService();
    poll.onAlertCallback = null;
    poll.onNoticeCallback = null;
    poll.stopPolling();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _exitDelegation() {
    setState(() {
      _delegatedStore = null;
    });
    context.read<StoreProvider>().exitDelegation();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已退出代管模式，返回超级管理员总控台')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreProvider>();
    final isPhoneAccount = RegExp(r'^\d{11}$').hasMatch(auth.username);
    final isPlatformSuperAdmin = (auth.username.toLowerCase() == 'admin' ||
            auth.username.toLowerCase() == 'root_ops' ||
            auth.role == 'PLATFORM_DEVELOPER') &&
        !isPhoneAccount;
    final isSuperAdmin = isPlatformSuperAdmin;

    // 若当前为SaaS平台开发运维超级管理员身份且未进入具体代管门店，只显示超级管理员总控台页面
    if (isPlatformSuperAdmin && _delegatedStore == null) {
      return PlatformAdminView(
        onLogout: () async {
          context.read<StoreProvider>().exitDelegation();
          await context.read<AuthProvider>().logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginView()),
              (route) => false,
            );
          }
        },
        onEnterStore: (storeData) async {
          final targetStoreId = storeData['storeId']?.toString() ?? 'S001';
          final targetStoreName = storeData['storeName']?.toString() ?? '门店';
          final targetAddress = storeData['address']?.toString() ?? '';
          final targetPhone = storeData['phone']?.toString() ?? '';
          final targetIndustry = storeData['industry']?.toString() ?? 'BEAUTY';
          final targetManager = storeData['managerName']?.toString() ?? '店长';

          await context.read<StoreProvider>().delegateStore(
            StoreModel(
              storeId: targetStoreId,
              storeName: targetStoreName,
              address: targetAddress,
              phone: targetPhone,
              openTime: '09:30 - 22:00',
              industry: IndustryType.fromCode(targetIndustry),
              industryCategoryName: targetIndustry,
              managerName: targetManager,
            ),
          );

          setState(() {
            _delegatedStore = storeData;
            _currentIndex = 0;
          });
        },
      );
    }

    final bool isManager = auth.role == 'STORE_MANAGER' ||
        auth.role == 'SUPER_ADMIN' ||
        auth.role.contains('MANAGER') ||
        auth.role.contains('ADMIN') ||
        auth.username.contains('admin') ||
        auth.username.contains('manager') ||
        auth.username.contains('boss') ||
        auth.realName.contains('店长');

    final bool isCashier = auth.role == 'CASHIER' ||
        auth.role.contains('CASHIER') ||
        auth.username.contains('cashier') ||
        auth.realName.contains('收银');

    final List<Widget> pages = [];
    final List<BottomNavigationBarItem> navItems = [];

    // 1. 工作台 (全员可见)
    pages.add(DashboardView(onNavigateTab: _onTabChanged));
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: '工作台',
    ));

    // 2. 展位/包厢 (全员可见)
    pages.add(const SpacesView());
    navItems.add(BottomNavigationBarItem(
      icon: const Icon(Icons.meeting_room_outlined),
      activeIcon: const Icon(Icons.meeting_room),
      label: store.spaceAlias,
    ));

    // 3. 核心业务居中突出：店长/收银为移动收银，其他技师为预约排班
    if (isManager || isCashier) {
      pages.add(const CashierView());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale_outlined),
        activeIcon: Icon(Icons.point_of_sale),
        label: '移动收银',
      ));
    } else {
      pages.add(const AppointmentsView());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month),
        label: '预约排班',
      ));
    }

    // 4. 会员中心 (全员可见：客户海马体偏好档案、双轨储值、次卡)
    pages.add(const MembersView());
    navItems.add(const BottomNavigationBarItem(
      icon: Icon(Icons.card_membership_outlined),
      activeIcon: Icon(Icons.card_membership),
      label: '会员中心',
    ));

    // 5. 门店管理 / 个人中心 (全员严格保持 5 个黄金 Tab 规范)
    pages.add(ProfileView(
      isSuperAdmin: isSuperAdmin,
      onSwitchToAdmin: isSuperAdmin ? _exitDelegation : null,
    ));
    navItems.add(BottomNavigationBarItem(
      icon: Icon(isManager ? Icons.storefront_outlined : Icons.person_pin_outlined),
      activeIcon: Icon(isManager ? Icons.storefront : Icons.person_pin),
      label: isManager ? '门店管理' : '个人中心',
    ));

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    final bool isWideScreen = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      body: Column(
        children: [
          // 超管代管模式顶部长条提示
          if (isSuperAdmin && _delegatedStore != null)
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '👑 超管代管模式 · ${_delegatedStore!['storeName']} (${_delegatedStore!['tenantName'] ?? '商户'})',
                        style: const TextStyle(
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: _exitDelegation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('退出代管', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Row(
              children: [
                if (isWideScreen)
                  NavigationRail(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (idx) {
                      HapticFeedback.lightImpact();
                      _onTabChanged(idx);
                    },
                    labelType: NavigationRailLabelType.all,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedIconTheme: const IconThemeData(color: AppColors.primary),
                    selectedLabelTextStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('🌊', style: TextStyle(fontSize: 24)),
                    ),
                    destinations: navItems
                        .map((item) => NavigationRailDestination(
                              icon: item.icon,
                              selectedIcon: item.activeIcon,
                              label: Text(item.label ?? ''),
                            ))
                        .toList(),
                  ),
                if (isWideScreen)
                  const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderLight),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWideScreen
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                border: const Border(
                  top: BorderSide(color: AppColors.borderLight, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 58,
                  child: BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (idx) {
                      HapticFeedback.lightImpact();
                      _onTabChanged(idx);
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: AppColors.textMuted,
                    selectedFontSize: 11,
                    unselectedFontSize: 11,
                    items: navItems,
                  ),
                ),
              ),
            ),
    );
  }
}

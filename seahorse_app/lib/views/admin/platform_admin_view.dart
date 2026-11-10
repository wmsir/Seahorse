import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/chinese_date_utils.dart';
import '../../core/network/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../login/login_view.dart';

class PlatformAdminView extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onEnterStore;
  final VoidCallback? onLogout;

  const PlatformAdminView({Key? key, this.onEnterStore, this.onLogout}) : super(key: key);

  @override
  State<PlatformAdminView> createState() => _PlatformAdminViewState();
}

class _PlatformAdminViewState extends State<PlatformAdminView> {
  int _currentIndex = 0;

  // 支付通道参数状态
  String _activePaymentRoute = 'route1_individual'; // route1_individual, route2_aggregate, route3_sandbox
  bool _scanBoxEnabled = true;
  int _scanBoxThreshold = 50;
  bool _scanBoxBeep = true;
  bool _autoSettle = true;

  // 短信直发控制台状态
  String _smsChannel = 'aliyun'; // aliyun, tencent
  final _smsPhoneController = TextEditingController(text: '13800138000');
  String _selectedTemplate = 'auth_code';
  String _smsMockOutput = '';

  // 真实租户与订阅数据
  List<Map<String, dynamic>> _realTenants = [];
  bool _isLoadingTenants = false;

  // 平台实时统计指标
  Map<String, dynamic> _vendorStats = {};
  bool _isLoadingStats = false;

  // 平台管理组与角色协同数据
  final List<Map<String, dynamic>> _adminGroups = [
    {
      'code': 'SUPER_ADMIN',
      'name': '超级管理组',
      'roleTag': '全域总控',
      'tagColor': Colors.amber,
      'description': '拥有平台全局最高管辖权，包含系统大盘、租户开通、资金结算与支付通道',
      'enabled': true,
      'members': ['admin (平台总超管 · 平台专属)'],
      'permissions': ['全域平台大盘', '租户入驻与管控', '支付通道配置', '云短信直发中心', 'SaaS套餐定价', '系统安全日志'],
    },
    {
      'code': 'OPERATIONS',
      'name': '平台运营管理组',
      'roleTag': '业务运营',
      'tagColor': Colors.blue,
      'description': '负责商户入驻审核、租户续期延期特批、SaaS营销策略与促销券下发',
      'enabled': true,
      'members': ['待分配成员'],
      'permissions': ['租户入驻与管控', '营销策略促单', '短信模板配置', '商户到期预警'],
    },
    {
      'code': 'FINANCE',
      'name': '财务结算管理组',
      'roleTag': '财务审计',
      'tagColor': Colors.green,
      'description': '负责全平台交易流水审计、分润核算、开票记录与SaaS订阅记账',
      'enabled': true,
      'members': ['待分配成员'],
      'permissions': ['交易总流水监控', '商户对账结算', '存储服务费记账', '财务报表导出'],
    },
    {
      'code': 'TECH_SUPPORT',
      'name': '技术支撑运维组',
      'roleTag': '技术运维',
      'tagColor': Colors.purple,
      'description': '负责网关连通性诊断 (Ping)、扫码盒子免驱参数调优与日志回执分析',
      'enabled': true,
      'members': ['待分配成员'],
      'permissions': ['网关通信诊断 (Ping)', '扫码硬件参数调优', '短信通道下发测试', '接口性能监控'],
    },
    {
      'code': 'STORE_MANAGER',
      'name': '连锁店长协同组',
      'roleTag': '实体门店',
      'tagColor': Colors.teal,
      'description': '各实体连锁门店日常经营管理、人员排班、工位翻台与前台巡店',
      'enabled': false,
      'members': ['暂无入驻门店店长'],
      'permissions': ['前台工位房态', '收银结算台', '技师预约排班', '会员建档与充值', '店内耗材调拨'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
    _loadVendorStats();
  }

  int _calculateTotalStores() {
    if (_vendorStats['totalStores'] != null) {
      return (_vendorStats['totalStores'] as num).toInt();
    }
    int total = 0;
    for (var t in _realTenants) {
      if (t['stores'] is List) {
        total += (t['stores'] as List).length;
      } else if (t['storeCount'] != null) {
        total += (t['storeCount'] as num).toInt();
      } else {
        total += 1;
      }
    }
    return total;
  }

  Future<void> _loadVendorStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final response = await ApiClient().dio.get('/vendor/stats');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map) {
          if (mounted) {
            setState(() {
              _vendorStats = Map<String, dynamic>.from(data);
              _isLoadingStats = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      print('PlatformAdminView loadVendorStats error: $e');
    }
    if (mounted) {
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoadingTenants = true);
    try {
      final response = await ApiClient().dio.get('/vendor/subscriptions');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          final items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          if (mounted) {
            setState(() {
              _realTenants = items;
              _isLoadingTenants = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      print('PlatformAdminView loadSubscriptions error: $e');
    }
    if (mounted) {
      setState(() {
        _realTenants = [];
        _isLoadingTenants = false;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('退出登录确认', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('确定要退出超级管理员系统吗？退出后将清除当前管理会话并返回登录页面。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                context.read<StoreProvider>().exitDelegation();
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginView()),
                    (route) => false,
                  );
                }
              }
            },
            child: const Text('确定退出'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _smsPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardTab(),
      _buildTenantsTab(),
      _buildPaymentTab(),
      _buildSmsTab(),
      _buildPlansTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('平台运营总控台', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Text('SUPER ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              '全系统多业态连锁数字化总控中枢',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.phone_android_rounded, size: 14, color: Color(0xFFD97706)),
              label: const Text('查店代管', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFBEB),
                side: const BorderSide(color: Color(0xFFFDE68A)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => _openQueryStoreByPhoneDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            tooltip: '退出登录',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      // 按照用户需求：超级管理员登录成功后，页签统一放置在底部 BottomNavigationBar！
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0D9488),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: '平台大盘',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: '租户管控',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: '扫码支付',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sms_outlined),
            activeIcon: Icon(Icons.sms),
            label: '云短信',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: '套餐定价',
          ),
        ],
      ),
    );
  }

  // ==================== TAB 1: 平台运营大盘 ====================
  Widget _buildDashboardTab() {
    final totalTenants = (_vendorStats['totalTenants'] as num?)?.toInt() ?? _realTenants.length;
    final totalStores = _calculateTotalStores();
    final totalRevenue = (_vendorStats['totalSubscriptionRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalMembers = (_vendorStats['totalMembers'] as num?)?.toInt() ?? 0;
    final totalStorage = (_vendorStats['totalStorageRevenue'] as num?)?.toDouble() ?? 0.0;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_loadSubscriptions(), _loadVendorStats()]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingStats) ...[
              const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
              const SizedBox(height: 8),
            ],
            // 欢迎横幅（明亮护眼翡翠绿渐变，温和舒适）
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/seahorse_logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '超级管理员 · 平台运营大盘',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ChineseDateUtils.formatFullChineseDate(DateTime.now()),
                          style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Colors.white),
                    tooltip: '退出登录',
                    onPressed: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 手机号查店代管登录入口卡片（护眼柔和琥珀金）
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFDF5), Color(0xFFFEF9C3)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_android_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '租户分店代管登录通道',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '输入商户/店长手机号查店，代管登录进入管理',
                          style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login_rounded, size: 14),
                    label: const Text('查店登录', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _openQueryStoreByPhoneDialog(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('📊 平台核心经营概览', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),

            // 数据指标 2x2 网格
            Row(
              children: [
                Expanded(child: _buildMetricCard('签约租户数', '$totalTenants 家', totalTenants == 0 ? '暂无商户签约' : '正常入驻', Icons.corporate_fare, Colors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricCard('全国连锁门店', '$totalStores 间', totalStores == 0 ? '暂未开设门店' : '100% 在线', Icons.store, Colors.teal)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMetricCard('今日交易总流水', '¥ ${totalRevenue.toStringAsFixed(2)}', '按真实流水核算', Icons.payments, Colors.deepOrange)),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricCard('全平台会员总数', '$totalMembers 人', '全平台实时在册', Icons.people, Colors.purple)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMetricCard('云端存储配额', '${totalStorage.toStringAsFixed(1)} GB', '真实云存储用量', Icons.cloud_queue, Colors.indigo)),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricCard('通信短信余量', '0 条', '充值加油包即时生效', Icons.message, Colors.amber.shade800)),
              ],
            ),

            const SizedBox(height: 20),
            const Text('⚡ 平台配置通道快捷入口', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 10),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.credit_card, color: Color(0xFF2563EB))),
                    title: const Text('💳 扫码盒子与支付通道', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('个体户直连、持牌聚合小微与沙箱模拟', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFF0FDF4), child: Icon(Icons.send_rounded, color: Color(0xFF16A34A))),
                    title: const Text('📱 阿里云 / 腾讯云短信直发中心', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('场景模板自适应、短信拟真与即时直发', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.groups_rounded, color: Color(0xFFD97706))),
                    title: const Text('👥 平台管理组与角色权限', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('管理超级管理组、运营组、财务组与技术支持组', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => _showAdminGroupManageSheet(),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFF3E8FF), child: Icon(Icons.business_rounded, color: Color(0xFF9333EA))),
                    title: const Text('🏢 签约租户与多门店管控', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('全网租户配额、订阅套餐与多门店管控', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8,
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
              Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  // ==================== TAB 2: 租户与分店管控 ====================
  Widget _buildTenantsTab() {
    if (_isLoadingTenants) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)));
    }

    if (_realTenants.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF0D9488),
        onRefresh: () async {
          await Future.wait([_loadSubscriptions(), _loadVendorStats()]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Text('🏢 签约入驻商户 (0 家)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.groups_rounded, size: 15, color: Color(0xFF0D9488)),
                    label: const Text('平台管理组', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF99F6E4)),
                      backgroundColor: const Color(0xFFF0FDFA),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showAdminGroupManageSheet,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0FDFA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business_outlined, size: 50, color: Color(0xFF0D9488)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无签约入驻租户数据（纯净空库）',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '全域商业数据已全部清空，等待新租户自主注册或后台开通',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('从服务端重新加载'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      _loadSubscriptions();
                      _loadVendorStats();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0D9488),
      onRefresh: _loadSubscriptions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _realTenants.length + 1,
        itemBuilder: (ctx, idx) {
          if (idx == 0) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text('🏢 签约入驻商户 (${_realTenants.length} 家)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.groups_rounded, size: 15, color: Color(0xFF0D9488)),
                    label: const Text('平台管理组', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF99F6E4)),
                      backgroundColor: const Color(0xFFF0FDFA),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showAdminGroupManageSheet,
                  ),
                ],
              ),
            );
          }

          final t = _realTenants[idx - 1];
          final tenantName = t['tenantName'] ?? '租户企业';
          final code = t['tenantId'] ?? 'T$idx';
          final storeCount = t['storeCount'] ?? (t['stores'] is List ? (t['stores'] as List).length : 1);
          final planName = t['planName'] ?? t['plan'] ?? '标准版';
          final storage = '${t['storageQuotaGb'] ?? 5} GB 配额';
          final expire = t['expireDate'] ?? '长期有效';
          final isActive = t['status'] == 'ACTIVE';
          final statusStr = isActive ? '正常运营' : '已停用';
          final statusColor = isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8);

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showTenantManageSheet(t),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 头部：企业名 + 套餐标签 + 运营状态
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business_rounded, size: 20, color: Color(0xFF0D9488)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenantName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text('租户编号: $code', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(planName, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(statusStr, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 数据指标栏（护眼柔和灰背景）
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('实体门店', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text('$storeCount 间分店', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('云存储配额', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text(storage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('联系人手机', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                Text('${t['contactPhone'] ?? '暂无'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 服务有效期独立展示行（避免横向拥挤超界）
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text('服务有效期至: $expire', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 操作按钮栏：全宽自适应双按钮，永不超界！
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D9488),
                              backgroundColor: const Color(0xFFF0FDFA),
                              side: const BorderSide(color: Color(0xFF99F6E4)),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _openQueryStoreByPhoneDialog(t['contactPhone']?.toString()),
                            icon: const Icon(Icons.phone_android_rounded, size: 14),
                            label: const Text('查店代管', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _showTenantManageSheet(t),
                            icon: const Icon(Icons.tune_rounded, size: 14),
                            label: const Text('管理租户', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------- 租户管控操作弹窗 (支持正常使用) -----------------
  void _showTenantManageSheet(Map<String, dynamic> t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String currentStatus = t['status'] ?? 'ACTIVE';
        String currentPlan = t['plan'] ?? 'STANDARD';
        String currentPlanName = t['planName'] ?? '标准版套餐';
        String currentExpire = t['expireDate'] ?? '2027-12-31';
        int storeLimit = t['storeLimit'] ?? (t['stores'] is List ? (t['stores'] as List).length : 1);
        if (storeLimit < 1) storeLimit = 1;
        int storageQuotaGb = t['storageQuotaGb'] ?? 10;
        final contactName = t['contactName'] ?? '未登记负责人';
        final contactPhone = t['contactPhone'] ?? '13800000000';
        final tenantName = t['tenantName'] ?? '租户企业';
        final tenantId = t['tenantId'] ?? 'T000';
        final stores = (t['stores'] is List) ? List<Map<String, dynamic>>.from(t['stores']) : <Map<String, dynamic>>[];

        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final isTenantActive = currentStatus == 'ACTIVE';

            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 10, left: 20, right: 12, bottom: 8),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isTenantActive ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.business_center, color: isTenantActive ? Colors.green : Colors.grey, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          tenantName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isTenantActive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isTenantActive ? '正常运营' : '已停用',
                                          style: TextStyle(
                                            color: isTenantActive ? Colors.green : Colors.red,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '租户编号: $tenantId · 联系人: $contactName ($contactPhone)',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 1. 运营状态控制开关
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isTenantActive ? Colors.green.withOpacity(0.04) : Colors.red.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isTenantActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isTenantActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                                color: isTenantActive ? Colors.green : Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTenantActive ? '租户运营状态：正常提供服务' : '租户运营状态：已暂停停用',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isTenantActive ? Colors.green.shade800 : Colors.red.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isTenantActive ? '租户旗下所有门店均可正常开台、收银与排班' : '已冻结前台开单收银与客户预订，后台仅供对账',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isTenantActive,
                                activeColor: Colors.green,
                                onChanged: (v) {
                                  setModalState(() {
                                    currentStatus = v ? 'ACTIVE' : 'DISABLED';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 2. SaaS 订阅套餐选择
                        const Text('📦 SaaS 订阅套餐级别', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPlanChoiceChip(
                              label: '🎁 体验版 (TRIAL)',
                              planKey: 'TRIAL',
                              currentPlan: currentPlan,
                              onSelect: () {
                                setModalState(() {
                                  currentPlan = 'TRIAL';
                                  currentPlanName = '体验版套餐';
                                });
                              },
                            ),
                            _buildPlanChoiceChip(
                              label: '🌱 标准版 (STANDARD)',
                              planKey: 'STANDARD',
                              currentPlan: currentPlan,
                              onSelect: () {
                                setModalState(() {
                                  currentPlan = 'STANDARD';
                                  currentPlanName = '标准版套餐';
                                });
                              },
                            ),
                            _buildPlanChoiceChip(
                              label: '⭐ 专业版 (PROFESSIONAL)',
                              planKey: 'PROFESSIONAL',
                              currentPlan: currentPlan,
                              onSelect: () {
                                setModalState(() {
                                  currentPlan = 'PROFESSIONAL';
                                  currentPlanName = '专业版套餐';
                                });
                              },
                            ),
                            _buildPlanChoiceChip(
                              label: '👑 旗舰企业版 (ENTERPRISE)',
                              planKey: 'ENTERPRISE',
                              currentPlan: currentPlan,
                              onSelect: () {
                                setModalState(() {
                                  currentPlan = 'ENTERPRISE';
                                  currentPlanName = '旗舰企业版';
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // 3. 服务有效期与快捷延期
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('📅 订阅服务有效期', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              icon: const Icon(Icons.calendar_month, size: 16),
                              label: Text(currentExpire, style: const TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now.add(const Duration(days: 365)),
                                  firstDate: now.subtract(const Duration(days: 365)),
                                  lastDate: now.add(const Duration(days: 3650)),
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    currentExpire = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            ActionChip(
                              label: const Text('+30天 (月度)'),
                              onPressed: () {
                                final now = DateTime.now().add(const Duration(days: 30));
                                setModalState(() {
                                  currentExpire = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('+90天 (季度)'),
                              onPressed: () {
                                final now = DateTime.now().add(const Duration(days: 90));
                                setModalState(() {
                                  currentExpire = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('+1年 (年度特批)'),
                              onPressed: () {
                                final now = DateTime.now().add(const Duration(days: 365));
                                setModalState(() {
                                  currentExpire = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                                });
                              },
                            ),
                            ActionChip(
                              label: const Text('+3年 (长期客户)'),
                              onPressed: () {
                                final now = DateTime.now().add(const Duration(days: 1095));
                                setModalState(() {
                                  currentExpire = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // 4. 经营配额分配
                        const Text('⚙️ 经营配额分配', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('实体门店开店配额上限', style: TextStyle(fontSize: 13)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: storeLimit > 1
                                            ? () => setModalState(() => storeLimit--)
                                            : null,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                                        child: Text('$storeLimit 家', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: storeLimit < 50
                                            ? () => setModalState(() => storeLimit++)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('云端存储空间配额', style: TextStyle(fontSize: 13)),
                                  DropdownButton<int>(
                                    value: storageQuotaGb,
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 5, child: Text('5 GB (基础档)')),
                                      DropdownMenuItem(value: 10, child: Text('10 GB (推荐档)')),
                                      DropdownMenuItem(value: 20, child: Text('20 GB (进阶档)')),
                                      DropdownMenuItem(value: 50, child: Text('50 GB (豪华档)')),
                                      DropdownMenuItem(value: 100, child: Text('100 GB (海量档)')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setModalState(() => storageQuotaGb = v);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 5. 旗下实体门店清单
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('🏬 旗下开设门店 (${stores.length} 家)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text('配额已用 ${stores.length}/$storeLimit', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (stores.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                            child: const Center(child: Text('该租户暂未录入实体门店', style: TextStyle(fontSize: 12, color: Colors.grey))),
                          )
                        else
                          ...stores.map((s) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.storefront, size: 16, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s['storeName'] ?? '实体门店', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 2),
                                          Text('${s['industryDesc'] ?? '综合服务'} · 编号: ${s['storeId'] ?? '-'} · 电话: ${s['phone'] ?? '暂无'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('正常营业', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0F172A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        if (widget.onEnterStore != null) {
                                          widget.onEnterStore!({
                                            'storeId': s['storeId'],
                                            'storeName': s['storeName'],
                                            'tenantId': tenantId,
                                            'tenantName': tenantName,
                                            'phone': s['phone'] ?? contactPhone,
                                            'industry': s['industry'] ?? 'BEAUTY',
                                            'address': s['address'] ?? '',
                                            'managerName': s['managerName'] ?? contactName,
                                          });
                                        }
                                      },
                                      child: const Text('代管进入', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),

                  // 底部保存按钮
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), offset: const Offset(0, -3), blurRadius: 6),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('取消返回'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('保存租户管控配置'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                t['status'] = currentStatus;
                                t['plan'] = currentPlan;
                                t['planName'] = currentPlanName;
                                t['expireDate'] = currentExpire;
                                t['storeLimit'] = storeLimit;
                                t['storageQuotaGb'] = storageQuotaGb;

                                try {
                                  await ApiClient().dio.post(
                                    '/vendor/tenant/$tenantId/toggle-status',
                                    data: {'status': currentStatus},
                                  );
                                } catch (_) {}

                                try {
                                  await ApiClient().dio.post(
                                    '/vendor/renew',
                                    data: {
                                      'tenantId': tenantId,
                                      'plan': currentPlan,
                                      'expireDate': currentExpire,
                                    },
                                  );
                                } catch (_) {}

                                Navigator.pop(ctx);
                                setState(() {});

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.success,
                                    content: Text('🎉 租户【$tenantName】管理配置已成功保存并实时生效！'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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

  // ----------------- 平台管理组与权限协同管理弹窗 -----------------
  void _showAdminGroupManageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (groupCtx, setGroupState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 10, left: 20, right: 12, bottom: 8),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.groups_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              '平台管理组与角色权限协同',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _adminGroups.length,
                      itemBuilder: (context, index) {
                        final g = _adminGroups[index];
                        final isEnabled = g['enabled'] as bool;
                        final members = List<String>.from(g['members'] ?? []);
                        final permissions = List<String>.from(g['permissions'] ?? []);
                        final tagColor = g['tagColor'] as Color? ?? Colors.blue;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: tagColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        g['roleTag'] ?? '管理组',
                                        style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        g['name'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    Switch(
                                      value: isEnabled,
                                      activeColor: AppColors.primary,
                                      onChanged: (v) {
                                        setGroupState(() {
                                          g['enabled'] = v;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  g['description'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const Divider(height: 16),
                                const Text('👥 组内配置成员:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: members.map((m) => Chip(
                                    label: Text(m, style: const TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.grey.shade100,
                                    padding: EdgeInsets.zero,
                                  )).toList(),
                                ),
                                const SizedBox(height: 8),
                                const Text('🔐 核心管辖权限清单:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: permissions.map((p) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isEnabled ? AppColors.primary.withOpacity(0.08) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: isEnabled ? AppColors.primary.withOpacity(0.2) : Colors.grey.shade300),
                                    ),
                                    child: Text(
                                      '✓ $p',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isEnabled ? AppColors.primaryDark : Colors.grey,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), offset: const Offset(0, -3), blurRadius: 6),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('保存平台管理组与权限配置'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('🎉 平台管理组状态与权限矩阵已保存并实时生效！'),
                              ),
                            );
                          },
                        ),
                      ),
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

  Widget _buildPlanChoiceChip({
    required String label,
    required String planKey,
    required String currentPlan,
    required VoidCallback onSelect,
  }) {
    final isSelected = currentPlan == planKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      onSelected: (_) => onSelect(),
    );
  }

  // ==================== TAB 3: 扫码盒子与支付通道 ====================
  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💳 系统全局收款主通道', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _buildPaymentRouteOption(
            id: 'route1_individual',
            badge: '🌟 官方最推荐',
            badgeColor: Colors.blue,
            title: '路线 1: 个体工商直连入网 (租户专属)',
            subtitle: '执照与法人直连微信/支付宝商业版，0.38% 费率，直接到账',
          ),
          const SizedBox(height: 10),
          _buildPaymentRouteOption(
            id: 'route2_aggregate',
            badge: '⚡ 免执照合规',
            badgeColor: Colors.green,
            title: '路线 2: 持牌聚合支付小微进件',
            subtitle: '支持自然人凭身份证与门头照片合规开通，银联清算，次日自动结汇',
          ),
          const SizedBox(height: 10),
          _buildPaymentRouteOption(
            id: 'route3_sandbox',
            badge: '🧪 零成本联调',
            badgeColor: Colors.purple,
            title: '路线 3: 官方沙箱环境联调通道',
            subtitle: '无真实资金发生，沙箱账户虚拟全链路模拟反扫与回调',
          ),

          const SizedBox(height: 20),
          const Text('📷 扫码盒子免驱 USB HID 硬件参数', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('全局 USB 扫码枪/盒子监听', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('后台常驻捕获条码，无需先用光标点击输入框'),
                  value: _scanBoxEnabled,
                  onChanged: (v) => setState(() => _scanBoxEnabled = v),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('击键间隔识别阈值', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('当前设定: $_scanBoxThreshold ms (自动区分人工手敲与高速扫码器)'),
                  trailing: DropdownButton<int>(
                    value: _scanBoxThreshold,
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 ms (极速)')),
                      DropdownMenuItem(value: 50, child: Text('50 ms (标准)')),
                      DropdownMenuItem(value: 80, child: Text('80 ms (宽容)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _scanBoxThreshold = v);
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('清脆扫码蜂鸣声', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('成功识别微信/支付宝付款码时播放哔声反馈'),
                  value: _scanBoxBeep,
                  onChanged: (v) => setState(() => _scanBoxBeep = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('反扫付款码自动结账', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('在收银台捕获 18 位付款码后自动发起扣款请求'),
                  value: _autoSettle,
                  onChanged: (v) => setState(() => _autoSettle = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Ping 诊断通道'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    _showPingDialog();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('保存支付设定'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🎉 支付通道与扫码硬件参数已保存并同步至全系统！')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRouteOption({
    required String id,
    required String badge,
    required Color badgeColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _activePaymentRoute == id;

    return GestureDetector(
      onTap: () => setState(() => _activePaymentRoute = id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? AppColors.primaryDark : Colors.black87)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: badgeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPingDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.network_check, color: AppColors.success),
              SizedBox(width: 8),
              Text('网关通信握手 (Ping) 报告'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前测试通道: $_activePaymentRoute'),
              const SizedBox(height: 8),
              const Text('• 握手协议: TLS 1.3 / HTTPS POST'),
              const Text('• 往返时延: 48 ms (极佳)'),
              const Text('• 签名验签校验: 通过 (RSA-SHA256)'),
              const Text('• 状态码: HTTP 200 OK (GATEWAY_ONLINE)'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('完成')),
          ],
        );
      },
    );
  }

  // ==================== TAB 4: 云短信直发中心 ====================
  Widget _buildSmsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📱 云短信下发通道', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🟠 阿里云 Dysmsapi'),
                    ],
                  ),
                  selected: _smsChannel == 'aliyun',
                  onSelected: (v) => setState(() => _smsChannel = 'aliyun'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔵 腾讯云 SMS'),
                    ],
                  ),
                  selected: _smsChannel == 'tencent',
                  onSelected: (v) => setState(() => _smsChannel = 'tencent'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _smsPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: '接收人手机号码',
              prefixIcon: const Icon(Icons.phone_iphone),
              suffixIcon: TextButton(
                onPressed: () {
                  _smsPhoneController.text = '13800138000';
                },
                child: const Text('快捷填入', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('📋 业务场景模板', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTemplateChip('auth_code', '🔑 验证码'),
              _buildTemplateChip('consume_bill', '💰 消费结账'),
              _buildTemplateChip('recharge_notice', '💳 储值通知'),
              _buildTemplateChip('appointment_reminder', '📅 预约提醒'),
              _buildTemplateChip('system_upgrade', '📢 平台公告'),
            ],
          ),

          const SizedBox(height: 16),
          const Text('📱 手机端真实下发内容拟真预览', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('【海马连锁店务】', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                    const Text('预计计费: 1条 (70字内)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_getTemplatePreviewText(), style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('🚀 立即执行短信在线下发'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                _sendMockSms();
              },
            ),
          ),

          if (_smsMockOutput.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📡 下发诊断回执 (Live Direct Receipt):', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_smsMockOutput, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String id, String label) {
    final isSelected = _selectedTemplate == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) {
        if (v) setState(() => _selectedTemplate = id);
      },
    );
  }

  String _getTemplatePreviewText() {
    switch (_selectedTemplate) {
      case 'auth_code':
        return '您的安全验证码为 859321，5分钟内有效。工作人员绝不会索取验证码，切勿泄露给他人。';
      case 'consume_bill':
        return '尊敬的贵宾，您在智慧商业(旗舰店)消费¥298.00已结算完成，感谢您的光临，祝您生活愉快！';
      case 'recharge_notice':
        return '尊敬的会员，您的会员卡已成功充值¥1000.00，当前卡内可用余额为¥2450.00，赠送100积分。';
      case 'appointment_reminder':
        return '温馨提醒：您预约的今日 15:30【总监定制美发设计·店长】即将开始，请提前10分钟到店。';
      case 'system_upgrade':
        return '【平台升级通知】海马店务系统将于今晚24:00进行性能例行维护，期间不影响收银机离线结账。';
      default:
        return '海马连锁门店管理系统通知消息。';
    }
  }

  void _sendMockSms() {
    final phone = _smsPhoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入接收人手机号')));
      return;
    }

    final reqId = 'REQ${DateTime.now().millisecondsSinceEpoch}';
    final bizId = 'BIZ20260911${DateTime.now().microsecond}';
    setState(() {
      _smsMockOutput = 'HTTP/1.1 200 OK\n'
          'Channel: ${_smsChannel.toUpperCase()} Direct Gateway\n'
          'RequestId: $reqId\n'
          'BizId: $bizId\n'
          'To: $phone\n'
          'Code: OK (DELIVRD)\n'
          'Cost: 112 ms · 单条扣费成功';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('✅ 短信下发成功！接收号码: $phone (回执ID: $bizId)'),
      ),
    );
  }

  // ==================== TAB 5: 套餐定价与加油包 ====================
  Widget _buildPlansTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('📱 短信扩容加油包定价 (超级管理员可调)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        _buildPackCard('基础入门包', '500 条', '¥ 50.00', '0.100 元/条', Colors.blue, '适合单店体验'),
        _buildPackCard('超值热销包', '1,250 条', '¥ 100.00', '0.080 元/条', Colors.deepOrange, '🔥 80% 租户首选'),
        _buildPackCard('连锁大客包', '4,285 条', '¥ 300.00', '0.070 元/条', Colors.purple, '适合多门店连锁'),
        _buildPackCard('集团特惠包', '10,000 条', '¥ 500.00', '0.050 元/条', Colors.green, '单价低至 5分/条'),

        const SizedBox(height: 20),
        const Text('☁️ 云端存储扩容加油包', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        _buildPackCard('云存储 50GB', '50 GB / 年', '¥ 199.00', '约 0.54元/天', Colors.indigo, '高速云备份'),
        _buildPackCard('云存储 200GB', '200 GB / 年', '¥ 499.00', '约 1.36元/天', Colors.indigo, '海量视频相册存证'),
      ],
    );
  }

  Widget _buildPackCard(String name, String amount, String price, String unit, Color color, String tag) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.bolt, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text(tag, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('容量: $amount · 折算单价: $unit', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // ==================== 手机号查店与超管代管登录弹窗 ====================
  void _openQueryStoreByPhoneDialog([String? initialPhone]) {
    final TextEditingController phoneController = TextEditingController(text: initialPhone ?? '');
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    bool hasSearched = false;
    String? searchError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> doSearch() async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) {
                setModalState(() {
                  searchError = '请输入要查询的手机号';
                });
                return;
              }
              setModalState(() {
                isSearching = true;
                searchError = null;
              });
              try {
                final res = await ApiClient().dio.get(
                  '/vendor/query-stores-by-phone',
                  queryParameters: {'phone': phone},
                );
                if (res.statusCode == 200 && res.data != null) {
                  final dynamic raw = res.data;
                  final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
                  if (list is List) {
                    final items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
                    setModalState(() {
                      searchResults = items;
                      isSearching = false;
                      hasSearched = true;
                    });
                    return;
                  }
                }
                setModalState(() {
                  searchResults = [];
                  isSearching = false;
                  hasSearched = true;
                });
              } catch (e) {
                setModalState(() {
                  isSearching = false;
                  hasSearched = true;
                  searchError = '查询失败: $e';
                });
              }
            }

            // 如果有初始手机号且未检索过，自动触发一次查询
            if (initialPhone != null && initialPhone.isNotEmpty && !hasSearched && !isSearching) {
              WidgetsBinding.instance.addPostFrameCallback((_) => doSearch());
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // 顶部把手与标题
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 20, right: 12, bottom: 12),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.phone_android, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '手机号查店 · 超管代管登录',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '输入商户/店长手机号查店，代管登录查看店铺数据',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // 搜索与快捷输入区
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 手机号输入框与搜索按钮
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '输入商户老板/店长/分店手机号',
                                  hintStyle: const TextStyle(fontSize: 13),
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: phoneController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            phoneController.clear();
                                            setModalState(() {});
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                ),
                                onSubmitted: (_) => doSearch(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: isSearching ? null : doSearch,
                              child: isSearching
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('查询店铺', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('💡 提示：输入商户入驻注册绑定的手机号，即可检索其关联的门店列表。',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),

                        if (searchError != null) ...[
                          const SizedBox(height: 8),
                          Text(searchError!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // 搜索结果列表
                  Expanded(
                    child: isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : !hasSearched
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.storefront_outlined, size: 54, color: AppColors.textMuted),
                                    SizedBox(height: 12),
                                    Text('请输入手机号检索店铺', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                    SizedBox(height: 4),
                                    Text('支持商户负责人、分店店长或绑定手机号检索', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              )
                            : searchResults.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.search_off, size: 54, color: AppColors.textMuted),
                                        SizedBox(height: 12),
                                        Text('未查询到与该手机号关联的店铺信息', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                        SizedBox(height: 4),
                                        Text('请确认手机号输入正确或商户门店已成功入驻', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: searchResults.length,
                                    itemBuilder: (context, index) {
                                      final store = searchResults[index];
                                      final storeName = store['storeName'] ?? '实体门店';
                                      final tenantName = store['tenantName'] ?? '商户';
                                      final managerName = store['managerName'] ?? '负责人';
                                      final phone = store['phone'] ?? '';
                                      final address = store['address'] ?? '未登记地址';
                                      final industry = store['industry'] ?? 'BEAUTY';

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: const BorderSide(color: AppColors.border),
                                        ),
                                        elevation: 0,
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(Icons.store, color: AppColors.primary, size: 20),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          storeName,
                                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '所属商户: $tenantName · 业态: $industry',
                                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                                                        const SizedBox(width: 4),
                                                        Text('店长/联系人: $managerName', style: const TextStyle(fontSize: 12)),
                                                        const SizedBox(width: 12),
                                                        const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                                                        const SizedBox(width: 4),
                                                        Text(phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            '地址: $address',
                                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(Icons.login, size: 16),
                                                  label: Text('🔑 代管登录进入【$storeName】', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF0F172A),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    if (widget.onEnterStore != null) {
                                                      widget.onEnterStore!(store);
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
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

}

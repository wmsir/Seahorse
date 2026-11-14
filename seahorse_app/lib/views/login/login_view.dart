import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/server_config.dart';
import '../../core/utils/platform_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/account_manager.dart';
import '../main_navigation_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberPassword = true;
  List<SavedAccountModel> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _rememberPassword = AccountManager.isRememberPasswordEnabled();
    _loadInitialAccount();
  }

  void _loadInitialAccount() {
    _savedAccounts = AccountManager.getSavedAccounts();
    final lastAccount = AccountManager.getLastUsedAccount();
    if (lastAccount != null) {
      _usernameController.text = lastAccount.username;
      if (lastAccount.rememberPassword && lastAccount.savedPassword.isNotEmpty) {
        _passwordController.text = lastAccount.savedPassword;
        _rememberPassword = true;
      } else {
        _rememberPassword = lastAccount.rememberPassword;
      }
    }
  }

  void _refreshSavedAccounts() {
    setState(() {
      _savedAccounts = AccountManager.getSavedAccounts();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectAccount(SavedAccountModel acc) {
    setState(() {
      _usernameController.text = acc.username;
      if (acc.rememberPassword && acc.savedPassword.isNotEmpty) {
        _passwordController.text = acc.savedPassword;
        _rememberPassword = true;
      } else {
        _passwordController.clear();
        _rememberPassword = acc.rememberPassword;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换账号: ${acc.realName.isNotEmpty ? acc.realName : acc.username}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入登录账号与密码')),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      username,
      password,
      rememberPassword: _rememberPassword,
    );

    if (success && mounted) {
      _refreshSavedAccounts();
      final isPhoneAccount = RegExp(r'^\d{11}$').hasMatch(auth.username);
      final isPlatformSuperAdmin = (auth.username.toLowerCase() == 'admin' ||
              auth.username.toLowerCase() == 'root_ops' ||
              auth.role == 'PLATFORM_DEVELOPER') &&
          !isPhoneAccount;

      if (isPlatformSuperAdmin) {
        // 平台开发运维超级管理员登录成功：直接进入超级管理员总控台
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigationView(startInAdminMode: true)),
        );
      } else {
        await context.read<StoreProvider>().loadStores();
        if (mounted) {
          context.read<StoreProvider>().reloadAllProviders(context);
        }
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationView(startInAdminMode: false)),
          );
        }
      }
    } else if (mounted) {
      final isNetworkErr = auth.errorMessage != null && auth.errorMessage!.contains('无法连接');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? '登录失败，请检查账号密码或服务器状态'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          action: isNetworkErr
              ? SnackBarAction(
                  label: '网络检测',
                  textColor: Colors.white,
                  onPressed: _showServerConfigSheet,
                )
              : null,
        ),
      );
    }
  }

  /// 账号切换弹窗
  void _showAccountSwitcherSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final accounts = AccountManager.getSavedAccounts();
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.switch_account_outlined, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            '切换已登录账号',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '已记录 ${accounts.length} 个账号，点击即可快速切换并自动填充登录信息',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: accounts.isEmpty
                        ? const Center(
                            child: Text(
                              '暂无已保存账号，成功登录后将自动在此记录',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: accounts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final acc = accounts[index];
                              final isCurrent = _usernameController.text == acc.username;

                              return InkWell(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _selectAccount(acc);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? AppColors.primary.withOpacity(0.06) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrent ? AppColors.primary : const Color(0xFFE2E8F0),
                                      width: isCurrent ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _getRoleBadgeColor(acc.role).withOpacity(0.15),
                                        child: Text(
                                          acc.realName.isNotEmpty
                                              ? acc.realName.substring(0, 1)
                                              : (acc.username.isNotEmpty ? acc.username.substring(0, 1) : 'U'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: _getRoleBadgeColor(acc.role),
                                          ),
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
                                                  acc.realName.isNotEmpty ? acc.realName : acc.username,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(width: 6),
                                                _buildRoleBadge(acc.role),
                                                if (isCurrent) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: const Text('当前选中', style: TextStyle(color: Colors.white, fontSize: 9.5)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '账号: ${acc.username}${acc.storeName.isNotEmpty ? ' · ${acc.storeName}' : ''}',
                                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  acc.rememberPassword ? Icons.check_circle : Icons.lock_clock_outlined,
                                                  size: 12,
                                                  color: acc.rememberPassword ? Colors.green : AppColors.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  acc.rememberPassword ? '已记住密码 (可免输直接登录)' : '未记住密码 (需输入密码)',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    color: acc.rememberPassword ? Colors.green : AppColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                                        tooltip: '移除记录',
                                        onPressed: () async {
                                          await AccountManager.removeAccount(acc.username);
                                          setSheetState(() {});
                                          _refreshSavedAccounts();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_alt_outlined, size: 16),
                      label: const Text('使用新账号登录 (清空当前输入)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _usernameController.clear();
                          _passwordController.clear();
                          _rememberPassword = true;
                        });
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

  /// 服务器网络连接诊断与通道切换弹窗
  void _showServerConfigSheet() {
    final customUrlCtrl = TextEditingController(text: ServerConfig.currentUrl);
    String pingResult = '';
    bool isTesting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.dns_outlined, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            '服务器网络诊断与切换',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
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
                    '若提示“无法连接到服务器”，可一键切换官方 80 端口标准通道或备用直连通道',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Text('当前连接地址：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          ServerConfig.currentUrl,
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 连通性测试按钮
                  ElevatedButton.icon(
                    icon: isTesting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.network_check_outlined, size: 16, color: Colors.white),
                    label: Text(isTesting ? '正在探测服务器...' : '一键测试网络连通性 (Ping)', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isTesting
                        ? null
                        : () async {
                            setSheetState(() => isTesting = true);
                            final res = await ServerConfig.testConnection(customUrlCtrl.text.trim());
                            setSheetState(() {
                              isTesting = false;
                              pingResult = res['success'] == true
                                  ? '🟢 连通正常: 耗时 ${res['durationMs']}ms (${res['message']})'
                                  : '🔴 连通异常: ${res['message']} (耗时 ${res['durationMs']}ms)';
                            });
                          },
                  ),
                  if (pingResult.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: pingResult.contains('🟢') ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pingResult,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: pingResult.contains('🟢') ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('快速选用服务通道：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: ServerConfig.serverPresets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = ServerConfig.serverPresets[i];
                        final isSel = ServerConfig.currentUrl == p['url'];
                        return InkWell(
                          onTap: () async {
                            final targetUrl = p['url']!;
                            await ServerConfig.updateServerUrl(targetUrl);
                            customUrlCtrl.text = targetUrl;
                            setSheetState(() {
                              isTesting = true;
                              pingResult = '正在探测 ${p['title']}...';
                            });
                            setState(() {});
                            final res = await ServerConfig.testConnection(targetUrl);
                            setSheetState(() {
                              isTesting = false;
                              pingResult = res['success'] == true
                                  ? '🟢 连通正常: 耗时 ${res['durationMs']}ms (${res['message']})'
                                  : '🔴 连通异常: ${res['message']} (耗时 ${res['durationMs']}ms)';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? AppColors.primary : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                                  size: 16,
                                  color: isSel ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(p['url']!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                  child: Text(p['tag']!, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
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
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        customUrlCtrl.dispose();
      });
    });
  }

  Widget _buildRoleBadge(String role) {
    final color = _getRoleBadgeColor(role);
    final label = _getRoleDisplayName(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getRoleBadgeColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
      case 'PLATFORM_DEVELOPER':
        return Colors.red;
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

  String _getRoleDisplayName(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
        return '企业主';
      case 'PLATFORM_DEVELOPER':
        return '开发运维';
      case 'STORE_MANAGER':
        return '店长';
      case 'CASHIER':
        return '收银员';
      case 'TECHNICIAN':
        return '技师';
      case 'WAITER':
        return '服务员';
      default:
        return role;
    }
  }

  Widget _buildQuickDemoChip(String label, String uname, String pwd) {
    return InkWell(
      onTap: () {
        setState(() {
          _usernameController.text = uname;
          _passwordController.text = pwd;
        });
        _handleLogin();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final targetCtrl = TextEditingController(text: _usernameController.text.trim());
    final codeCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final confirmPwdCtrl = TextEditingController();
    bool isSending = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('找回 / 重置登录密码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: targetCtrl,
                      decoration: const InputDecoration(
                        labelText: '登录账号 / 绑定手机号',
                        prefixIcon: Icon(Icons.person_search_outlined),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '6位验证码',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSending
                              ? null
                              : () async {
                                  final target = targetCtrl.text.trim();
                                  if (target.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('请先输入登录账号或绑定手机号')),
                                    );
                                    return;
                                  }
                                  setModalState(() => isSending = true);
                                  try {
                                    final res = await ApiClient().dio.post(
                                      '/auth/send-reset-code',
                                      data: {'account': target},
                                    );
                                    final raw = res.data;
                                    if (raw is Map && raw['code'] != null && raw['code'] != 200) {
                                      throw Exception(raw['message']?.toString() ?? '发送验证码失败');
                                    }
                                    final dataMap = (raw is Map && raw['data'] is Map)
                                        ? Map<String, dynamic>.from(raw['data'] as Map)
                                        : <String, dynamic>{};
                                    final serverCode = (dataMap['devCode'] ?? dataMap['code'])?.toString();
                                    if (serverCode != null && serverCode.isNotEmpty) {
                                      codeCtrl.text = serverCode;
                                    }
                                    final tipMsg = (raw is Map && raw['message'] != null)
                                        ? raw['message'].toString()
                                        : '验证码已发送，请在5分钟内完成操作';
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(tipMsg), backgroundColor: AppColors.success),
                                      );
                                    }
                                  } on DioException catch (e) {
                                    final errMsg = (e.response?.data is Map && e.response?.data['message'] != null)
                                        ? e.response!.data['message'].toString()
                                        : '发送验证码失败，请确认账号或手机号是否正确';
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(errMsg), backgroundColor: AppColors.error),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString().replaceFirst('Exception: ', '')),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setModalState(() => isSending = false);
                                    }
                                  }
                                },
                          child: Text(isSending ? '发送中...' : '获取验证码', style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPwdCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '设置新密码 (至少6位)',
                        prefixIcon: Icon(Icons.lock_outline),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPwdCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '确认新密码 (再次输入)',
                        prefixIcon: Icon(Icons.lock_outline),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final target = targetCtrl.text.trim();
                          final code = codeCtrl.text.trim();
                          final newPwd = newPwdCtrl.text.trim();
                          final confirmPwd = confirmPwdCtrl.text.trim();
                          if (target.isEmpty || code.length < 4 || newPwd.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请完整填写账号、验证码及至少6位新密码'), backgroundColor: AppColors.error),
                            );
                            return;
                          }
                          if (newPwd != confirmPwd) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('两次输入的新密码不一致，请重新核对'), backgroundColor: AppColors.error),
                            );
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            final res = await ApiClient().dio.post('/auth/reset-password', data: {
                              'account': target,
                              'code': code,
                              'newPassword': newPwd,
                            });
                            final raw = res.data;
                            if (raw is Map && raw['code'] != null && raw['code'] != 200) {
                              throw Exception(raw['message']?.toString() ?? '密码重置失败');
                            }
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              setState(() {
                                _usernameController.text = target;
                                _passwordController.text = newPwd;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('密码重置成功，请使用新密码登录！'), backgroundColor: AppColors.success),
                              );
                            }
                          } on DioException catch (e) {
                            final errMsg = (e.response?.data is Map && e.response?.data['message'] != null)
                                ? e.response!.data['message'].toString()
                                : '重置失败，请检查验证码或网络连接';
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errMsg), backgroundColor: AppColors.error),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setModalState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: const Text('确认重置'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        targetCtrl.dispose();
        codeCtrl.dispose();
        newPwdCtrl.dispose();
        confirmPwdCtrl.dispose();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_tethering, color: AppColors.textSecondary),
            tooltip: '服务器网络检测',
            onPressed: _showServerConfigSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 品牌 Logo 与标题
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/seahorse_logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '海马智慧商业门店 · 连锁移动管家',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '全场景房态管控 · 智能扫码收银 · 会员海马体画像',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF7DD3FC), width: 1.2),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✦ ', style: TextStyle(color: Color(0xFFD97706), fontSize: 13, fontWeight: FontWeight.w900)),
                        Text(
                          '海马会员，记住每位好客。',
                          style: TextStyle(
                            color: Color(0xFF0C4A6E),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // 多账号快捷切换 Chips (如果有多个已保存账号)
                if (_savedAccounts.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '👥 快捷切换账号',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      InkWell(
                        onTap: _showAccountSwitcherSheet,
                        child: Text(
                          '全部账号 (${_savedAccounts.length}) >',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _savedAccounts.map((acc) {
                        final isChosen = _usernameController.text == acc.username;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: CircleAvatar(
                              backgroundColor: isChosen ? Colors.white : AppColors.primary.withOpacity(0.15),
                              child: Text(
                                acc.realName.isNotEmpty
                                    ? acc.realName.substring(0, 1)
                                    : (acc.username.isNotEmpty ? acc.username.substring(0, 1) : 'U'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isChosen ? AppColors.primary : AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            label: Text(
                              '${acc.realName.isNotEmpty ? acc.realName : acc.username} (${_getRoleDisplayName(acc.role)})',
                            ),
                            backgroundColor: isChosen ? AppColors.primary : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isChosen ? Colors.white : AppColors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isChosen ? AppColors.primary : const Color(0xFFE2E8F0),
                              ),
                            ),
                            onPressed: () => _selectAccount(acc),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 账号输入 (已去除超级管理员admin提示)
                TextField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: '统一登录账号 / 手机号',
                    hintText: '支持 FWPT 统一通行证账号 / 手机号 / 员工工号',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),

                // 密码输入
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '登录密码',
                    hintText: '请输入登录密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 记住密码与多账号切换入口行
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _rememberPassword = !_rememberPassword);
                        AccountManager.setRememberPasswordEnabled(_rememberPassword);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _rememberPassword,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() => _rememberPassword = val ?? true);
                                AccountManager.setRememberPasswordEnabled(_rememberPassword);
                              },
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '记住密码 (下次免输)',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text(
                            '忘记密码？',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                        if (_savedAccounts.isNotEmpty)
                          TextButton.icon(
                            onPressed: _showAccountSwitcherSheet,
                            icon: const Icon(Icons.switch_account_outlined, size: 15),
                            label: Text(
                              '切换 (${_savedAccounts.length})',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 登录按钮
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('立即登录并进入门店', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),

                // ⚡ 快速体验行业演示方案
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚡ 一键体验多行业门店方案：',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildQuickDemoChip('💇 美业老板', 'beauty_boss', '123456'),
                          _buildQuickDemoChip('🍲 餐饮老板', 'dining_boss', '123456'),
                          _buildQuickDemoChip('🚗 汽修老板', 'auto_boss', '123456'),
                          _buildQuickDemoChip('🛍️ 零售老板', 'retail_boss', '123456'),
                          _buildQuickDemoChip('👑 旗舰店长', '13966668888', '123456'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 官方支持平台与网络状态提示
                Column(
                  children: [
                    InkWell(
                      onTap: _showServerConfigSheet,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sensors, size: 13, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '服务节点: ${ServerConfig.displayNodeLabel}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.tune, size: 12, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.verified, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          '官方平台: ${PlatformInfoUtils.officialWebsite}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${PlatformInfoUtils.getPlatformName()} · 全域数智连锁管理平台',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

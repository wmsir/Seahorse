import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/server_config.dart';
import '../../../core/utils/platform_info.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/sound_service.dart';
import '../../login/login_view.dart';
import 'package:provider/provider.dart';

class AccountSettingsTab extends StatelessWidget {
  final bool isSuperAdmin;
  final VoidCallback? onSwitchToAdmin;

  const AccountSettingsTab({
    Key? key,
    required this.isSuperAdmin,
    this.onSwitchToAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPhoneAccount = RegExp(r'^\d{11}$').hasMatch(auth.username);
    final isRealSuperAdmin = isSuperAdmin &&
        (auth.username.toLowerCase() == 'admin' ||
            auth.username.toLowerCase() == 'root_ops' ||
            auth.role == 'PLATFORM_DEVELOPER') &&
        !isPhoneAccount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 超级管理员控制中心入口（仅超管可见）
          if (isRealSuperAdmin && onSwitchToAdmin != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.amberAccent,
                    child: Icon(Icons.admin_panel_settings, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '超级管理员控制中心',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '全平台大盘、租户管控与支付通道',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: onSwitchToAdmin,
                    child: const Text('进入总控', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          // 2. 当前登录账号信息卡 + 修改密码入口
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.secondary.withOpacity(0.15),
                      child: const Icon(Icons.person, color: AppColors.secondary, size: 28),
                    ),
                    title: Text(
                      auth.realName.isEmpty ? '系统用户' : auth.realName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text('权限角色：${auth.role} · 账号：${auth.username}'),
                    trailing: TextButton.icon(
                      onPressed: () => _showChangePasswordDialog(context, auth.username),
                      icon: const Icon(Icons.lock_reset, size: 18, color: AppColors.primary),
                      label: const Text('修改密码', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2.5 🔊 门店实时语音播报与设备设置
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.volume_up, color: Colors.amber, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔊 实时订单语音播报引擎',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '出餐加菜、顾客开台、管家呼叫实时大声朗读',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.play_circle_fill, size: 18),
                          label: const Text('立即测试语音播报'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            await SoundService.playOrderAlertSound();
                            await Future.delayed(const Duration(milliseconds: 350));
                            await SoundService.speakText('海马智慧门店语音播报测试成功！新订单与呼叫服务将实时为您大声报单！');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📢 已触发测试语音！若未听到声音，请调大手机媒体音量与通知音量'),
                                  backgroundColor: Color(0xFF0F172A),
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.help_outline, size: 16),
                        label: const Text('设置指引'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showVoiceSettingsGuide(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. 官方服务平台与系统信息
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_done_outlined, color: AppColors.success),
                  title: const Text('云端通信节点'),
                  subtitle: Text(ServerConfig.displayNodeLabel),
                  trailing: TextButton(
                    onPressed: () async {
                      final sw = Stopwatch()..start();
                      try {
                        await ApiClient().dio.get('/public/platform-config');
                        sw.stop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ 云端网关连接极佳 (${sw.elapsedMilliseconds}ms)'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ 当前节点响应波动，系统已启用双机热备自动容灾'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('连通测速', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language, color: AppColors.primary),
                  title: const Text('官方网站'),
                  subtitle: const Text(PlatformInfoUtils.officialWebsite),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                    child: const Text('官方权威认证', style: TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_outlined, color: AppColors.info),
                  title: const Text('当前运行平台'),
                  subtitle: Text(PlatformInfoUtils.getPlatformName()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security, color: AppColors.success),
                  title: const Text('系统安全保障'),
                  subtitle: const Text('全链路通信安全防护 · 商用交易级数据隔离'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.textMuted),
                  title: const Text('APP 版本'),
                  subtitle: Text(PlatformInfoUtils.getFullVersionString()),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('最新正式版', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. 账号切换与退出登录按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.switch_account_outlined, color: AppColors.primary),
                  label: const Text('切换账号', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginView()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('退出登录'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginView()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, String currentUsername) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: AppColors.primary),
            SizedBox(width: 8),
            Text('修改当前账号密码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前登录账号：$currentUsername', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '新登录密码',
                hintText: '请输入至少6位新密码',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认新密码',
                hintText: '请再次输入新密码',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final p1 = newPassCtrl.text.trim();
              final p2 = confirmPassCtrl.text.trim();
              if (p1.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('新密码长度不能少于6位')),
                );
                return;
              }
              if (p1 != p2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的密码不一致')),
                );
                return;
              }
              try {
                await ApiClient().dio.post('/vendor/users/reset-password', data: {
                  'username': currentUsername,
                  'newPassword': p1,
                });
              } catch (_) {}
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ 密码修改成功！下次登录请使用新密码'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }

  void _showVoiceSettingsGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.volume_up, color: AppColors.primary),
            SizedBox(width: 8),
            Text('安卓手机语音播报设置指南', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('为保证在锁屏、灭屏或后台时均能大声播报订单，请确认以下手机系统设置：',
                  style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5)),
              SizedBox(height: 12),
              _GuideStepItem(
                num: '1',
                title: '调大手机音量',
                desc: '按手机侧边音量键，点击展开全部音量，确保【媒体音量】与【通知音量】已调大，切勿处于静音或免打扰状态。',
              ),
              _GuideStepItem(
                num: '2',
                title: '开启通知与悬浮窗权限',
                desc: '前往手机【设置 -> 应用管理 -> 海马智慧门店 -> 通知管理】，打开“允许通知”、“铃声/震动”、“横幅悬浮通知”。',
              ),
              _GuideStepItem(
                num: '3',
                title: '允许自启动与无限制后台运行',
                desc: '在手机【电池管理 / 应用启动管理】中，将“海马智慧门店”设置为“允许自启动”并关闭“电池优化省电策略”，防止系统熄屏后杀死网络报单服务。',
              ),
              _GuideStepItem(
                num: '4',
                title: '检查系统TTS语音引擎',
                desc: '前往手机【系统设置 -> 更多设置 -> 语言与输入法 -> 文字转语音(TTS)输出】，确保启用了内置系统中文语音服务。',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }
}

class _GuideStepItem extends StatelessWidget {
  final String num;
  final String title;
  final String desc;

  const _GuideStepItem({
    required this.num,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary,
            child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

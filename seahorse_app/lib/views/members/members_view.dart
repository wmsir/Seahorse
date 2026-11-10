import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/constants.dart';
import '../../core/constants/member_level_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/member_model.dart';
import '../../providers/member_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/empty_state.dart';
import '../scanner/camera_scanner_view.dart';
import 'member_create_dialog.dart';
import 'member_recharge_dialog.dart';
import 'member_detail_dialog.dart';
import '../../core/utils/phone_caller.dart';

class MembersView extends StatefulWidget {
  const MembersView({Key? key}) : super(key: key);

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  final _searchCtrl = TextEditingController();
  String? _lastStoreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final store = context.read<StoreProvider>();
        context.read<MemberProvider>().loadMembers(
          storeId: store.currentStoreId,
          tenantId: store.currentStore?.tenantId,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.watch<StoreProvider>();
    final curStoreId = store.currentStoreId;
    if (_lastStoreId != curStoreId) {
      _lastStoreId = curStoreId;
      context.read<MemberProvider>().loadMembers(
        storeId: curStoreId,
        tenantId: store.currentStore?.tenantId,
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openCreateMemberDialog() {
    showDialog(
      context: context,
      builder: (_) => const MemberCreateDialog(),
    );
  }

  void _openMemberDetailDialog(MemberModel member) {
    showDialog(
      context: context,
      builder: (_) => MemberDetailDialog(member: member),
    );
  }

  void _openRechargeDialog(MemberModel member) {
    showDialog(
      context: context,
      builder: (_) => MemberRechargeDialog(member: member),
    );
  }

  MemberLevelStyle _getMemberLevelStyle(String levelName) {
    return MemberLevelHelper.getStyle(levelName);
  }

  void _showMemberQrCodeDialog(MemberModel member) {
    final qrData = 'SEAHORSE:MEMBER:${member.phone}';
    final style = _getMemberLevelStyle(member.levelName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: style.badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(style.icon, color: style.badgeColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '${member.levelName} · ${member.memberNo}',
                    style: TextStyle(fontSize: 12, color: style.badgeColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: style.borderColor.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: style.badgeColor,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '卡号/手机: ${member.phone}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '📱 跨端通用会员码 · 支持在手机APP扫码与收银台盒子快速识读',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanMemberCard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraScannerView(purpose: ScanPurpose.memberLookup),
      ),
    );
    if (result != null) {
      final raw = (result['code'] ?? result['barcode'] ?? '').toString().trim();
      if (raw.isNotEmpty) {
        String cleanCode = raw;
        if (cleanCode.startsWith('SEAHORSE:MEMBER:')) {
          cleanCode = cleanCode.replaceFirst('SEAHORSE:MEMBER:', '');
        }
        _searchCtrl.text = cleanCode;
        if (mounted) {
          context.read<MemberProvider>().loadMembers(query: cleanCode);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已识别会员码：$cleanCode，正在检索会员档案...'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberProv = context.watch<MemberProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('会员中心与储值次卡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: '扫码查会员',
            onPressed: _scanMemberCard,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: '新增会员',
            onPressed: _openCreateMemberDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索会员姓名、手机号或会员卡号...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          memberProv.loadMembers();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, size: 20, color: AppColors.primary),
                      tooltip: '扫码识别',
                      onPressed: _scanMemberCard,
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) {
                memberProv.loadMembers(query: val);
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // 会员列表
          Expanded(
            child: memberProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : memberProv.members.isEmpty
                    ? EmptyState(
                        title: '未找到匹配会员记录',
                        subtitle: '可尝试变更搜索关键词或新建会员建档',
                        icon: Icons.people_outline,
                        actionLabel: '+ 新增会员建档',
                        onAction: _openCreateMemberDialog,
                      )
                    : RefreshIndicator(
                        onRefresh: () => memberProv.loadMembers(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: memberProv.members.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final m = memberProv.members[idx];
                            return _buildMemberCard(m);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(MemberModel member) {
    final style = _getMemberLevelStyle(member.levelName);
    final isDark = style.isDarkCard;

    return InkWell(
      onTap: () => _openMemberDetailDialog(member),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFFF59E0B) : style.borderColor.withOpacity(0.6),
            width: isDark ? 1.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0xFFF59E0B).withOpacity(0.12) : style.badgeColor.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：姓名、卡号与差异化等级徽章 (自适应弹性布局，杜绝标签溢出显示框)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFFF59E0B) : style.primaryColor.withOpacity(0.35),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : style.badgeBgColor,
                            child: Text(
                              member.name.isNotEmpty ? member.name.substring(0, 1) : '客',
                              style: TextStyle(
                                color: isDark ? const Color(0xFFFBBF24) : style.badgeTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFEF3C7) : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${member.memberNo} · ${Formatters.maskPhone(member.phone)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (member.phone.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => PhoneCaller.call(context, member.phone, targetName: member.name),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withOpacity(0.35),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.phone,
                                          size: 11,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: style.badgeBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: style.borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: style.primaryColor.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.icon, size: 13, color: style.badgeTextColor),
                        const SizedBox(width: 4),
                        Text(
                          member.levelName,
                          style: TextStyle(color: style.badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 20, color: isDark ? Colors.white12 : AppColors.border),

              // 资产信息：余额、积分、次卡
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAssetItem(
                    '卡内储值余额',
                    Formatters.currency(member.balance),
                    isPrimary: true,
                    primaryColor: isDark ? const Color(0xFFF59E0B) : style.badgeColor,
                    isDark: isDark,
                  ),
                  Container(width: 1, height: 28, color: isDark ? Colors.white12 : AppColors.border),
                  _buildAssetItem('积分资产', '${member.points}', isDark: isDark),
                  Container(width: 1, height: 28, color: isDark ? Colors.white12 : AppColors.border),
                  _buildAssetItem('可用次卡', '${member.timesCards.length} 张', isDark: isDark),
                ],
              ),

              // 次卡详情预览
              if (member.timesCards.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: member.timesCards.map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('🎫 ${c.templateName}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textPrimary)),
                            Text('剩 ${c.remainingCount}/${c.totalCount} 次', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFFBBF24) : AppColors.primary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // 快捷操作：详情/编辑 & 出示会员码 & 储值充值
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note, size: 16),
                    label: const Text('详情/编辑'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF94A3B8) : AppColors.textPrimary,
                      side: BorderSide(color: isDark ? Colors.white24 : AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _openMemberDetailDialog(member),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_2, size: 16),
                    label: const Text('会员码'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFFBBF24) : style.badgeColor,
                      side: BorderSide(color: isDark ? const Color(0xFFF59E0B) : style.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _showMemberQrCodeDialog(member),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_card, size: 16),
                    label: const Text('储值充值'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFFF59E0B) : AppColors.primary,
                      foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _openRechargeDialog(member),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetItem(String label, String value, {bool isPrimary = false, Color? primaryColor, bool isDark = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 16 : 15,
            fontWeight: FontWeight.bold,
            color: isPrimary ? (primaryColor ?? AppColors.primary) : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary)),
      ],
    );
  }
}

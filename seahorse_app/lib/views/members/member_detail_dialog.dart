import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/constants/member_level_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/phone_caller.dart';
import '../../models/member_model.dart';
import '../../providers/member_provider.dart';

class MemberDetailDialog extends StatefulWidget {
  final MemberModel member;

  const MemberDetailDialog({Key? key, required this.member}) : super(key: key);

  @override
  State<MemberDetailDialog> createState() => _MemberDetailDialogState();
}

class _MemberDetailDialogState extends State<MemberDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;
  late TextEditingController _notesController;
  late String _gender;
  late String _selectedLevel;
  late int _points;

  bool _isSaving = false;
  bool _isLoadingOrders = false;
  List<Map<String, dynamic>> _orders = [];

  final List<Map<String, String>> _levels = [
    {'code': 'REGULAR', 'name': '普卡会员 (无折扣)'},
    {'code': 'SILVER', 'name': '荣耀银卡 (95折)'},
    {'code': 'GOLD', 'name': '黄金VIP卡 (90折)'},
    {'code': 'VIP', 'name': 'VIP会员 (88折)'},
    {'code': 'PLATINUM', 'name': '至尊白金卡 (85折)'},
    {'code': 'DIAMOND', 'name': '黑钻VIP卡 (80折)'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phone);
    _birthdayController = TextEditingController(text: widget.member.birthday);
    _notesController = TextEditingController(text: widget.member.notes);
    _gender = widget.member.gender.isNotEmpty ? widget.member.gender : 'MALE';
    _points = widget.member.points;

    // 确定当前选中的等级code
    String matchCode = 'REGULAR';
    final raw = widget.member.rawLevel.toUpperCase();
    final name = widget.member.levelName;
    if (raw.contains('DIAMOND') || name.contains('钻')) {
      matchCode = 'DIAMOND';
    } else if (raw.contains('PLATINUM') || name.contains('白金')) {
      matchCode = 'PLATINUM';
    } else if (raw.contains('GOLD') || name.contains('金')) {
      matchCode = 'GOLD';
    } else if (raw.contains('SILVER') || name.contains('银')) {
      matchCode = 'SILVER';
    } else if (raw.contains('VIP')) {
      matchCode = 'VIP';
    }
    _selectedLevel = matchCode;

    _loadMemberOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberOrders() async {
    setState(() => _isLoadingOrders = true);
    final list = await context.read<MemberProvider>().getMemberOrders(widget.member.id);
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _saveMemberInfo() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('会员姓名不能为空'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('联系手机不能为空'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    final data = {
      'name': name,
      'phone': phone,
      'gender': _gender,
      'level': _selectedLevel,
      'birthday': _birthdayController.text.trim().isNotEmpty ? _birthdayController.text.trim() : null,
      'notes': _notesController.text.trim(),
      'points': _points,
    };

    final ok = await context.read<MemberProvider>().updateMember(widget.member.id, data);
    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        widget.member.name = name;
        widget.member.phone = phone;
        widget.member.gender = _gender;
        widget.member.rawLevel = _selectedLevel;
        widget.member.points = _points;
        widget.member.notes = _notesController.text.trim();
        widget.member.birthday = _birthdayController.text.trim();

        // 更新等级名称
        final matched = _levels.firstWhere((l) => l['code'] == _selectedLevel, orElse: () => _levels[0]);
        widget.member.levelName = matched['name']!.split(' ')[0];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 会员信息已保存并同步至服务器！'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请检查网络或服务端状态'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAdjustPointsDialog() {
    final deltaCtrl = TextEditingController(text: '100');
    final reasonCtrl = TextEditingController(text: '前台特批奖励积分');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('调整会员积分', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前可用积分: $_points 分', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 12),
            TextField(
              controller: deltaCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: '积分增减额 (支持正负数，如 100 或 -50)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: '调整原因 / 备注',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final delta = int.tryParse(deltaCtrl.text.trim()) ?? 0;
              if (delta == 0) return;
              Navigator.pop(ctx);
              final ok = await context.read<MemberProvider>().adjustPoints(
                widget.member.id,
                delta,
                reasonCtrl.text.trim(),
              );
              if (ok && mounted) {
                setState(() {
                  _points = (_points + delta < 0) ? 0 : (_points + delta);
                  widget.member.points = _points;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('积分调整成功，当前积分: $_points'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('确定调整'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = MemberLevelHelper.getStyle(widget.member.levelName);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          children: [
            // 头部会员简报
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: style.badgeColor.withOpacity(0.2),
                    child: Text(
                      widget.member.name.isNotEmpty ? widget.member.name.substring(0, 1) : '客',
                      style: TextStyle(color: style.badgeColor, fontSize: 20, fontWeight: FontWeight.bold),
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
                              widget.member.name,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: style.badgeBgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: style.borderColor),
                              ),
                              child: Text(
                                widget.member.levelName,
                                style: TextStyle(color: style.badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '卡号: ${widget.member.memberNo} · ${widget.member.phone}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => PhoneCaller.call(context, widget.member.phone, targetName: widget.member.name),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withOpacity(0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(Icons.phone, size: 12, color: Color(0xFF10B981)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab 切换栏
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '✏️ 档案编辑'),
                Tab(text: '💰 资产与积分'),
                Tab(text: '🧾 消费记录'),
              ],
            ),

            // Tab 内容区
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEditTab(),
                  _buildAssetsTab(),
                  _buildOrdersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: 档案资料编辑 ====================
  Widget _buildEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '会员姓名 *',
              prefixIcon: Icon(Icons.person_outline, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '手机号码 *',
              prefixIcon: Icon(Icons.phone_outlined, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('性别: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('先生 (男)'),
                selected: _gender == 'MALE',
                onSelected: (val) => setState(() => _gender = 'MALE'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('女士 (女)'),
                selected: _gender == 'FEMALE',
                onSelected: (val) => setState(() => _gender = 'FEMALE'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedLevel,
            decoration: const InputDecoration(
              labelText: '会员卡等级与折扣',
              prefixIcon: Icon(Icons.stars, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _levels.map((l) {
              return DropdownMenuItem(
                value: l['code'],
                child: Text(l['name']!, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedLevel = val);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _birthdayController,
            decoration: const InputDecoration(
              labelText: '生日日期 (如 1995-06-18)',
              prefixIcon: Icon(Icons.cake_outlined, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '客户偏好与海马体档案备注',
              prefixIcon: Icon(Icons.notes, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Text('🧠 海马体常态客情偏好快捷标注：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildMemoryTagChip('细软发质'),
              _buildMemoryTagChip('头皮敏感'),
              _buildMemoryTagChip('偏好轻音乐'),
              _buildMemoryTagChip('免辣免葱'),
              _buildMemoryTagChip('固定靠窗座'),
              _buildMemoryTagChip('5W-40全合成'),
              _buildMemoryTagChip('指定老技师'),
              _buildMemoryTagChip('勿推销办卡'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSaving ? '正在保存...' : '保存会员信息修改', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSaving ? null : _saveMemberInfo,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: 资产与积分统计 ====================
  Widget _buildAssetsTab() {
    final nextRule = MemberLevelHelper.getNextRule(_points);
    final pointsToNext = MemberLevelHelper.getPointsToNext(_points);
    final progress = MemberLevelHelper.getProgressRatio(_points);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 会员等级晋升与成长进度卡片
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.06),
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
                    Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          widget.member.levelName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF78350F)),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.rule, size: 14, color: Color(0xFFD97706)),
                      label: const Text('晋升规则', style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                      onPressed: _showLevelRulesDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('当前成长积分: $_points 分', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    if (nextRule != null)
                      Text(
                        '距【${nextRule.levelName}】差 $pointsToNext 分',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFEA580C), fontWeight: FontWeight.bold),
                      )
                    else
                      const Text(
                        '👑 已达黑钻至尊顶峰',
                        style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                  ),
                ),
              ],
            ),
          ),

          // 资产汇总四宫格
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBlock('卡内储值余额', Formatters.currency(widget.member.balance), color: AppColors.primary),
                    _buildStatBlock('累计消费金额', Formatters.currency(widget.member.totalSpent), color: Colors.amber.shade800),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBlock('当前可用积分', '$_points 分', isPoints: true),
                    _buildStatBlock('到店履约频次', '${widget.member.visitCount} 次'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 积分快捷操作按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('调整 / 增减会员积分'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showAdjustPointsDialog,
            ),
          ),
          const SizedBox(height: 16),

          // 可用次卡列表
          Row(
            children: [
              const Icon(Icons.confirmation_num_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('专属次卡列表 (${widget.member.timesCards.length} 张)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.member.timesCards.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text('暂无可用次卡', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            )
          else
            ...widget.member.timesCards.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.templateName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('有效期至: ${c.expireDate}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                  Text('剩余 ${c.remainingCount}/${c.totalCount} 次', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildStatBlock(String title, String value, {Color? color, bool isPoints = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ==================== TAB 3: 消费记录与履约账单 ====================
  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('暂无消费记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('会员开单收银后，消费金额与流水将在此保持双端一致展示', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final ord = _orders[idx];
        final orderNo = ord['orderNo']?.toString() ?? 'ORD-${ord['id']}';
        final actualAmount = (ord['actualAmount'] ?? 0).toString();
        final payChannel = ord['payChannel']?.toString() ?? 'STORED_VALUE';
        final settledAt = ord['settledAt']?.toString().replaceFirst('T', ' ').split('.')[0] ??
            ord['createdAt']?.toString().replaceFirst('T', ' ').split('.')[0] ?? '';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('单号: $orderNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('实付 ￥$actualAmount', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('时间: $settledAt', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payChannel == 'STORED_VALUE' ? '储值划扣' : (payChannel == 'WECHAT' ? '微信支付' : '已结算'),
                      style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLevelRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('👑 会员等级晋升规则表', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Text(
                    '消费 1 元 = 1 积分/经验。积分达成下一级门槛，系统自动平滑晋升并即刻生效专属折扣。',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                ),
                ...MemberLevelHelper.standardRules.map((rule) {
                  final style = MemberLevelHelper.getStyle(rule.levelCode);
                  final isReached = _points >= rule.threshold;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isReached ? style.badgeBgColor : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isReached ? style.borderColor : const Color(0xFFE2E8F0),
                        width: isReached ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(style.icon, size: 16, color: style.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  rule.levelName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: style.badgeTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '门槛: ${rule.threshold}分',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '折扣: ${rule.discount}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            if (isReached)
                              const Text('✓ 已解锁', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rule.privileges,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('我知道了')),
        ],
      ),
    );
  }

  Widget _buildMemoryTagChip(String tag) {
    final hasTag = _notesController.text.contains(tag);
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (hasTag) {
            _notesController.text = _notesController.text.replaceAll(tag, '').replaceAll('、、', '、').trim();
          } else {
            final cur = _notesController.text.trim();
            _notesController.text = cur.isEmpty ? tag : '$cur、$tag';
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: hasTag ? AppColors.primary.withOpacity(0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasTag ? AppColors.primary : AppColors.border,
            width: hasTag ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasTag) ...[
              const Icon(Icons.check, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: hasTag ? FontWeight.bold : FontWeight.normal,
                color: hasTag ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

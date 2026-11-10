import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/network/api_client.dart';
import '../../providers/member_provider.dart';
import '../../providers/store_provider.dart';

class MemberCreateDialog extends StatefulWidget {
  const MemberCreateDialog({Key? key}) : super(key: key);

  @override
  State<MemberCreateDialog> createState() => _MemberCreateDialogState();
}

class _MemberCreateDialogState extends State<MemberCreateDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0');
  final _giftCtrl = TextEditingController(text: '0');
  String _gender = 'MALE';
  String _level = '普卡会员';
  String _deductMode = 'PROPORTIONAL';
  List<Map<String, dynamic>> _chargeOptions = [];
  int? _selectedOptionId;

  @override
  void initState() {
    super.initState();
    _loadStoreChargeOptions();
  }

  void _loadStoreChargeOptions() async {
    try {
      final store = context.read<StoreProvider>();
      final sId = store.currentStoreId;
      final res = await ApiClient().dio.get('/store/register-config', queryParameters: {'storeId': sId});
      if (res.statusCode == 200 && res.data != null) {
        final dynamic raw = res.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map && data['chargeOptions'] != null) {
          final optRaw = data['chargeOptions'];
          List<dynamic> list = [];
          if (optRaw is String) {
            list = jsonDecode(optRaw) as List<dynamic>;
          } else if (optRaw is List) {
            list = optRaw;
          }
          if (mounted && list.isNotEmpty) {
            setState(() {
              _chargeOptions = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _balanceCtrl.dispose();
    _giftCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final balance = double.tryParse(_balanceCtrl.text.trim()) ?? 0.0;
    final gift = double.tryParse(_giftCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完整填写会员姓名与手机号码')),
      );
      return;
    }

    try {
      final memberProv = context.read<MemberProvider>();
      final store = context.read<StoreProvider>();
      final m = await memberProv.registerMember(
        name: name,
        phone: phone,
        gender: _gender,
        initialBalance: balance,
        initialGift: gift,
        deductMode: _deductMode,
        levelName: _level,
        storeId: store.currentStoreId,
        tenantId: store.currentStore?.tenantId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('新会员【${m.name}】(${m.memberNo}) 办理成功并已同步！'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('办理会员失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('👤 新建会员建档', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '会员姓名 / 尊称', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: '手机号码 (11位)', prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Text('性别：', style: TextStyle(fontSize: 14)),
                  Radio<String>(
                    value: 'MALE',
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                  const Text('男士'),
                  Radio<String>(
                    value: 'FEMALE',
                    groupValue: _gender,
                    onChanged: (val) => setState(() => _gender = val!),
                  ),
                  const Text('女士'),
                ],
              ),
              if (_chargeOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.card_membership, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text('本店首充方案 (点击直接选用并联动等级)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _chargeOptions.map((opt) {
                    final isSelected = _selectedOptionId == opt['id'];
                    final title = opt['title'] ?? '方案';
                    final p = opt['principal'] ?? 0;
                    final g = opt['gift'] ?? 0;
                    final lvlName = opt['levelName'] ?? '普卡会员';
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedOptionId = opt['id'];
                          _balanceCtrl.text = p.toString();
                          _giftCtrl.text = g.toString();
                          _level = lvlName;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              p > 0 ? '充￥$p 赠￥$g · $lvlName' : '免费开卡 · $lvlName',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(labelText: '初始会员等级', prefixIcon: Icon(Icons.stars_outlined)),
                items: const [
                  DropdownMenuItem(value: '普卡会员', child: Text('普卡会员 (无折扣)')),
                  DropdownMenuItem(value: '荣耀银卡', child: Text('荣耀银卡 (95折 · 300分)')),
                  DropdownMenuItem(value: '黄金VIP卡', child: Text('黄金VIP卡 (90折 · 800分)')),
                  DropdownMenuItem(value: 'VIP尊享卡', child: Text('VIP尊享卡 (88折 · 1200分)')),
                  DropdownMenuItem(value: '至尊白金卡', child: Text('至尊白金卡 (85折 · 2000分)')),
                  DropdownMenuItem(value: '黑钻至尊卡', child: Text('黑钻至尊卡 (80折 · 3500分)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _level = val);
                },
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '成长晋升：消费每支付1元累积1分，积分达标系统自动平滑升级，永久尊享专属折扣。',
                        style: TextStyle(fontSize: 11, color: Color(0xFF15803D), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '开卡首充本金 (元)', prefixIcon: Icon(Icons.account_balance_wallet_outlined)),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _giftCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '首充赠送金 (元)', prefixIcon: Icon(Icons.card_giftcard_outlined)),
              ),
              const SizedBox(height: 14),

              const Text('开卡储值扣减策略 *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('按本金/赠金比例双轨扣减', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('消费时按当前本金与赠送金余额同比例扣除，防赠金套现（推荐）', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                value: 'PROPORTIONAL',
                groupValue: _deductMode,
                onChanged: (val) => setState(() => _deductMode = val!),
              ),
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('优先扣减实充本金', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('消费时优先扣除实充本金，本金扣减完毕后再扣除赠送金', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                value: 'PRINCIPAL_FIRST',
                groupValue: _deductMode,
                onChanged: (val) => setState(() => _deductMode = val!),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('确认办理开卡', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

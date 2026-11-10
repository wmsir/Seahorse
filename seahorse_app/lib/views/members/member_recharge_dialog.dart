import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/member_model.dart';
import '../../providers/member_provider.dart';

class MemberRechargeDialog extends StatefulWidget {
  final MemberModel member;

  const MemberRechargeDialog({Key? key, required this.member}) : super(key: key);

  @override
  State<MemberRechargeDialog> createState() => _MemberRechargeDialogState();
}

class _MemberRechargeDialogState extends State<MemberRechargeDialog> {
  double _rechargeAmount = 1000;
  double _bonusAmount = 150;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _bonusCtrl;

  final List<Map<String, double>> _presets = [
    {'amount': 500, 'bonus': 50},
    {'amount': 1000, 'bonus': 150},
    {'amount': 2000, 'bonus': 350},
    {'amount': 3000, 'bonus': 600},
    {'amount': 5000, 'bonus': 1200},
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: '1000');
    _bonusCtrl = TextEditingController(text: '150');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bonusCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_rechargeAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入大于 0 的充值本金金额'), backgroundColor: AppColors.error),
      );
      return;
    }
    final memberProv = context.read<MemberProvider>();
    final ok = await memberProv.recharge(
      widget.member.id,
      _rechargeAmount,
      bonus: _bonusAmount,
    );

    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('会员【${widget.member.name}】充值 ${Formatters.currency(_rechargeAmount)} 成功！(赠送 ${Formatters.currency(_bonusAmount)})'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '💰 会员卡充值 · ${widget.member.name}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 16),

            Text('当前卡内余额：${Formatters.currency(widget.member.balance)} · 剩余积分：${widget.member.points}'),
            const SizedBox(height: 14),

            const Text('推荐充值特惠加油包：', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                final isSelected = _rechargeAmount == preset['amount'] && _bonusAmount == preset['bonus'];
                return ChoiceChip(
                  label: Text('充 ${preset['amount']!.toInt()} 送 ${preset['bonus']!.toInt()}'),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  onSelected: (_) {
                    setState(() {
                      _rechargeAmount = preset['amount']!;
                      _bonusAmount = preset['bonus']!;
                      _amountCtrl.text = _rechargeAmount.toInt().toString();
                      _bonusCtrl.text = _bonusAmount.toInt().toString();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            const Text('或自定义输入充值与赠金：', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '充值本金 (元)',
                      prefixText: '¥ ',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _rechargeAmount = double.tryParse(val.trim()) ?? 0.0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _bonusCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '赠送金额 (元)',
                      prefixText: '¥ ',
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _bonusAmount = double.tryParse(val.trim()) ?? 0.0;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('实际充值到账总额：', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    Formatters.currency(_rechargeAmount + _bonusAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text('确认收款充值 (${Formatters.currency(_rechargeAmount)})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

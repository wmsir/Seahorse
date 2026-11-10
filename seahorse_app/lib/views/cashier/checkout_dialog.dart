import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/constants/member_level_helper.dart';
import '../../core/utils/formatters.dart';
import '../../models/member_model.dart';
import '../../providers/cashier_provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/space_provider.dart';
import '../scanner/camera_scanner_view.dart';
import 'receipt_dialog.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({Key? key}) : super(key: key);

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  PaymentMethod _selectedMethod = PaymentMethod.wechat;
  MemberModel? _selectedMember;
  TimesCardItem? _selectedTimesCard;

  @override
  void initState() {
    super.initState();
    final cashier = context.read<CashierProvider>();
    final memberProv = context.read<MemberProvider>();
    final members = memberProv.members;

    if (members.isNotEmpty) {
      if (cashier.customerPhone != null && cashier.customerPhone!.isNotEmpty) {
        final matches = members.where((m) => m.phone == cashier.customerPhone);
        if (matches.isNotEmpty) {
          _selectedMember = matches.first;
        }
      }

      if (_selectedMember != null) {
        cashier.setDiscountRate(_selectedMember!.discountRate);
        if (_selectedMember!.timesCards.isNotEmpty) {
          _selectedTimesCard = _selectedMember!.timesCards.first;
        }
        if (_selectedMember!.balance >= cashier.payableAmount) {
          _selectedMethod = PaymentMethod.memberCard;
        } else {
          _selectedMethod = PaymentMethod.wechat;
        }
      } else {
        _selectedMethod = PaymentMethod.wechat;
      }
    }
  }

  void _onMemberChanged(MemberModel member) {
    setState(() {
      _selectedMember = member;
      if (member.timesCards.isNotEmpty) {
        _selectedTimesCard = member.timesCards.first;
      } else {
        _selectedTimesCard = null;
      }
      if (member.balance >= context.read<CashierProvider>().payableAmount) {
        _selectedMethod = PaymentMethod.memberCard;
      }
    });
    context.read<CashierProvider>().setDiscountRate(member.discountRate);
  }

  void _confirmCheckout() async {
    final cashier = context.read<CashierProvider>();
    final store = context.read<StoreProvider>();
    final spaceProv = context.read<SpaceProvider>();

    // 会员余额扣减判断
    if (_selectedMethod == PaymentMethod.memberCard) {
      if (_selectedMember == null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('未选择扣款会员'),
            content: const Text('当前为散客结算，尚未绑定会员卡。请在上方选择结算会员，或改用微信/支付宝/现金结账。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedMethod = PaymentMethod.wechat);
                },
                child: const Text('改用微信支付'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('好的')),
            ],
          ),
        );
        return;
      }
      if (_selectedMember!.balance < cashier.payableAmount) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('会员卡内储值余额不足'),
            content: Text('会员【${_selectedMember!.name}】当前储值可用余额为 ${Formatters.currency(_selectedMember!.balance)}，本次应付 ${Formatters.currency(cashier.payableAmount)}。\n请选择其他支付方式或前往会员中心充值。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedMethod = PaymentMethod.wechat);
                },
                child: const Text('改用微信支付'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('我知道了')),
            ],
          ),
        );
        return;
      }
      _selectedMember!.balance -= cashier.payableAmount;
    }

    // 次卡抵扣判断
    if (_selectedMethod == PaymentMethod.timesCard) {
      if (_selectedTimesCard == null || _selectedTimesCard!.remainingCount <= 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('次卡无可用次数'),
            content: const Text('当前会员暂无可抵扣的有效次卡，请选择其他支付方式。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedMethod = PaymentMethod.wechat);
                },
                child: const Text('改用微信支付'),
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('好的')),
            ],
          ),
        );
        return;
      }
    }

    final memberProv = context.read<MemberProvider>();
    final targetSpaceId = cashier.selectedSpaceId;

    late final dynamic order;
    try {
      order = await cashier.checkout(
        storeId: store.currentStoreId,
        paymentMethod: _selectedMethod,
        memberId: _selectedMember?.id,
        customerName: _selectedMember?.name ?? cashier.customerName,
        customerPhone: _selectedMember?.phone ?? cashier.customerPhone,
        timeCardNo: _selectedMethod == PaymentMethod.timesCard ? _selectedTimesCard?.cardNo : null,
      );
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('结算未完成'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('我知道了')),
            ],
          ),
        );
      }
      return;
    }

    if (_selectedMethod == PaymentMethod.memberCard && _selectedMember != null) {
      memberProv.updateMemberBalance(_selectedMember!.id, _selectedMember!.balance);
    }
    if (_selectedMethod == PaymentMethod.timesCard && _selectedMember != null && _selectedTimesCard != null) {
      await memberProv.deductTimesCard(_selectedMember!.id, _selectedTimesCard!.cardNo);
    } else {
      memberProv.loadMembers();
    }
    // 重新拉取服务端最新商品库存数据，保证云端与本地状态一致
    cashier.loadProducts();

    // 释放展位并翻台恢复空闲
    if (targetSpaceId != null) {
      await spaceProv.cleanAndResetSpace(store.currentStoreId, targetSpaceId);
    }
    await spaceProv.loadSpaces(store.currentStoreId);

    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => ReceiptDialog(
          order: order,
          storeName: store.currentStoreName,
        ),
      );
    }
  }

  Future<void> _scanToPay() async {
    final cashier = context.read<CashierProvider>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScannerView(
          purpose: ScanPurpose.payment,
          orderAmount: cashier.payableAmount,
        ),
      ),
    );

    if (result != null && mounted) {
      final paymentType = result['paymentType'] as String?;
      if (paymentType == 'wechat') {
        setState(() => _selectedMethod = PaymentMethod.wechat);
      } else if (paymentType == 'alipay') {
        setState(() => _selectedMethod = PaymentMethod.alipay);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已成功扫描${paymentType == "alipay" ? "支付宝" : "微信"}付款码 [${result["barcode"]}]，立即发起结算！'),
          backgroundColor: AppColors.success,
        ),
      );
      _confirmCheckout();
    }
  }

  void _showLevelRulesModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('👑 会员晋升阶梯规则', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: MemberLevelHelper.standardRules.map((rule) {
                final isCurrent = _selectedMember != null && _selectedMember!.points >= rule.threshold;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.levelName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            '门槛: ${rule.threshold}分 · ${rule.discount}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      if (isCurrent)
                        const Text('✓ 已达标', style: TextStyle(fontSize: 10, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('好的')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cashier = context.watch<CashierProvider>();
    final members = context.watch<MemberProvider>().members;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('💳 移动结账收银', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 16),

              // 金额总览卡片
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('消费原价合计：', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(Formatters.currency(cashier.rawTotalAmount), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (cashier.discountAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('会员立减 (${(_selectedMember?.discountRate ?? 1.0) * 10}折)：', style: const TextStyle(color: AppColors.error, fontSize: 13)),
                          Text('-${Formatters.currency(cashier.discountAmount)}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('应付结算金额：', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(
                          Formatters.currency(cashier.payableAmount),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 关联会员选择
              const Text('消费结算会员：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<MemberModel>(
                value: _selectedMember,
                isExpanded: true,
                items: members.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text('${m.name} (${m.levelName} · 余${Formatters.currency(m.balance)})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _onMemberChanged(val);
                },
              ),

              if (_selectedMember != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('👑', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '${_selectedMember!.levelName} (当前: ${_selectedMember!.points}分)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF78350F)),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _showLevelRulesModal,
                            child: const Text('规则 >', style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '本次消费预计积: +${cashier.payableAmount.toInt()} 分',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                          ),
                          if (_selectedMember!.nextLevelName != null)
                            Text(
                              '距【${_selectedMember!.nextLevelName}】差 ${_selectedMember!.pointsToNext} 分',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFEA580C), fontWeight: FontWeight.w600),
                            )
                          else
                            const Text(
                              '已达黑钻顶峰',
                              style: TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      if (_selectedMember!.nextLevelName != null &&
                          (_selectedMember!.points + cashier.payableAmount.toInt()) >=
                              (_selectedMember!.points + _selectedMember!.pointsToNext)) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '🎉 结算后预计将晋升为【${_selectedMember!.nextLevelName}】！',
                            style: const TextStyle(fontSize: 10, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 扫码盒子直接收款快捷通道
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  onPressed: cashier.cartItems.isEmpty ? null : _scanToPay,
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                  label: const Text(
                    '📷 扫码盒子收款 (微信/支付宝付款码)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF07C160),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),

              // 支付方式选项
              const Text('或手动选择结算收款渠道：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...PaymentMethod.values.map((method) {
                final isSelected = _selectedMethod == method;
                return InkWell(
                  onTap: () => setState(() => _selectedMethod = method),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? method.color.withOpacity(0.1) : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? method.color : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(method.icon, color: method.color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            method.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? method.color : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: method.color, size: 18),
                      ],
                    ),
                  ),
                );
              }),

              // 若选择次卡抵扣，展示可选次卡
              if (_selectedMethod == PaymentMethod.timesCard) ...[
                const SizedBox(height: 8),
                const Text('选择核销次卡：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                if (_selectedMember != null && _selectedMember!.timesCards.isNotEmpty)
                  DropdownButtonFormField<TimesCardItem>(
                    value: _selectedTimesCard,
                    isExpanded: true,
                    items: _selectedMember!.timesCards.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text('${c.templateName} (剩余 ${c.remainingCount} 次)'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTimesCard = val);
                    },
                  )
                else
                  const Text('当前会员暂无可抵扣次卡', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],

              const SizedBox(height: 20),

              // 确认收款结账
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cashier.cartItems.isEmpty ? null : _confirmCheckout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text('确认收款结算 (${Formatters.currency(cashier.payableAmount)})'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

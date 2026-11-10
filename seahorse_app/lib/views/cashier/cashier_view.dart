import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/product_model.dart';
import '../../providers/cashier_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/empty_state.dart';
import '../../models/member_model.dart';
import '../../providers/member_provider.dart';
import '../scanner/camera_scanner_view.dart';
import 'checkout_dialog.dart';

class CashierView extends StatefulWidget {
  const CashierView({Key? key}) : super(key: key);

  @override
  State<CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends State<CashierView> {
  String _selectedCategory = 'ALL';
  String? _lastStoreId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.watch<StoreProvider>();
    final curStoreId = store.currentStoreId;
    if (_lastStoreId != curStoreId) {
      _lastStoreId = curStoreId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final s = context.read<StoreProvider>();
          context.read<CashierProvider>().loadProducts(storeId: s.currentStoreId);
          context.read<CashierProvider>().loadCategories(
            industry: s.currentStore?.industry.name,
            storeId: s.currentStoreId,
            tenantId: s.currentStore?.tenantId,
          );
        }
      });
    }
  }

  List<String> get _categories {
    final cashier = context.read<CashierProvider>();
    final set = <String>{'ALL'};
    for (var p in cashier.products) {
      set.add(p.category);
    }
    return set.toList();
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CartBottomSheet(),
    );
  }

  void _scanBarcodeToAdd() async {
    final cashier = context.read<CashierProvider>();
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraScannerView(
          purpose: ScanPurpose.cashierAdd,
          title: '结账扫码 / 扫码点单加车',
        ),
      ),
    );
    if (res != null && res['success'] == true && mounted) {
      final code = (res['code'] ?? res['barcode'] ?? '').toString().trim();
      if (code.isEmpty) return;

      // 关键判定：如果用户选择了【会员码】模式，或扫出的是会员专属格式，绝不能弹“新商品录入”
      final isMember = res['isMemberCode'] == true ||
          res['purpose'] == ScanPurpose.memberLookup ||
          res['scanType'] == '顾客专属会员码' ||
          code.startsWith('SEAHORSE:MEMBER:') ||
          RegExp(r'^(M|VIP|CARD)\d+', caseSensitive: false).hasMatch(code);

      if (isMember) {
        _handleMemberCodeInCashier(code);
        return;
      }

      final matched = cashier.findProductByBarcode(code);
      if (matched != null) {
        // 匹配到已录入商品：直接显示价格并加入待结算清单
        cashier.addToCart(matched);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF065F46),
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📷 扫码成功：【${matched.title}】', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('单价: ¥${matched.price.toStringAsFixed(2)} | 条码: ${matched.productCode}，已计入待结算清单！', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: '查看清单',
              textColor: Colors.amberAccent,
              onPressed: _showCartSheet,
            ),
          ),
        );
      } else if (RegExp(r'^1[3-9]\d{9}$').hasMatch(code)) {
        // 扫到11位手机号：优先作为会员识别绑定
        _handleMemberCodeInCashier(code);
      } else {
        // 未录入商品：弹出快捷录入登记弹窗，录入后自动加入待结算清单
        _showQuickRegisterAndAddToCartDialog(code);
      }
    }
  }

  void _handleMemberCodeInCashier(String rawCode) {
    final cashier = context.read<CashierProvider>();
    final memberProv = context.read<MemberProvider>();
    String cleanCode = rawCode;
    if (cleanCode.startsWith('SEAHORSE:MEMBER:')) {
      cleanCode = cleanCode.replaceFirst('SEAHORSE:MEMBER:', '');
    }

    final members = memberProv.members;
    MemberModel? matchedMember;
    try {
      matchedMember = members.firstWhere(
        (m) => m.phone == cleanCode ||
               m.memberNo == cleanCode ||
               m.cardNo == cleanCode ||
               m.timesCards.any((c) => c.cardNo == cleanCode) ||
               m.id.toString() == cleanCode,
      );
    } catch (_) {
      matchedMember = null;
    }

    if (matchedMember != null) {
      cashier.setCustomer(
        matchedMember.name,
        matchedMember.phone,
        discountRate: matchedMember.discountRate,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F766E),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.verified, color: Colors.greenAccent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👤 会员扫码识别成功：【${matchedMember.name}】',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    Text(
                      '手机: ${matchedMember.phone} | 等级: ${matchedMember.levelName} (${(matchedMember.discountRate * 10).toStringAsFixed(1)}折) | 储值余额: ¥${matchedMember.balance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 虽未在本地列表中精确命中，但已按会员凭证关联收银台，杜绝误弹商品录入
      cashier.setCustomer('会员顾客', cleanCode);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.badge_outlined, color: Colors.amberAccent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👤 识别到会员标识码: $cleanCode',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    const Text('已成功关联为当前结账顾客。若为首次到店新客，点击结账即可开卡充值。',
                        style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showQuickRegisterAndAddToCartDialog(String barcode) {
    final cashier = context.read<CashierProvider>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '50');
    String category = '酒水饮料';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.add_shopping_cart, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('新商品扫码快捷录入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text('扫描条形码: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(barcode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('系统中暂未收录该条形码，请输入品名及价格，保存后将自动加入当前待结算清单：', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '商品品名 *',
                      hintText: '如 怡宝纯净水 555ml',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: '零售单价 (¥) *',
                            hintText: '如 3.0',
                            prefixText: '¥ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: '进货成本 (¥)',
                            hintText: '如 1.2',
                            prefixText: '¥ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(
                            labelText: '所属品类',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '酒水饮料', child: Text('酒水饮料')),
                            DropdownMenuItem(value: '休闲零食', child: Text('休闲零食')),
                            DropdownMenuItem(value: 'SPA精油', child: Text('SPA精油')),
                            DropdownMenuItem(value: '个护耗材', child: Text('个护耗材')),
                            DropdownMenuItem(value: '增值增项', child: Text('增值增项')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDlgState(() => category = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '入库库存',
                            hintText: '50',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 18, color: Colors.white),
                label: const Text('录入并计入结算单', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                  final cost = double.tryParse(costCtrl.text.trim()) ?? 0.0;
                  final stock = int.tryParse(stockCtrl.text.trim()) ?? 50;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写商品品名！')));
                    return;
                  }
                  if (price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写有效的销售单价！')));
                    return;
                  }

                  Navigator.pop(ctx);

                  final newProd = ProductModel(
                    id: 0,
                    productCode: barcode,
                    title: name,
                    category: category,
                    price: price,
                    cost: cost,
                    type: 'PHYSICAL',
                    stock: stock,
                    unit: '件',
                    description: '扫码收银快捷建档录入',
                  );

                  // 持久化保存至服务端
                  final saved = await cashier.saveProductToServer(newProd);
                  final itemToAdd = saved ?? newProd;

                  // 自动加车计入待结算清单
                  cashier.addToCart(itemToAdd);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('🎉 已录入【$name】(单价 ¥${price.toStringAsFixed(2)}) 并已加入待结算清单！'),
                        action: SnackBarAction(
                          label: '去结账',
                          textColor: Colors.amberAccent,
                          onPressed: _showCartSheet,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _scanBarcodeToStockIn() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScannerView(purpose: ScanPurpose.inventory)),
    );
    if (res != null && res['success'] == true && mounted) {
      final code = res['code'].toString().trim();
      _showQuickRegisterAndAddToCartDialog(code);
    }
  }

  Future<void> _refreshProducts() async {
    final cashier = context.read<CashierProvider>();
    final ok = await cashier.loadProducts();
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(ok ? '🔄 已刷新获取最新商品及价格列表' : '⚠️ 刷新失败，请检查网络连接'),
            ],
          ),
          backgroundColor: ok ? const Color(0xFF059669) : AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditProductDialog(ProductModel product) {
    final cashier = context.read<CashierProvider>();
    final nameCtrl = TextEditingController(text: product.title);
    final priceCtrl = TextEditingController(text: product.price.toStringAsFixed(2));
    final costCtrl = TextEditingController(text: product.cost.toStringAsFixed(2));
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final unitCtrl = TextEditingController(text: product.unit);
    final durationCtrl = TextEditingController(text: product.durationMinutes.toString());
    final descCtrl = TextEditingController(text: product.description);
    final codeCtrl = TextEditingController(text: product.productCode);

    final availableCats = _categories.where((c) => c != 'ALL').toList();
    if (availableCats.isEmpty) {
      availableCats.addAll(['特色服务', '日常洗护', '护理套餐', '酒水饮料', '个护耗材']);
    }
    String editCategory = product.category.isNotEmpty && availableCats.contains(product.category)
        ? product.category
        : (availableCats.isNotEmpty ? availableCats.first : '特色服务');
    String editProductType = product.type.isNotEmpty ? product.type : 'PHYSICAL';
    String? inSheetError;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final isService = editProductType == 'SERVICE';
            final isPhysical = editProductType == 'PHYSICAL';

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.edit_note, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('修改商品信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('ID: ${product.id > 0 ? product.id : "本地"} · 编码: ${product.productCode}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (inSheetError != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                inSheetError!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: '商品 / 服务品名 *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) {
                        if (inSheetError != null) setSheetState(() => inSheetError = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: editProductType,
                            decoration: InputDecoration(
                              labelText: '属性类型',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'PHYSICAL', child: Text('🧴 实物零售品')),
                              DropdownMenuItem(value: 'SERVICE', child: Text('💆 计量服务项')),
                              DropdownMenuItem(value: 'PACKAGE', child: Text('🎁 组合套餐项')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() {
                                  editProductType = val;
                                  if (val == 'SERVICE') {
                                    unitCtrl.text = '次';
                                  } else if (val == 'PACKAGE') {
                                    unitCtrl.text = '套';
                                  } else if (val == 'PHYSICAL') {
                                    unitCtrl.text = '件';
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: editCategory,
                            decoration: InputDecoration(
                              labelText: '所属品类',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: availableCats
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => editCategory = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: '销售单价 (¥) *',
                              prefixText: '¥ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) {
                              if (inSheetError != null) setSheetState(() => inSheetError = null);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: '进价成本 (¥)',
                              prefixText: '¥ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        if (isPhysical) ...[
                          Expanded(
                            child: TextField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '物理库存',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (isService) ...[
                          Expanded(
                            child: TextField(
                              controller: durationCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '服务时长 (分钟)',
                                suffixText: '分钟',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            decoration: InputDecoration(
                              labelText: '计量单位',
                              hintText: isService ? '次' : '件',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        labelText: '商品条码 / 编号',
                        prefixIcon: const Icon(Icons.qr_code, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '规格描述 / 介绍说明 (选填)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined, color: Colors.white),
                        label: Text(
                          isSaving ? '正在同步保存云端...' : '确认保存修改 (同步至云端)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving ? null : () async {
                          final name = nameCtrl.text.trim();
                          final cleanPrice = priceCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
                          final price = double.tryParse(cleanPrice) ?? product.price;
                          final cleanCost = costCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
                          final cost = double.tryParse(cleanCost) ?? product.cost;
                          final stock = int.tryParse(stockCtrl.text.trim()) ?? product.stock;
                          final duration = int.tryParse(durationCtrl.text.trim()) ?? product.durationMinutes;

                          if (name.isEmpty) {
                            setSheetState(() => inSheetError = '⚠️ 请填写商品品名！');
                            return;
                          }
                          if (price <= 0) {
                            setSheetState(() => inSheetError = '⚠️ 销售单价需大于 0！');
                            return;
                          }

                          setSheetState(() {
                            inSheetError = null;
                            isSaving = true;
                          });

                          final updated = ProductModel(
                            id: product.id,
                            productCode: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : product.productCode,
                            title: name,
                            category: editCategory,
                            price: price,
                            cost: cost,
                            type: editProductType,
                            stock: stock,
                            durationMinutes: duration,
                            unit: unitCtrl.text.trim().isEmpty ? product.unit : unitCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                          );

                          Navigator.pop(ctx);

                          cashier.addProduct(updated);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ 已成功更新【${updated.title}】并已同步！'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }

                          await cashier.saveProductToServer(updated);
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                        label: const Text('删除此商品 (不可恢复)', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDeleteProduct(product);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteProduct(ProductModel product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('确认删除商品？', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('即将从门店与云端下架并删除以下商品：', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('编码: ${product.productCode.isNotEmpty ? product.productCode : "无"} · 标价: ¥${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('注：删除后该商品将从收银台和列表移除，无法再进行点单与计费。', style: TextStyle(fontSize: 11, color: AppColors.error)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final cashier = context.read<CashierProvider>();
      final success = await cashier.deleteProductFromServer(product.id, productCode: product.productCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '商品【${product.title}】已从云端彻底删除' : '商品【${product.title}】已从收银台移除'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashier = context.watch<CashierProvider>();

    final filteredProducts = cashier.products.where((p) {
      if (_selectedCategory != 'ALL' && p.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('移动点单与收银台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新商品与价格 (同步云端)',
            onPressed: _refreshProducts,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: '扫码枪点单 (扫商品条形码)',
            onPressed: _scanBarcodeToAdd,
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: '商品扫码入库',
            onPressed: _scanBarcodeToStockIn,
          ),
          if (cashier.cartItems.isNotEmpty)
            TextButton(
              onPressed: () => cashier.clearCart(),
              child: const Text('清空', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 分类选择横向滑动条
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat == 'ALL' ? '全部品类' : cat),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // 项目与商品卡片列表 (支持下拉手势刷新)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              color: AppColors.primary,
              child: filteredProducts.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                        alignment: Alignment.center,
                        child: EmptyState(
                          title: _selectedCategory == 'ALL' ? '暂无在售商品或服务项目' : '当前分类暂无商品',
                          subtitle: '门店尚未配置商品，可在后台【项目商品】录入或点击右上角扫码入库（下拉可刷新）',
                          icon: Icons.shopping_bag_outlined,
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final product = filteredProducts[idx];
                        return _buildProductCard(product, cashier);
                      },
                    ),
            ),
          ),
        ],
      ),

      // 底部结算浮条
      bottomSheet: cashier.cartItems.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                child: Row(
                  children: [
                    InkWell(
                      onTap: _showCartSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shopping_cart, color: AppColors.primary),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cashier.cartItems.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: _showCartSheet,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('合计：', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                Text(
                                  Formatters.currency(cashier.rawTotalAmount),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                            if (cashier.selectedSpaceName != null)
                              Text(
                                '已关联：${cashier.selectedSpaceName}',
                                style: const TextStyle(fontSize: 11, color: AppColors.info),
                              ),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CheckoutDialog(),
                        );
                      },
                      child: const Text('立即结算', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProductCard(ProductModel product, CashierProvider cashier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: product.type == 'SERVICE' ? AppColors.primary.withOpacity(0.12) : AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                product.type == 'SERVICE' ? Icons.spa : Icons.inventory_2_outlined,
                color: product.type == 'SERVICE' ? AppColors.primary : AppColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        Formatters.currency(product.price),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      if (product.durationMinutes > 0) ...[
                        const SizedBox(width: 8),
                        Text('${product.durationMinutes}分钟', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                      if (product.isPhysical) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.stock <= 5 ? Colors.red.withOpacity(0.12) : AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '库存: ${product.stock} ${product.unit}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: product.stock <= 5 ? Colors.red : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  icon: const Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    cashier.addToCart(product);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已将【${product.title}】加入待结算清单'),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                  tooltip: '商品管理操作',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showEditProductDialog(product);
                    } else if (action == 'delete') {
                      _confirmDeleteProduct(product);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_note, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('修改商品信息', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('删除商品 (下架)', style: TextStyle(fontSize: 13, color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBottomSheet extends StatelessWidget {
  const _CartBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cashier = context.watch<CashierProvider>();
    final int totalCount = cashier.cartItems.fold(0, (sum, i) => sum + i.quantity);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('🛒 待结算消费清单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('共 $totalCount 件', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (cashier.cartItems.isNotEmpty)
                TextButton(
                  onPressed: () {
                    cashier.clearCart();
                    Navigator.pop(context);
                  },
                  child: const Text('清空清单', style: TextStyle(color: AppColors.error, fontSize: 13)),
                ),
            ],
          ),
          const Divider(),
          if (cashier.cartItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('待结算清单为空，请使用上方扫码或点击商品加车', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cashier.cartItems.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, idx) {
                  final item = cashier.cartItems[idx];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(Formatters.currency(item.price), style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                                const SizedBox(width: 8),
                                Text('小计: ${Formatters.currency(item.subtotal)}', style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.grey),
                        onPressed: () => cashier.updateQuantity(item.id, item.quantity - 1),
                      ),
                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 22, color: AppColors.primary),
                        onPressed: () => cashier.updateQuantity(item.id, item.quantity + 1),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('待付应结总额', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      Formatters.currency(cashier.rawTotalAmount),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                  label: const Text('立即结账收银', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => const CheckoutDialog(),
                    );
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../../core/network/api_client.dart';
import '../../../models/product_model.dart';
import '../../../providers/cashier_provider.dart';
import '../../../providers/store_provider.dart';
import '../../scanner/camera_scanner_view.dart';

class ProductEntryTab extends StatefulWidget {
  const ProductEntryTab({Key? key}) : super(key: key);

  @override
  State<ProductEntryTab> createState() => _ProductEntryTabState();
}

class _ProductEntryTabState extends State<ProductEntryTab> {
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  String _selectedType = 'ALL'; // ALL, PHYSICAL, SERVICE, PACKAGE
  String? _lastStoreId;

  // 分类列表，存储 {id, name}，与服务端保持一致
  List<Map<String, dynamic>> _categoryItems = [];

  // 兼容旧字段的 getter
  List<String> get _customCategories {
    final cashier = context.read<CashierProvider>();
    if (cashier.categories.isNotEmpty) {
      return cashier.categories
          .map((c) => c['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return _categoryItems.map((c) => c['name'] as String).toList();
  }

  @override
  void initState() {
    super.initState();
  }

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
          _loadServerCategories(
            storeId: s.currentStoreId,
            tenantId: s.currentStore?.tenantId,
            industry: s.currentStore?.industry.name,
          );
        }
      });
    }
  }

  Future<void> _loadServerCategories({String? storeId, String? tenantId, String? industry}) async {
    try {
      final Map<String, dynamic> params = {};
      if (storeId != null && storeId.isNotEmpty) params['storeId'] = storeId;
      if (tenantId != null && tenantId.isNotEmpty) params['tenantId'] = tenantId;
      if (industry != null && industry.isNotEmpty) params['industry'] = industry;

      final res = await ApiClient().dio.get('/product/categories', queryParameters: params);
      if (res.data != null && res.data['code'] == 200 && res.data['data'] is List) {
        final list = (res.data['data'] as List)
            .where((c) => c['name'] != null && c['name'].toString().isNotEmpty)
            .map((c) => {'id': c['id'], 'name': c['name'].toString()})
            .toList()
            .cast<Map<String, dynamic>>();
        if (mounted) {
          setState(() {
            _categoryItems = list;
          });
        }
      }
    } catch (_) {
      // 离线使用默认分类
    }
  }

  void _showCategoryManagementDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (mCtx) {
        final addCatCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
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
                          children: const [
                            Icon(Icons.category_outlined, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('🏷️ 项目与商品分类管理', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(mCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '店长/老板专属：在此维护商品与服务分类，实时同步至全店端。',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addCatCtrl,
                            decoration: const InputDecoration(
                              labelText: '新建分类名称',
                              hintText: '如：男士修容SPA',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('添加'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final name = addCatCtrl.text.trim();
                            if (name.isEmpty) return;
                            if (_categoryItems.any((c) => c['name'] == name)) return;
                            // 保存到服务端
                            dynamic newId;
                            try {
                              final resp = await ApiClient().dio.post('/product/category/save', data: {
                                'name': name,
                                'sortOrder': _categoryItems.length + 1,
                                'available': true,
                              });
                              if (resp.data?['data'] != null) {
                                newId = resp.data['data']['id'];
                              }
                            } catch (_) {}
                            final newItem = {'id': newId, 'name': name};
                            setDialogState(() {
                              _categoryItems.add(newItem);
                            });
                            setState(() {});
                            addCatCtrl.clear();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('已成功添加分类【$name】'), backgroundColor: AppColors.success),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('当前全部可用分类：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._categoryItems.map((catItem) {
                      final cat = catItem['name'] as String;
                      final catId = catItem['id'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  tooltip: '修改名称',
                                  onPressed: () {
                                    _promptRenameCategory(cat, (newName) async {
                                      // 同步到服务端
                                      try {
                                        await ApiClient().dio.post('/product/category/save', data: {
                                          if (catId != null) 'id': catId,
                                          'name': newName,
                                          'sortOrder': _categoryItems.indexOf(catItem) + 1,
                                          'available': true,
                                        });
                                      } catch (_) {}
                                      setDialogState(() {
                                        final idx = _categoryItems.indexOf(catItem);
                                        if (idx != -1) {
                                          _categoryItems[idx] = {'id': catId, 'name': newName};
                                        }
                                      });
                                      setState(() {});
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  tooltip: '删除分类',
                                  onPressed: () async {
                                    // 同步删除到服务端
                                    if (catId != null) {
                                      try {
                                        await ApiClient().dio.delete('/product/category/$catId');
                                      } catch (_) {}
                                    }
                                    setDialogState(() {
                                      _categoryItems.removeWhere((c) => c['name'] == cat);
                                    });
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('已删除分类【$cat】')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _promptRenameCategory(String oldName, Function(String) onRenamed) {
    final editCtrl = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改分类名称', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editCtrl,
          decoration: const InputDecoration(labelText: '新分类名称', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final val = editCtrl.text.trim();
              if (val.isNotEmpty && val != oldName) {
                onRenamed(val);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('分类名称已修改为【$val】'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('确认修改'),
          ),
        ],
      ),
    );
  }

  void _scanBarcodeToRegister() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraScannerView(
          purpose: ScanPurpose.inventory,
          title: '扫描商品条形码录入',
        ),
      ),
    );

    if (res != null && res['success'] == true && mounted) {
      final code = (res['code'] ?? res['barcode'] ?? '').toString().trim();
      if (code.isNotEmpty) {
        final cashier = context.read<CashierProvider>();
        final existing = cashier.findProductByBarcode(code);
        if (existing != null) {
          _showEditProductDialog(existing, isFromScan: true, scannedBarcode: code);
        } else {
          _showCreateProductDialog(initialBarcode: code);
        }
      }
    }
  }

  void _showCreateProductDialog({String? initialBarcode}) {
    final cashier = context.read<CashierProvider>();
    final codeCtrl = TextEditingController(text: initialBarcode ?? '');
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '');
    final costCtrl = TextEditingController(text: '');
    final stockCtrl = TextEditingController(text: '50');
    final unitCtrl = TextEditingController(text: '瓶');
    final durationCtrl = TextEditingController(text: '45');
    final descCtrl = TextEditingController();
    String category = _customCategories.isNotEmpty ? _customCategories.first : '默认分类';
    String productType = 'PHYSICAL'; // PHYSICAL, SERVICE, PACKAGE
    String? inSheetError;
    bool isSaving = false;

    final categories = _customCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setSheetState) {
            final isPhysical = productType == 'PHYSICAL';

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
                              child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            const Text('录入新商品 / 服务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 错误提示条
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

                    // 条形码输入与自动生成/重扫
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeCtrl,
                            decoration: InputDecoration(
                              labelText: '商品条形码 (EAN/Code) *',
                              hintText: '扫码获取或点右侧随机生成',
                              prefixIcon: const Icon(Icons.view_week_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('随机条码', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              inSheetError = null;
                              codeCtrl.text = '69${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.camera_alt_outlined),
                          tooltip: '重新扫码',
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CameraScannerView(purpose: ScanPurpose.inventory)),
                            );
                            if (res != null && res['success'] == true) {
                              setSheetState(() {
                                inSheetError = null;
                                codeCtrl.text = (res['code'] ?? res['barcode'] ?? '').toString().trim();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 商品品名
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: '商品 / 服务品名 *',
                        hintText: '如 依云天然矿泉水 500ml',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) {
                        if (inSheetError != null) setSheetState(() => inSheetError = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    // 商品类型与分类
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: productType,
                            decoration: InputDecoration(
                              labelText: '属性分类',
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
                                  productType = val;
                                  if (val == 'SERVICE') {
                                    unitCtrl.text = '次';
                                  } else if (val == 'PACKAGE') {
                                    unitCtrl.text = '套';
                                  } else {
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
                            value: category,
                            decoration: InputDecoration(
                              labelText: '行业品类',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => category = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 销售价与成本价
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: '销售单价 (¥) *',
                              hintText: '如 12.0',
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
                              labelText: '成本底价 (¥)',
                              hintText: '如 5.0',
                              prefixText: '¥ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 库存与单位 (实物才需要库存)
                    if (isPhysical) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '初始库存数量',
                                hintText: '如 50',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: unitCtrl,
                              decoration: InputDecoration(
                                labelText: '单位 (瓶/盒/件)',
                                hintText: '件',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (productType == 'SERVICE') ...[
                      Row(
                        children: [
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
                          Expanded(
                            child: TextField(
                              controller: unitCtrl,
                              decoration: InputDecoration(
                                labelText: '服务单位 (次/项)',
                                hintText: '次',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 描述规格
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '规格说明 / 介绍 (选填)',
                        hintText: '如 500ml 瓶装，常温饮品',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 提交按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined, color: Colors.white),
                        label: Text(
                          isSaving ? '正在保存同步上架...' : '保存并同步上架',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving ? null : () async {
                          final name = nameCtrl.text.trim();
                          String code = codeCtrl.text.trim();
                          final cleanPrice = priceCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
                          final price = double.tryParse(cleanPrice) ?? 0.0;
                          final cleanCost = costCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
                          final cost = double.tryParse(cleanCost) ?? 0.0;
                          final stock = int.tryParse(stockCtrl.text.trim()) ?? (isPhysical ? 50 : 0);
                          final unit = unitCtrl.text.trim().isEmpty ? (isPhysical ? '件' : '次') : unitCtrl.text.trim();
                          final duration = int.tryParse(durationCtrl.text.trim()) ?? (productType == 'SERVICE' ? 45 : 0);

                          if (name.isEmpty) {
                            setSheetState(() => inSheetError = '⚠️ 请填写商品 / 服务品名！');
                            return;
                          }
                          if (price <= 0) {
                            setSheetState(() => inSheetError = '⚠️ 请填写有效的销售单价（需大于0）！');
                            return;
                          }
                          if (code.isEmpty) {
                            // 若用户未填条码，自动分配唯一编码，绝不卡死页面
                            code = '69${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
                          }

                          setSheetState(() {
                            inSheetError = null;
                            isSaving = true;
                          });

                          final newProd = ProductModel(
                            id: 0,
                            productCode: code,
                            title: name,
                            category: category,
                            price: price,
                            cost: cost,
                            type: productType,
                            stock: stock,
                            durationMinutes: duration,
                            unit: unit,
                            description: descCtrl.text.trim(),
                          );

                          // 关闭底部弹窗
                          Navigator.pop(ctx);

                          // 立即插入本地列表与向后端保存
                          cashier.addProduct(newProd);
                          if (mounted) {
                            setState(() {
                              _selectedCategory = 'ALL';
                              _selectedType = 'ALL';
                              _searchQuery = '';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 商品【$name】(条码: $code) 已成功录入入库并同步上架！'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }

                          // 异步同步到服务器
                          await cashier.saveProductToServer(newProd);
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

  void _showEditProductDialog(ProductModel product, {bool isFromScan = false, String? scannedBarcode}) {
    final cashier = context.read<CashierProvider>();
    final nameCtrl = TextEditingController(text: product.title);
    final priceCtrl = TextEditingController(text: product.price.toStringAsFixed(2));
    final costCtrl = TextEditingController(text: product.cost.toStringAsFixed(2));
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final unitCtrl = TextEditingController(text: product.unit);
    final durationCtrl = TextEditingController(text: product.durationMinutes.toString());
    final descCtrl = TextEditingController(text: product.description);
    String editCategory = product.category.isNotEmpty && _customCategories.contains(product.category)
        ? product.category
        : (_customCategories.isNotEmpty ? _customCategories.first : '特色服务');
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isFromScan ? '扫码匹配成功' : '编辑商品信息',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('条形码: ${product.productCode}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 错误提示条
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

                    if (isFromScan) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Color(0xFF1D4ED8)),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text('已自动比对条码匹配该商品，可快捷更新价格或调配库存', style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF))),
                            ),
                          ],
                        ),
                      ),
                    ],

                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: '商品品名',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) {
                        if (inSheetError != null) setSheetState(() => inSheetError = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    // 商品类型与分类
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: editProductType,
                            decoration: InputDecoration(
                              labelText: '属性分类',
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
                                  if (val == 'SERVICE' && (unitCtrl.text.isEmpty || unitCtrl.text == '件')) {
                                    unitCtrl.text = '次';
                                  } else if (val == 'PACKAGE' && (unitCtrl.text.isEmpty || unitCtrl.text == '件')) {
                                    unitCtrl.text = '套';
                                  } else if (val == 'PHYSICAL' && unitCtrl.text == '次') {
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
                              labelText: '行业品类',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: (_customCategories.isNotEmpty ? _customCategories : ['特色服务', '日常洗护', '护理套餐', '进阶定制'])
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
                              labelText: '销售单价 (¥)',
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
                              labelText: '成本进价 (¥)',
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
                        if (editProductType == 'PHYSICAL') ...[
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
                        if (editProductType == 'SERVICE') ...[
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
                              hintText: editProductType == 'SERVICE' ? '次' : '件',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: '商品说明',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          isSaving ? '正在保存修改...' : '确认保存修改',
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
                          final duration = int.tryParse(durationCtrl.text.trim()) ?? product.durationMinutes;

                          if (name.isEmpty) {
                            setSheetState(() => inSheetError = '⚠️ 请填写商品品名！');
                            return;
                          }
                          if (price <= 0) {
                            setSheetState(() => inSheetError = '⚠️ 销售单价需大于0！');
                            return;
                          }

                          setSheetState(() {
                            inSheetError = null;
                            isSaving = true;
                          });

                          final updated = ProductModel(
                            id: product.id,
                            productCode: product.productCode,
                            title: name,
                            category: editCategory,
                            price: price,
                            cost: cost,
                            type: editProductType,
                            stock: int.tryParse(stockCtrl.text.trim()) ?? product.stock,
                            durationMinutes: duration,
                            unit: unitCtrl.text.trim().isEmpty ? product.unit : unitCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                          );

                          Navigator.pop(ctx);

                          cashier.addProduct(updated);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已更新【${updated.title}】商品信息！'), backgroundColor: AppColors.success),
                            );
                          }

                          await cashier.saveProductToServer(updated);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever, color: AppColors.error, size: 18),
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
            Text('即将从门店和云端下架并删除以下商品：', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
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
                  Text('条形码: ${product.productCode.isNotEmpty ? product.productCode : "无"} · 价格: ¥${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('注：删除后该商品将无法在收银台扫码或开单加购。', style: TextStyle(fontSize: 11, color: AppColors.error)),
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
            content: Text(success ? '商品【${product.title}】已从云端彻底删除' : '商品【${product.title}】已从列表移除'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashier = context.watch<CashierProvider>();
    final allProducts = cashier.products;

    // 过滤列表
    final filtered = allProducts.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.contains(_searchQuery) ||
          p.productCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.contains(_searchQuery);
      if (!matchesSearch) return false;

      if (_selectedType == 'PHYSICAL' && !p.isPhysical) return false;
      if (_selectedType == 'SERVICE' && !p.isService) return false;

      if (_selectedCategory != 'ALL' && p.category != _selectedCategory) return false;

      return true;
    }).toList();

    final physicalCount = allProducts.where((p) => p.isPhysical).length;
    final serviceCount = allProducts.where((p) => p.isService).length;
    final lowStockCount = allProducts.where((p) => p.isPhysical && p.stock <= 10).length;

    return RefreshIndicator(
      onRefresh: () async {
        await cashier.loadProducts();
        await _loadServerCategories();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部操作区 (扫码录入 + 手动添加)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Color(0xFFFBBF24), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '智能扫码商品管理',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '支持 69 零售条码、自建码秒级录入与结账联动',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
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
                        flex: 1,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 16),
                          label: const Text('扫码录入', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _scanBarcodeToRegister,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                          label: const Text('手动建档', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF475569)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showCreateProductDialog(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.category_outlined, color: Color(0xFF38BDF8), size: 16),
                          label: const Text('分类管理', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0284C7)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _showCategoryManagementDialog,
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, color: Color(0xFF34D399), size: 16),
                        label: const Text('刷新', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF059669)),
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final ok = await cashier.loadProducts();
                          await _loadServerCategories();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? '🔄 已刷新获取最新商品与分类数据' : '⚠️ 刷新失败，请检查网络连接'),
                                backgroundColor: ok ? AppColors.success : AppColors.error,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. 统计卡片
            Row(
              children: [
                Expanded(
                  child: _buildStatBadge('实物商品', '$physicalCount 款', AppColors.primary, Icons.inventory_2_outlined),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBadge('服务项目', '$serviceCount 项', const Color(0xFF7C3AED), Icons.spa_outlined),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatBadge('库存紧张', '$lowStockCount 款', lowStockCount > 0 ? Colors.red : Colors.green, Icons.warning_amber_outlined),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. 搜索框
            TextField(
              decoration: InputDecoration(
                hintText: '搜索商品品名 / 条码 / 分类...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 10),

            // 4. 类型过滤
            Row(
              children: [
                _buildTypeChip('全部品项 (${allProducts.length})', 'ALL'),
                const SizedBox(width: 8),
                _buildTypeChip('📦 实物零售 ($physicalCount)', 'PHYSICAL'),
                const SizedBox(width: 8),
                _buildTypeChip('💆 服务体验 ($serviceCount)', 'SERVICE'),
              ],
            ),
            const SizedBox(height: 10),

            // 4.1 分类过滤条
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('全部分类', 'ALL'),
                  const SizedBox(width: 6),
                  ...(cashier.categories.isNotEmpty ? cashier.categories : _categoryItems).map((c) {
                    final cName = (c['name'] ?? '').toString();
                    final cCount = cashier.getProductCountByCategory(cName);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildCategoryChip(cCount > 0 ? '$cName ($cCount)' : cName, cName),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. 商品清单
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isNotEmpty ? '未检索到包含【$_searchQuery】的商品' : '暂无商品数据，点击上方按钮扫码录入',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final p = filtered[idx];
                  final isPhysical = p.isPhysical;
                  final isLowStock = isPhysical && p.stock <= 10;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧图标
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isPhysical
                                ? const Color(0xFF0284C7).withOpacity(0.12)
                                : const Color(0xFF7C3AED).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPhysical ? Icons.shopping_bag_outlined : Icons.spa_outlined,
                            color: isPhysical ? const Color(0xFF0284C7) : const Color(0xFF7C3AED),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 中间信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.title,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPhysical ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.category,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isPhysical ? Colors.blue.shade700 : Colors.purple.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),

                              // 条码展示
                              Row(
                                children: [
                                  const Icon(Icons.qr_code, size: 13, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    p.productCode.isNotEmpty ? p.productCode : '无条形码',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // 价格与库存
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '¥${p.price.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                      ),
                                      Text(' / ${p.unit}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      if (p.cost > 0) ...[
                                        const SizedBox(width: 8),
                                        Text('进价: ¥${p.cost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ],
                                  ),
                                  if (isPhysical)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isLowStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '库存: ${p.stock} ${p.unit}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isLowStock ? Colors.red : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 右侧操作区：编辑与删除
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: AppColors.primary, size: 24),
                              tooltip: '编辑维护',
                              onPressed: () => _showEditProductDialog(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              tooltip: '删除商品',
                              onPressed: () => _confirmDeleteProduct(p),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String type) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String catKey) {
    final isSelected = _selectedCategory == catKey;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = catKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

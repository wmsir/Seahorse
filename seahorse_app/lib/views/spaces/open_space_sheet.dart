import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/space_model.dart';
import '../../models/product_model.dart';
import '../../models/staff_model.dart';
import '../../services/staff_service.dart';
import '../../services/cashier_service.dart';
import '../../providers/space_provider.dart';
import '../../providers/store_provider.dart';

class OpenSpaceSheet extends StatefulWidget {
  final SpaceModel space;

  const OpenSpaceSheet({Key? key, required this.space}) : super(key: key);

  @override
  State<OpenSpaceSheet> createState() => _OpenSpaceSheetState();
}

class _OpenSpaceSheetState extends State<OpenSpaceSheet> {
  final _customerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _peopleCount = 1;

  final StaffService _staffService = StaffService();
  final CashierService _cashierService = CashierService();
  List<StaffModel> _staffList = [];
  List<ProductModel> _productList = [];
  ProductModel? _selectedProduct;
  StaffModel? _selectedStaff;

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    final curStoreId = widget.space.storeId;
    final staff = await _staffService.getStaffList(storeId: curStoreId);
    final products = await _cashierService.getProducts(storeId: curStoreId);
    if (mounted) {
      setState(() {
        _staffList = staff;
        _productList = products.where((p) => p.type == 'SERVICE').toList();
        if (_productList.isEmpty) {
          _productList = products;
        }
        if (_staffList.isNotEmpty) {
          _selectedStaff = _staffList.first;
        } else {
          _selectedStaff = StaffModel(
            id: 1,
            staffNo: 'S001',
            storeId: curStoreId,
            realName: '服务顾问',
            phone: '13800000000',
            postName: '服务顾问',
          );
          _staffList = [_selectedStaff!];
        }

        // 首选开台项目默认不强制预选，支持用户按需选择或删除不选
        _selectedProduct = null;
      });
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showPeopleCountInputDialog() {
    final controller = TextEditingController(text: '$_peopleCount');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('输入同行到店人数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '同行到店人数',
                hintText: '请输入人数 (最少1人)',
                suffixText: '人',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '注：开台入座最少为 1 人，上限支持 99 人。',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim()) ?? 1;
              final count = val < 1 ? 1 : (val > 99 ? 99 : val);
              setState(() => _peopleCount = count);
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (_peopleCount < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('同行人数不能少于1人')),
      );
      return;
    }

    final name = _customerNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入客户名称')),
      );
      return;
    }

    final store = context.read<StoreProvider>();
    final spaceProv = context.read<SpaceProvider>();

    final staffName = _selectedStaff?.realName ?? '店长/技师';
    final productTitle = _selectedProduct?.title ?? '';
    final productPrice = _selectedProduct?.price ?? 0.0;

    final ok = await spaceProv.openSession(
      storeId: store.currentStoreId,
      spaceId: widget.space.id,
      customerName: name,
      phone: phone,
      technicianName: staffName,
      serviceItemName: productTitle,
      servicePrice: productPrice,
      serviceProductId: _selectedProduct?.id,
      peopleCount: _peopleCount,
    );

    if (ok && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('【${widget.space.spaceName}】开台成功！已派工：$staffName'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏨 开台入座 · ${widget.space.spaceName}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '区域：${widget.space.floorZone} · 最多可容纳 ${widget.space.capacity} 人',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // 顾客姓名与手机
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: '顾客尊称',
                      hintText: '请输入客户名称',
                      prefixIcon: Icon(Icons.person, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: '联系电话',
                      hintText: '请输入电话',
                      prefixIcon: Icon(Icons.phone, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 选择上钟技师
            const Text('指派上钟技师/服务人员：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<StaffModel>(
              value: _selectedStaff,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: _staffList.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text('${s.realName} (${s.postName})'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedStaff = val);
              },
            ),
            const SizedBox(height: 16),

            // 选择开台服务项目 (支持删除不选与留空开台)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('首选开台体验项目：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (_selectedProduct != null)
                  InkWell(
                    onTap: () => setState(() => _selectedProduct = null),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text('删除不选', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ProductModel?>(
              value: _selectedProduct,
              isExpanded: true,
              hint: const Text('可选择体验项目，或留空不选', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.spa_outlined, size: 18),
                suffixIcon: _selectedProduct != null
                    ? IconButton(
                        icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                        tooltip: '删除不选',
                        onPressed: () => setState(() => _selectedProduct = null),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                const DropdownMenuItem<ProductModel?>(
                  value: null,
                  child: Text('无 / 暂不选择项目 (仅开台入座)', style: TextStyle(color: AppColors.textMuted)),
                ),
                ..._productList.map((p) {
                  return DropdownMenuItem<ProductModel?>(
                    value: p,
                    child: Text('${p.title} - ${Formatters.currency(p.price)}'),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() => _selectedProduct = val);
              },
            ),
            const SizedBox(height: 16),

            // 到店人数选择
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('同行到店人数：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        if (widget.space.capacity > 0 && _peopleCount > widget.space.capacity)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Text(
                              '超额定${widget.space.capacity}人(已加座)',
                              style: TextStyle(fontSize: 10, color: Colors.amber.shade900),
                            ),
                          ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                            onPressed: _peopleCount > 1
                                ? () => setState(() => _peopleCount--)
                                : null,
                          ),
                          InkWell(
                            onTap: _showPeopleCountInputDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$_peopleCount 人',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                            onPressed: _peopleCount < 99
                                ? () => setState(() => _peopleCount++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 快捷选择人数 Chips
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...[1, 2, 3, 4, 5, 6].map((count) {
                      final isSelected = _peopleCount == count;
                      return ChoiceChip(
                        label: Text('$count人', style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.grey.shade100,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onSelected: (selected) {
                          if (selected) setState(() => _peopleCount = count);
                        },
                      );
                    }),
                    ChoiceChip(
                      label: Text(_peopleCount > 6 ? '$_peopleCount人(自定)' : '更多...', style: TextStyle(fontSize: 11, color: _peopleCount > 6 ? Colors.white : AppColors.textPrimary)),
                      selected: _peopleCount > 6,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.grey.shade100,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) => _showPeopleCountInputDialog(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 确认开台按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_selectedProduct != null
                    ? '确认立即开台并派工 (${Formatters.currency(_selectedProduct!.price)})'
                    : '确认立即开台并派工 (无预选项目)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

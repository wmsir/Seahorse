import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../models/product_model.dart';
import '../../models/space_model.dart';
import '../../models/staff_model.dart';
import '../../providers/space_provider.dart';
import '../../providers/store_provider.dart';
import '../../services/cashier_service.dart';
import '../../services/staff_service.dart';

/// 包厢/工位加项选择面板
class AppendItemSheet extends StatefulWidget {
  final SpaceModel space;

  const AppendItemSheet({Key? key, required this.space}) : super(key: key);

  @override
  State<AppendItemSheet> createState() => _AppendItemSheetState();
}

class _AppendItemSheetState extends State<AppendItemSheet> {
  final CashierService _cashierService = CashierService();
  final StaffService _staffService = StaffService();

  List<ProductModel> _allProducts = [];
  List<StaffModel> _staffList = [];
  bool _isLoading = true;

  // 多选集合: Product ID -> 数量 & Product ID -> 模型
  final Map<int, int> _selectedQuantities = {};
  final Map<int, ProductModel> _selectedProducts = {};
  String? _selectedStaffName;
  String _selectedCategory = '全部';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  List<String> _quickModifiers = [];
  String _staffDisplayMode = 'NICKNAME_FIRST';

  @override
  void initState() {
    super.initState();
    _selectedStaffName = widget.space.currentTechnicianName;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final targetStoreId = widget.space.storeId.isNotEmpty ? widget.space.storeId : storeProvider.currentStoreId;
      final ind = storeProvider.currentStore?.industry.name;

      final productsFuture = _cashierService.getProducts(storeId: targetStoreId);
      final staffFuture = _staffService.getStaffList(storeId: targetStoreId);
      final remarksFuture = _cashierService.getCommonRemarks(targetStoreId, ind);
      final displayModeFuture = _cashierService.getStaffDisplayMode(targetStoreId);

      final results = await Future.wait([productsFuture, staffFuture, remarksFuture, displayModeFuture]);
      if (mounted) {
        setState(() {
          _allProducts = results[0] as List<ProductModel>;
          _staffList = results[1] as List<StaffModel>;
          final rems = results[2] as List<String>;
          if (rems.isNotEmpty) {
            _quickModifiers = List<String>.from(rems);
          } else {
            _quickModifiers = ['微辣', '免葱姜蒜', '少盐少油', '常温饮品', '加重力度', '重点肩颈', '原厂配件优先', '加急催单'];
          }
          _staffDisplayMode = results[3] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _categories {
    final set = <String>{'全部'};
    for (var p in _allProducts) {
      if (p.category.isNotEmpty) {
        set.add(p.category);
      }
    }
    return set.toList();
  }

  List<ProductModel> get _filteredProducts {
    return _allProducts.where((p) {
      final matchesCategory = _selectedCategory == '全部' || p.category == _selectedCategory;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          p.title.toLowerCase().contains(query) ||
          p.productCode.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _totalSelectedCount {
    int count = 0;
    for (var q in _selectedQuantities.values) {
      count += q;
    }
    return count;
  }

  double get _addedTotal {
    double total = 0.0;
    _selectedQuantities.forEach((id, qty) {
      final p = _selectedProducts[id];
      if (p != null) {
        total += (p.price * qty);
      }
    });
    return total;
  }

  double get _projectedTotal {
    return widget.space.currentBillAmount + _addedTotal;
  }

  void _incrementProduct(ProductModel prod) {
    setState(() {
      _selectedProducts[prod.id] = prod;
      final current = _selectedQuantities[prod.id] ?? 0;
      if (current < 99) {
        _selectedQuantities[prod.id] = current + 1;
      }
    });
  }

  void _decrementProduct(ProductModel prod) {
    setState(() {
      final current = _selectedQuantities[prod.id] ?? 0;
      if (current <= 1) {
        _selectedQuantities.remove(prod.id);
        _selectedProducts.remove(prod.id);
      } else {
        _selectedQuantities[prod.id] = current - 1;
      }
    });
  }

  Future<void> _submitAppend() async {
    if (_selectedQuantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一项要追加的服务项目或商品')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final storeId = context.read<StoreProvider>().currentStoreId;
      final spaceProv = context.read<SpaceProvider>();
      final tech = _selectedStaffName ?? widget.space.currentTechnicianName;
      final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

      final List<String> appendedSummaries = [];
      bool allOk = true;

      for (var entry in _selectedQuantities.entries) {
        final prod = _selectedProducts[entry.key];
        if (prod == null) continue;
        final qty = entry.value;

        final success = await spaceProv.appendItem(
          storeId: storeId,
          spaceId: widget.space.id,
          product: prod,
          quantity: qty,
          modifiers: notes,
          technicianName: tech,
        );

        if (success) {
          appendedSummaries.add('${prod.title}×$qty');
        } else {
          allOk = false;
        }
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (allOk && appendedSummaries.isNotEmpty) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '已成功为【${widget.space.spaceName}】追加：${appendedSummaries.join('、')} (共+¥${_addedTotal.toStringAsFixed(2)})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.error,
              content: Text('追加项目提交失败，请重试'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('操作异常: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSpaceInfoBanner(),
          _buildSearchBar(),
          _buildCategoryFilter(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildProductListWithConfig(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 12, bottom: 8),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                '追加消费项目',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.space.spaceName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    if (widget.space.currentCustomerName != null)
                      Text(
                        '(${widget.space.currentCustomerName})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '当前账单: ¥${widget.space.currentBillAmount.toStringAsFixed(2)} · 已点 ${widget.space.currentItemCount} 项',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Text(
              '技师: ',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索项目名称、分类或拼音...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val);
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final cats = _categories;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final cat = cats[idx];
          final isSelected = cat == _selectedCategory;
          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.grey.shade100,
            onSelected: (val) {
              if (val) setState(() => _selectedCategory = cat);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            '未找到相关服务或商品',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListWithConfig() {
    final list = _filteredProducts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '请勾选或添加需要追加的项目 (支持多选)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            if (_selectedQuantities.isNotEmpty)
              Text(
                '已选 ${_selectedQuantities.length} 项 (共 $_totalSelectedCount 件)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...list.map((prod) {
          final qty = _selectedQuantities[prod.id] ?? 0;
          final isSelected = qty > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (qty == 0) {
                  _incrementProduct(prod);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 第一行：标题在左，价格在右（彻底隔离，防止任何重叠）
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 多选勾选标记
                        GestureDetector(
                          onTap: () {
                            if (isSelected) {
                              setState(() {
                                _selectedQuantities.remove(prod.id);
                                _selectedProducts.remove(prod.id);
                              });
                            } else {
                              _incrementProduct(prod);
                            }
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 10, top: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            prod.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '¥${prod.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                            Text(
                              '/${prod.unit}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 第二行：分类标签、时长标签，彻底在第二行展示，绝不与金额挤占
                    Row(
                      children: [
                        const SizedBox(width: 32), // 与勾选框对齐
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            prod.category,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ),
                        if (prod.durationMinutes > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 11, color: Colors.amber.shade800),
                                const SizedBox(width: 2),
                                Text(
                                  '${prod.durationMinutes}分钟',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        // 步进器或添加按钮
                        if (!isSelected)
                          InkWell(
                            onTap: () => _incrementProduct(prod),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 14, color: AppColors.primary),
                                  SizedBox(width: 2),
                                  Text('追加', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 14),
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _decrementProduct(prod),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 14),
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _incrementProduct(prod),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (prod.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          prod.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        _buildConfigSection(),
      ],
    );
  }

  Widget _buildConfigSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                '加项参数与服务配置',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
            ],
          ),
          if (_selectedQuantities.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('已选加项清单：', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedQuantities.entries.map((e) {
                final p = _selectedProducts[e.key];
                if (p == null) return const SizedBox.shrink();
                return Chip(
                  label: Text('${p.title} × ${e.value} (¥${(p.price * e.value).toStringAsFixed(1)})', style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() {
                      _selectedQuantities.remove(p.id);
                      _selectedProducts.remove(p.id);
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('指定服务', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStaffName != null &&
                            (_staffList.any((s) => s.getDisplayName(_staffDisplayMode) == _selectedStaffName || s.realName == _selectedStaffName) ||
                             _selectedStaffName == widget.space.currentTechnicianName)
                        ? _selectedStaffName
                        : (_staffList.isNotEmpty ? _staffList.first.getDisplayName(_staffDisplayMode) : null),
                    hint: const Text('选择服务人员', style: TextStyle(fontSize: 12)),
                    items: [
                      if (widget.space.currentTechnicianName != null && widget.space.currentTechnicianName!.isNotEmpty)
                        DropdownMenuItem(
                          value: widget.space.currentTechnicianName,
                          child: Text(
                            '原包厢服务: ${widget.space.currentTechnicianName}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ..._staffList.map((s) {
                        final displayName = s.getDisplayName(_staffDisplayMode);
                        return DropdownMenuItem(
                          value: displayName,
                          child: Text(displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStaffName = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('服务要求 / 特殊备注', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.settings, size: 13, color: AppColors.primary),
                label: const Text('管理常用标签', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                onPressed: _showManageRemarksSheet,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickModifiers.map((tag) {
              final isTagInNotes = _notesController.text.contains(tag);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isTagInNotes) {
                      _notesController.text = _notesController.text.replaceAll(tag, '').replaceAll('  ', ' ').trim();
                    } else {
                      final current = _notesController.text.trim();
                      _notesController.text = current.isEmpty ? tag : '$current $tag';
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTagInNotes ? AppColors.primary.withOpacity(0.12) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTagInNotes ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      color: isTagInNotes ? AppColors.primaryDark : AppColors.textSecondary,
                      fontWeight: isTagInNotes ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: '输入加项特殊说明（如额外加艾绒、茶饮加蜂蜜等）...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasSelection = _totalSelectedCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        hasSelection ? '已选 $_totalSelectedCount 件: ' : '追加金额: ',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '¥${_addedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '原账单 ¥${widget.space.currentBillAmount.toStringAsFixed(2)} ➔ 预计 ¥${_projectedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(
                  _isSubmitting
                      ? '追加中...'
                      : (hasSelection
                          ? '确认追加 ($_totalSelectedCount件 · +¥${_addedTotal.toStringAsFixed(2)})'
                          : '请选择追加项目'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: (_isSubmitting || !hasSelection) ? null : _submitAppend,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageRemarksSheet() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final targetStoreId = widget.space.storeId.isNotEmpty ? widget.space.storeId : storeProvider.currentStoreId;
    final TextEditingController newTagCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📝 管理门店常用服务要求与备注',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Text(
                    '此处增删标签将与浏览器管理后台及所有终端实时双向同步。',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickModifiers.map((tag) {
                          return Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () {
                              setSheetState(() {
                                _quickModifiers.remove(tag);
                              });
                              setState(() {});
                            },
                            backgroundColor: Colors.grey.shade100,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newTagCtrl,
                          decoration: InputDecoration(
                            hintText: '输入新标签 (如: 免葱/微辣/加急)',
                            hintStyle: const TextStyle(fontSize: 12),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onSubmitted: (val) {
                            final tag = val.trim();
                            if (tag.isNotEmpty && !_quickModifiers.contains(tag)) {
                              setSheetState(() {
                                _quickModifiers.add(tag);
                                newTagCtrl.clear();
                              });
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          final tag = newTagCtrl.text.trim();
                          if (tag.isNotEmpty && !_quickModifiers.contains(tag)) {
                            setSheetState(() {
                              _quickModifiers.add(tag);
                              newTagCtrl.clear();
                            });
                            setState(() {});
                          }
                        },
                        child: const Text('添加', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final success = await _cashierService.saveCommonRemarks(targetStoreId, _quickModifiers);
                        if (mounted) {
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? '✅ 常用备注标签已保存并同步至云端与浏览器！' : '保存常用备注失败，请稍后重试'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: const Text('保存并同步到全终端', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
}
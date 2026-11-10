import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../../providers/cashier_provider.dart';
import '../../../providers/store_provider.dart';

class CategoryManagementTab extends StatefulWidget {
  const CategoryManagementTab({Key? key}) : super(key: key);

  @override
  State<CategoryManagementTab> createState() => _CategoryManagementTabState();
}

class _CategoryManagementTabState extends State<CategoryManagementTab> {
  final TextEditingController _addController = TextEditingController();
  bool _isAdding = false;
  String? _lastStoreId;

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
          context.read<CashierProvider>().loadCategories(
            industry: s.currentStore?.industry.name,
            storeId: s.currentStoreId,
            tenantId: s.currentStore?.tenantId,
          );
          context.read<CashierProvider>().loadProducts(storeId: s.currentStoreId);
        }
      });
    }
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addNewCategory() async {
    final name = _addController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 请输入有效的分类名称')),
      );
      return;
    }

    final cashier = context.read<CashierProvider>();
    final store = context.read<StoreProvider>();

    if (cashier.categories.any((c) => c['name'] == name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ 分类【$name】已存在，请勿重复添加')),
      );
      return;
    }

    setState(() => _isAdding = true);

    try {
      await cashier.saveCategoryToServer({
        'name': name,
        'tenantId': store.currentStore?.tenantId,
        'industry': store.currentStore?.industry.name ?? 'GENERAL',
        'sortOrder': cashier.categories.length + 1,
        'available': true,
      });

      if (mounted) {
        _addController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 分类【$name】创建成功，已实时同步至云端与收银端！'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 添加分类失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final oldName = category['name']?.toString() ?? '';
    final catId = category['id'];
    final editCtrl = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text('编辑分类名称', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '重命名后，属于该分类的所有在售商品将自动更新为新分类名：',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: editCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '分类名称',
                hintText: '输入新的分类名',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newName = editCtrl.text.trim();
              if (newName.isEmpty || newName == oldName) {
                Navigator.pop(ctx);
                return;
              }

              final cashier = context.read<CashierProvider>();
              final store = context.read<StoreProvider>();

              Navigator.pop(ctx);

              await cashier.saveCategoryToServer({
                if (catId != null) 'id': catId,
                'name': newName,
                'tenantId': store.currentStore?.tenantId,
                'industry': store.currentStore?.industry.name ?? 'GENERAL',
                'sortOrder': category['sortOrder'] ?? 1,
                'available': true,
              }, oldName: oldName);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已将分类【$oldName】重命名为【$newName】'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('确认保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(Map<String, dynamic> category) {
    final name = category['name']?.toString() ?? '';
    final catId = category['id'];
    final cashier = context.read<CashierProvider>();
    final count = cashier.getProductCountByCategory(name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('确认删除分类？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  const TextSpan(text: '即将删除分类【'),
                  TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                  const TextSpan(text: '】。'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: count > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: count > 0 ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    count > 0 ? Icons.inventory_2_outlined : Icons.info_outline,
                    size: 18,
                    color: count > 0 ? AppColors.error : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      count > 0
                          ? '当前该分类下关联有 $count 款在售商品，删除后这些商品将被重置为未分类状态！'
                          : '当前分类下暂无商品，删除安全。',
                      style: TextStyle(
                        fontSize: 12,
                        color: count > 0 ? const Color(0xFFB91C1C) : AppColors.textSecondary,
                        fontWeight: count > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await cashier.deleteCategoryFromServer(catId, name);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '分类【$name】已成功从云端删除' : '删除操作完成'),
                    backgroundColor: success ? AppColors.success : AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cashier = context.watch<CashierProvider>();
    final store = context.watch<StoreProvider>();
    final categories = cashier.categories;

    return RefreshIndicator(
      onRefresh: () async {
        await cashier.loadCategories(industry: store.currentStore?.industry.name);
        await cashier.loadProducts();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // 顶部装饰卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF312E81).withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.category, color: Colors.amberAccent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '项目与商品分类管理',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '当前门店: ${store.currentStoreName} · 与云端数据库实时同步',
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: () => cashier.loadCategories(
                        industry: store.currentStore?.industry.name,
                        storeId: store.currentStoreId,
                        tenantId: store.currentStore?.tenantId,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('分类总数', '${categories.length} 个'),
                      Container(width: 1, height: 24, color: Colors.white24),
                      _buildHeaderStat('在售品项', '${cashier.products.length} 款'),
                      Container(width: 1, height: 24, color: Colors.white24),
                      _buildHeaderStat('同步状态', '已连接云端'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 新增分类快捷输入区
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('快速新建分类', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          decoration: InputDecoration(
                            hintText: '如：精选洗护、冷饮小吃、特色护理...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.bookmark_add_outlined, size: 18),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          onSubmitted: (_) => _addNewCategory(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: _isAdding
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add, size: 16),
                        label: Text(_isAdding ? '添加中' : '添加分类', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isAdding ? null : _addNewCategory,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 分类列表区域
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '全部分类清单 (${categories.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Text(
                '点击修改名称 / 删除分类',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (categories.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('暂无分类数据，请在上方输入框新建分类', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          else
            ...categories.map((catItem) {
              final name = catItem['name']?.toString() ?? '';
              final count = cashier.getProductCountByCategory(name);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 分类图标徽章
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.folder_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // 分类名称与关联商品数
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: count > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count 款在售',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: count > 0 ? const Color(0xFF1D4ED8) : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '同步状态: 已保存至云端 · 自动生效',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                    // 编辑按钮
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                      tooltip: '修改名称',
                      onPressed: () => _showEditCategoryDialog(catItem),
                    ),

                    // 删除按钮
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                      tooltip: '删除分类',
                      onPressed: () => _showDeleteCategoryDialog(catItem),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String title, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
      ],
    );
  }
}

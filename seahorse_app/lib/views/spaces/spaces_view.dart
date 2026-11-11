import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../models/space_model.dart';
import '../../providers/space_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/room_card.dart';
import '../../widgets/empty_state.dart';
import 'open_space_sheet.dart';
import 'space_detail_dialog.dart';

class SpacesView extends StatefulWidget {
  const SpacesView({Key? key}) : super(key: key);

  @override
  State<SpacesView> createState() => _SpacesViewState();
}

class _SpacesViewState extends State<SpacesView> {
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
          context.read<SpaceProvider>().loadSpaces(curStoreId);
        }
      });
    }
  }

  void _openSpace(SpaceModel space) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OpenSpaceSheet(space: space),
    );
    if (result == true) {
      final storeId = context.read<StoreProvider>().currentStoreId;
      context.read<SpaceProvider>().loadSpaces(storeId);
    }
  }

  void _showDetail(SpaceModel space) {
    showDialog(
      context: context,
      builder: (_) => SpaceDetailDialog(space: space),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final spaceProv = context.watch<SpaceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${store.spaceAlias}动态看板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => spaceProv.loadSpaces(store.currentStoreId),
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部运行指标胶囊条
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatBadge('全部', spaceProv.spaces.length, null, spaceProv.selectedStatus == null, () {
                    spaceProv.setStatus(null);
                  }),
                  const SizedBox(width: 8),
                  _buildStatBadge('空闲', spaceProv.idleCount, AppColors.success, spaceProv.selectedStatus == SpaceStatus.idle, () {
                    spaceProv.setStatus(spaceProv.selectedStatus == SpaceStatus.idle ? null : SpaceStatus.idle);
                  }),
                  const SizedBox(width: 8),
                  _buildStatBadge('服务中', spaceProv.occupiedCount, AppColors.info, spaceProv.selectedStatus == SpaceStatus.occupied, () {
                    spaceProv.setStatus(spaceProv.selectedStatus == SpaceStatus.occupied ? null : SpaceStatus.occupied);
                  }),
                  const SizedBox(width: 8),
                  _buildStatBadge('待清台', spaceProv.dirtyCount, AppColors.warning, spaceProv.selectedStatus == SpaceStatus.dirty, () {
                    spaceProv.setStatus(spaceProv.selectedStatus == SpaceStatus.dirty ? null : SpaceStatus.dirty);
                  }),
                  const SizedBox(width: 8),
                  _buildStatBadge('维护', spaceProv.maintenanceCount, AppColors.textMuted, spaceProv.selectedStatus == SpaceStatus.maintenance, () {
                    spaceProv.setStatus(spaceProv.selectedStatus == SpaceStatus.maintenance ? null : SpaceStatus.maintenance);
                  }),
                ],
              ),
            ),
          ),

          // 区域/楼层切换 Tab
          if (spaceProv.availableZones.isNotEmpty)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('全部区域'),
                      selected: spaceProv.selectedZone == 'ALL',
                      onSelected: (_) => spaceProv.setZone('ALL'),
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: spaceProv.selectedZone == 'ALL' ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: spaceProv.selectedZone == 'ALL' ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    ...spaceProv.availableZones.map((z) {
                      final isSelected = spaceProv.selectedZone == z;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ChoiceChip(
                          label: Text(z),
                          selected: isSelected,
                          onSelected: (_) => spaceProv.setZone(z),
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.border),

          // 空间卡片网格列表
          Expanded(
            child: spaceProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : spaceProv.filteredSpaces.isEmpty
                    ? EmptyState(
                        title: '暂无符合筛选条件的${store.spaceAlias}',
                        subtitle: '可尝试重置筛选或切换楼层区域',
                        icon: Icons.meeting_room_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: () => spaceProv.loadSpaces(store.currentStoreId),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1, // 移动端单列大卡片体验极佳
                            mainAxisExtent: 148,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: spaceProv.filteredSpaces.length,
                          itemBuilder: (ctx, idx) {
                            final space = spaceProv.filteredSpaces[idx];
                            return RoomCard(
                              space: space,
                              onTap: () => _showDetail(space),
                              onQuickAction: () {
                                if (space.status == SpaceStatus.idle) {
                                  _openSpace(space);
                                } else if (space.status == SpaceStatus.dirty) {
                                  spaceProv.cleanAndResetSpace(store.currentStoreId, space.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('【${space.spaceName}】已打扫完毕，恢复空闲！'), backgroundColor: AppColors.success),
                                  );
                                } else {
                                  _showDetail(space);
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color? color, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppColors.primary).withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? AppColors.primary) : AppColors.border,
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            if (color != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

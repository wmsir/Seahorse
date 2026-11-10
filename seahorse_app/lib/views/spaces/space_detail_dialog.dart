import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/space_model.dart';
import '../../providers/space_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/cashier_provider.dart';
import '../../providers/appointment_provider.dart';
import '../cashier/checkout_dialog.dart';
import 'open_space_sheet.dart';
import 'append_item_sheet.dart';

class SpaceDetailDialog extends StatelessWidget {
  final SpaceModel space;

  const SpaceDetailDialog({Key? key, required this.space}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreProvider>();
    final spaceProv = context.read<SpaceProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        space.spaceCode,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      space.spaceName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 18),

            // 基础信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('所在区域：${space.floorZone}'),
                Text('容纳能力：${space.capacity} 人'),
              ],
            ),
            const SizedBox(height: 6),
            Text('配套设施：${space.facilities.join(' · ')}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),

            // 动态状态区域
            if (space.status == SpaceStatus.occupied) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('当前在场顾客：', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${space.currentCustomerName} (${Formatters.maskPhone(space.currentCustomerPhone)})'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('当前服务技师：', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(space.currentTechnicianName ?? '未指定'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('已服务时长：', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('${space.servedMinutes} 分钟', style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('当前消费账单：', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          Formatters.currency(space.currentBillAmount),
                          style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 结账收银与加项操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('追加项目'),
                      onPressed: () async {
                        Navigator.pop(context);
                        final res = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AppendItemSheet(space: space),
                        );
                        if (res == true && context.mounted) {
                          final storeId = context.read<StoreProvider>().currentStoreId;
                          context.read<SpaceProvider>().loadSpaces(storeId);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.point_of_sale, size: 16),
                      label: const Text('结账收银'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () async {
                        final cashier = context.read<CashierProvider>();
                        cashier.clearCart();
                        cashier.bindSpace(
                          spaceId: space.id,
                          sessionId: space.currentSessionId,
                          spaceCode: space.spaceCode,
                          spaceName: space.spaceName,
                          customerName: space.currentCustomerName,
                          customerPhone: space.currentCustomerPhone,
                        );

                        List<OrderLineItem> loadedItems = [];
                        if (space.currentSessionId != null && space.currentSessionId! > 0) {
                          try {
                            final res = await ApiClient().dio.get('/session/${space.currentSessionId}/detail');
                            if (res.statusCode == 200 && res.data != null) {
                              final raw = res.data;
                              final detail = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
                              if (detail is Map && detail['lineItems'] is List) {
                                final rawList = detail['lineItems'] as List;
                                loadedItems = rawList.map((it) {
                                  final m = Map<String, dynamic>.from(it as Map);
                                  return OrderLineItem(
                                    id: int.tryParse(m['productId']?.toString() ?? '0') ?? 9999,
                                    title: m['productName']?.toString() ?? '${space.spaceName} 消费项',
                                    price: double.tryParse(m['price']?.toString() ?? '0') ?? 0.0,
                                    quantity: int.tryParse(m['quantity']?.toString() ?? '1') ?? 1,
                                    type: m['productType']?.toString() ?? 'SERVICE',
                                  );
                                }).toList();
                              }
                            }
                          } catch (_) {}
                        }

                        if (!context.mounted) return;

                        if (loadedItems.isNotEmpty) {
                          cashier.setCartItemsFromSession(loadedItems);
                        } else if (space.currentBillAmount > 0) {
                          cashier.addToCart(ProductModel(
                            id: 9999,
                            productCode: 'SRV_BILL_${space.spaceCode}',
                            title: '${space.spaceName} · 在场消费账单',
                            price: space.currentBillAmount,
                            category: '消费结算',
                            type: 'SERVICE',
                            durationMinutes: 60,
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('当前房台尚未录入消费项目，请先点击左侧【追加项目】后再结账'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => const CheckoutDialog(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ] else if (space.status == SpaceStatus.dirty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cleaning_services, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('上一位客人已离场结账，需完成更换床单毛巾与全室紫外线臭氧消毒。'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('已完成消毒打扫 · 一键恢复空闲'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: () async {
                    Navigator.pop(context);
                    await spaceProv.cleanAndResetSpace(store.currentStoreId, space.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('【${space.spaceName}】已打扫完毕，恢复空闲可接客！'), backgroundColor: AppColors.success),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text('当前包厢处于空闲待命状态，支持一键开台入座或接入预约顾客。', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.flash_on, size: 18),
                      label: const Text('一键开台入座'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => OpenSpaceSheet(space: space),
                        ).then((val) {
                          if (val == true) {
                            spaceProv.loadSpaces(store.currentStoreId);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('接入预约顾客'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAssignAppointmentDialog(context, space, store.currentStoreId);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAssignAppointmentDialog(BuildContext context, SpaceModel space, String storeId) async {
    final aptProv = context.read<AppointmentProvider>();
    final spaceProv = context.read<SpaceProvider>();
    await aptProv.loadAppointments(storeId);
    final pendingList = aptProv.appointments.where((a) => a.status == AppointmentStatus.pending).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('📅 接入预约 · ${space.spaceName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: pendingList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('当前暂无待到店预约顾客，建议直接点击【一键开台入座】。', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: pendingList.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final apt = pendingList[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(apt.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${apt.phone} · ${apt.serviceName}\n预约时间: ${apt.aptTime} · 技师: ${apt.staffName ?? "智能调配"}'),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('办理入座', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final ok = await aptProv.checkIn(
                            apt.id,
                            spaceId: space.id,
                            aptNo: apt.aptNo,
                            storeId: storeId,
                          );
                          if (ok) {
                            await spaceProv.loadSpaces(storeId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('顾客【${apt.customerName}】已顺利入座【${space.spaceName}】！展位与预约已变为【服务中】。'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('接入预约失败，请重试'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/chinese_date_utils.dart';
import '../../models/product_model.dart';
import '../../models/space_model.dart';
import '../../models/staff_model.dart';
import '../../services/staff_service.dart';
import '../../widgets/chinese_holiday_date_picker.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/cashier_provider.dart';
import '../../providers/space_provider.dart';
import '../../providers/store_provider.dart';

class CreateAppointmentSheet extends StatefulWidget {
  const CreateAppointmentSheet({Key? key}) : super(key: key);

  @override
  State<CreateAppointmentSheet> createState() => _CreateAppointmentSheetState();
}

class _CreateAppointmentSheetState extends State<CreateAppointmentSheet> {
  final _customerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _technicianCtrl = TextEditingController();

  ProductModel? _selectedProduct;
  SpaceModel? _selectedSpace;
  String _technicianName = '';
  List<StaffModel> _staffList = [];

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _peopleCount = 1;

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
    _loadStaffList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final spaces = context.read<SpaceProvider>().spaces;
      if (_selectedSpace == null && spaces.isNotEmpty) {
        final idleSpace = spaces.where((s) => s.status == SpaceStatus.idle).toList();
        setState(() {
          _selectedSpace = idleSpace.isNotEmpty ? idleSpace.first : spaces.first;
        });
      }
    });
  }

  Future<void> _loadStaffList() async {
    final curStoreId = context.read<StoreProvider>().currentStoreId;
    final staff = await StaffService().getStaffList(storeId: curStoreId);
    if (mounted) {
      setState(() {
        _staffList = staff;
        if (_staffList.isNotEmpty) {
          _technicianName = _staffList.first.getDisplayName();
          _technicianCtrl.text = _technicianName;
        } else {
          _technicianName = '专职服务顾问';
          _technicianCtrl.text = _technicianName;
        }
      });
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _technicianCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _customerNameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完整输入顾客姓名与联系电话')),
      );
      return;
    }

    final cashier = context.read<CashierProvider>();
    final services = cashier.products.where((p) => p.type == 'SERVICE').toList();
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 当前门店尚未配置预约服务项目，请先点击配置服务项目后再使用！'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final store = context.read<StoreProvider>();
    final aptProv = context.read<AppointmentProvider>();
    final spaceProv = context.read<SpaceProvider>();

    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final effectiveProduct = _selectedProduct ?? services.first;
    final serviceTitle = effectiveProduct.title;
    final servicePrice = effectiveProduct.price;
    final effectiveSpace = _selectedSpace ?? (spaceProv.spaces.isNotEmpty ? spaceProv.spaces.first : null);

    final ok = await aptProv.createAppointment(
      storeId: store.currentStoreId,
      customerName: name,
      phone: phone,
      serviceName: serviceTitle,
      servicePrice: servicePrice,
      aptDate: dateStr,
      aptTime: timeStr,
      spaceCode: effectiveSpace?.spaceCode ?? '',
      spaceName: effectiveSpace?.spaceName ?? '待到店排房',
      staffName: _technicianName,
      peopleCount: _peopleCount,
      notes: _notesCtrl.text.trim(),
    );

    if (ok && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('顾客【$name】预约登记成功！服务：$serviceTitle (¥$servicePrice)'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _openQuickAddServiceDialog(BuildContext ctx) {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '128');
    final durationCtrl = TextEditingController(text: '45');
    final categoryCtrl = TextEditingController(text: '特色服务');

    showDialog(
      context: ctx,
      builder: (dCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.room_service_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('配置新预约服务项目', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '当前门店暂无预约服务项目。配置完成后将即刻同步至预约中心、收银台与在线点单端。',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '服务项目名称 *',
                    hintText: '如：精修剪裁造型 / 招牌全身SPA',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '标牌单价 (¥) *',
                          prefixText: '¥ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '时长 (分钟)',
                          suffixText: 'min',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: '所属分类',
                    hintText: '如：美发造型 / 养生保健',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final t = titleCtrl.text.trim();
                final p = double.tryParse(priceCtrl.text.trim()) ?? 0;
                final dur = int.tryParse(durationCtrl.text.trim()) ?? 45;
                final cat = categoryCtrl.text.trim().isEmpty ? '特色服务' : categoryCtrl.text.trim();
                if (t.isEmpty || p <= 0) {
                  ScaffoldMessenger.of(dCtx).showSnackBar(
                    const SnackBar(content: Text('请输入合法的服务名称与单价')),
                  );
                  return;
                }

                final cashier = context.read<CashierProvider>();
                final newProd = ProductModel(
                  id: 0,
                  productCode: 'SRV${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  title: t,
                  price: p,
                  category: cat,
                  type: 'SERVICE',
                  stock: 0,
                  cost: p * 0.3,
                  unit: '次',
                  description: '服务时长$dur分钟',
                );

                cashier.addProduct(newProd);
                await cashier.saveProductToServer(newProd);
                Navigator.pop(dCtx);
                if (mounted) {
                  setState(() {
                    _selectedProduct = newProd;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 预约服务项目【$t】配置成功！已为您自动选定。'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('保存并选定'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleCtrl.dispose();
        priceCtrl.dispose();
        durationCtrl.dispose();
        categoryCtrl.dispose();
      });
    });
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
                const Text(
                  '📅 登记新顾客预约排班',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // 顾客姓名与电话
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: '顾客尊称 (如李先生)',
                      prefixIcon: Icon(Icons.person_outline),
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
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 服务项目
            const Text('预约服务项目：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Builder(
              builder: (ctx) {
                final cashier = ctx.watch<CashierProvider>();
                final products = cashier.products.where((p) => p.type == 'SERVICE').toList();
                if (products.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                            SizedBox(width: 8),
                            Text(
                              '暂未配置预约服务项目',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '当前门店尚未上架/配置可预约的服务项目。为保障履约规范，请先配置服务项目后再发起预约。',
                          style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_circle_outline, size: 16),
                            label: const Text('➕ 立即配置预约服务项目'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              _openQuickAddServiceDialog(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return DropdownButtonFormField<ProductModel>(
                  value: _selectedProduct ?? products.first,
                  isExpanded: true,
                  items: products.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text('${p.title} (${Formatters.currency(p.price)})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProduct = val);
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            // 指派技师
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('指派专属技师：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (_staffList.isNotEmpty)
                  const Text('点击快捷指定空闲在岗技师', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (ctx) {
                final spaceProv = ctx.watch<SpaceProvider>();
                final busyTechs = spaceProv.spaces
                    .where((s) => s.status == SpaceStatus.occupied && s.currentTechnicianName != null)
                    .map((s) => s.currentTechnicianName!.trim())
                    .toSet();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_staffList.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _staffList.map((staff) {
                          final isBusy = busyTechs.contains(staff.realName);
                          final isSelected = _technicianName == staff.realName;

                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isBusy ? Colors.amber.shade700 : Colors.green.shade600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${staff.realName} ${isBusy ? '(服务中)' : '(空闲)'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : (isBusy ? Colors.amber.shade900 : AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: isBusy ? Colors.amber.shade50 : Colors.green.shade50,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : (isBusy ? Colors.amber.shade300 : Colors.green.shade300),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _technicianName = staff.realName;
                                  _technicianCtrl.text = staff.realName;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _technicianCtrl,
                      decoration: const InputDecoration(
                        hintText: '输入技师工号或姓名 (如：88号技师)',
                        prefixIcon: Icon(Icons.person_pin),
                      ),
                      onChanged: (v) => _technicianName = v.trim(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // 预留包厢/工位
            const Text('预留包厢/工位：', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Builder(
              builder: (ctx) {
                final spaceProv = ctx.watch<SpaceProvider>();
                final spaces = spaceProv.spaces;
                if (spaces.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🚪 观澜阁 (VIP豪华包厢 · 云端默认)', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  );
                }
                return DropdownButtonFormField<SpaceModel>(
                  value: _selectedSpace ?? spaces.first,
                  isExpanded: true,
                  items: spaces.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text('${s.spaceCode} · ${s.spaceName} (${s.floorZone})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSpace = val);
                  },
                );
              },
            ),
            const SizedBox(height: 14),

            // 预约日期与时间
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await ChineseHolidayDatePicker.show(
                        context,
                        initialDate: _selectedDate,
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ChineseDateUtils.formatShortChineseDate(_selectedDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                        helpText: '选择到店时间',
                        cancelText: '取消',
                        confirmText: '确定',
                      );
                      if (picked != null) setState(() => _selectedTime = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 备注
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: '特殊偏好备注 (如力度适中、喝普洱茶、靠窗包间)',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 24),

            // 确认提交
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('确认保存预约工单'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

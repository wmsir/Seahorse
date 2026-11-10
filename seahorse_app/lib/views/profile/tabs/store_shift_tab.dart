import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/store_provider.dart';

class StoreShiftTab extends StatefulWidget {
  const StoreShiftTab({Key? key}) : super(key: key);

  @override
  State<StoreShiftTab> createState() => _StoreShiftTabState();
}

class _StoreShiftTabState extends State<StoreShiftTab> {
  final ApiClient _client = ApiClient();
  final TextEditingController _actualCashCtrl = TextEditingController(text: '0');
  final TextEditingController _notesCtrl = TextEditingController();

  String _selectedShift = 'DAY';
  bool _isSubmitting = false;
  bool _isLoadingRecords = false;
  double _todayRevenue = 0.0;
  int _todayOrders = 0;
  List<Map<String, dynamic>> _shiftRecords = [];
  Map<String, dynamic>? _lastSubmitResult;

  @override
  void initState() {
    super.initState();
    _loadShiftData();
  }

  @override
  void dispose() {
    _actualCashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShiftData() async {
    setState(() => _isLoadingRecords = true);
    try {
      final statsRes = await _client.dio.get('/dashboard/stats');
      if (statsRes.statusCode == 200 && statsRes.data != null) {
        final raw = statsRes.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map) {
          _todayRevenue = double.tryParse(data['todayRevenue']?.toString() ?? '0') ?? 0.0;
          _todayOrders = int.tryParse(data['todayOrderCount']?.toString() ?? data['completedOrderCount']?.toString() ?? '0') ?? 0;
        }
      }
    } catch (_) {}

    try {
      final recRes = await _client.dio.get('/shift/records');
      if (recRes.statusCode == 200 && recRes.data != null) {
        final raw = recRes.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          _shiftRecords = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoadingRecords = false);
    }
  }

  void _addDenomination(double value) {
    final current = double.tryParse(_actualCashCtrl.text.trim()) ?? 0.0;
    final nextVal = current + value;
    setState(() {
      _actualCashCtrl.text = nextVal.toStringAsFixed(nextVal == nextVal.roundToDouble() ? 0 : 2);
    });
  }

  Future<void> _submitBlindHandover(AuthProvider auth, StoreProvider store) async {
    final actualCash = double.tryParse(_actualCashCtrl.text.trim());
    if (actualCash == null || actualCash < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的钱箱实点现金金额'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final cashierName = auth.realName.isNotEmpty ? auth.realName : (auth.username.isNotEmpty ? auth.username : '前台收银');
      final response = await _client.dio.post('/shift/blind-submit', data: {
        'cashierName': cashierName,
        'actualCash': actualCash,
        'shiftType': _selectedShift,
        'storeId': store.currentStoreId,
        'notes': _notesCtrl.text.trim().isEmpty
            ? '${_selectedShift == "DAY" ? "早中班" : "晚班"}移动端盲盘交接'
            : _notesCtrl.text.trim(),
      });

      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map) {
          setState(() {
            _lastSubmitResult = Map<String, dynamic>.from(data);
          });
        }
      }

      await _loadShiftData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 盲盘交班已归档上云！系统已完成账实比对并同步至Web财务中心。'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('交班提交异常: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreProvider>();

    return RefreshIndicator(
      onRefresh: _loadShiftData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 班次切换与防舞弊盲盘说明
            Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('⚖️ 收银盲盘交班中心', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Text(
                                '当班收银: ${auth.realName.isNotEmpty ? auth.realName : "前台收银"} · ${store.currentStoreName}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: const Text('防舞弊盲交模式', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'DAY', label: Text('☀️ 早中班 (09:00-18:00)')),
                          ButtonSegment(value: 'NIGHT', label: Text('🌙 晚班 (18:00-打烊)')),
                        ],
                        selected: {_selectedShift},
                        onSelectionChanged: (set) => setState(() => _selectedShift = set.first),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 2. 本班实时营业概览
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    '今日已结营业额',
                    Formatters.currency(_todayRevenue),
                    Icons.payments_outlined,
                    AppColors.primary,
                    '已完成结算 $_todayOrders 笔',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    '系统应有现金',
                    _lastSubmitResult != null
                        ? Formatters.currency(double.tryParse(_lastSubmitResult!['systemExpectedCash']?.toString() ?? '0') ?? 0)
                        : '🔒 盲盘隐藏中',
                    Icons.lock_clock_outlined,
                    Colors.deepOrange,
                    _lastSubmitResult != null ? '已揭晓系统账面现金' : '提交实点现金后自动比对',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3. 盲盘实点现金清点器
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💵 第一步：清点钱箱实有现金', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      '请清点钱箱内实际纸币与硬币总额（不含备用金底数），直接输入或点击面额累加：',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _actualCashCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      decoration: InputDecoration(
                        labelText: '钱箱实点现金总额 (元)',
                        prefixText: '¥ ',
                        suffixIcon: TextButton(
                          onPressed: () => setState(() => _actualCashCtrl.text = '0'),
                          child: const Text('清零'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(label: const Text('+ ¥100'), onPressed: () => _addDenomination(100)),
                        ActionChip(label: const Text('+ ¥50'), onPressed: () => _addDenomination(50)),
                        ActionChip(label: const Text('+ ¥20'), onPressed: () => _addDenomination(20)),
                        ActionChip(label: const Text('+ ¥10'), onPressed: () => _addDenomination(10)),
                        ActionChip(label: const Text('+ ¥5'), onPressed: () => _addDenomination(5)),
                        ActionChip(label: const Text('+ ¥1'), onPressed: () => _addDenomination(1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: '交班备注说明 (选填)',
                        hintText: '例如：零钱找零已补齐、VIP客遗留雨伞已存前台等',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. 若刚完成盲盘提交，展示比对结果卡片
            if (_lastSubmitResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎉 本次盲盘交班对账结果', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('实点上缴: ¥${_lastSubmitResult!['actualReportedCash'] ?? _actualCashCtrl.text}'),
                        Text('系统应有: ¥${_lastSubmitResult!['systemExpectedCash'] ?? 0}'),
                        Text(
                          '差额: ¥${_lastSubmitResult!['varianceAmount'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 5. 确认盲盘交班按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.verified_outlined, color: Colors.white),
                label: Text(
                  _isSubmitting ? '正在加密归档交班记录...' : '确认盲盘交班 · 归档同步至云端',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : () => _submitBlindHandover(auth, store),
              ),
            ),

            const SizedBox(height: 20),

            // 6. 历史交班归档流水列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📋 近期交班盲盘归档记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _loadShiftData,
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text('刷新', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            if (_isLoadingRecords)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_shiftRecords.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('暂无历史交班记录，完成上方盲盘提交后将自动归档展示', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              )
            else
              ..._shiftRecords.take(8).map((rec) {
                final variance = double.tryParse(rec['varianceAmount']?.toString() ?? '0') ?? 0.0;
                final isMatched = variance.abs() < 0.01;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: isMatched ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.15),
                      child: Icon(
                        isMatched ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                        color: isMatched ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      '收银员: ${rec['cashierName'] ?? '前台'} · 实点 ¥${rec['actualReportedCash'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      '系统应有: ¥${rec['systemExpectedCash'] ?? 0} · 差额: ¥${variance.toStringAsFixed(2)}\n${rec['shiftEndTime'] ?? rec['createTime'] ?? ''}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isMatched ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isMatched ? '平账' : (variance > 0 ? '长款' : '短款'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMatched ? const Color(0xFF166534) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

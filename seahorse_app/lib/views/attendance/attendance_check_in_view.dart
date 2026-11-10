import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../leave/leave_management_view.dart';

class AttendanceCheckInView extends StatefulWidget {
  final bool isEmbedded;

  const AttendanceCheckInView({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<AttendanceCheckInView> createState() => _AttendanceCheckInViewState();
}

class _AttendanceCheckInViewState extends State<AttendanceCheckInView> {
  final LocationService _locationService = LocationService();
  final AttendanceService _attendanceService = AttendanceService();

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  LocationPoint? _currentLocation;
  double _distanceMeters = 35.0;
  bool _isLocating = true;
  bool _isSubmitting = false;

  AttendanceRecordModel? _todayRecord;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
    _initData();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    await _refreshLocation();
    await _loadTodayAttendance();
  }

  bool _isManager(AuthProvider auth) {
    final role = auth.role.toUpperCase();
    final username = auth.username.toLowerCase();
    return role == 'STORE_MANAGER' ||
        role == 'SUPER_ADMIN' ||
        role.contains('MANAGER') ||
        role.contains('ADMIN') ||
        username.contains('admin') ||
        username.contains('manager') ||
        username.contains('boss') ||
        auth.realName.contains('店长');
  }

  Future<void> _refreshLocation({bool forceRefresh = false}) async {
    setState(() => _isLocating = true);
    try {
      final loc = await _locationService.getCurrentLocation(forceRefresh: forceRefresh);
      final dist = _locationService.calculateDistanceMeters(
        loc.latitude,
        loc.longitude,
        _locationService.storeLatitude,
        _locationService.storeLongitude,
      );
      if (mounted) {
        setState(() {
          _currentLocation = loc;
          _distanceMeters = dist;
          _isLocating = false;
        });
        if (forceRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ 已成功重新探测物理硬件 GPS 坐标（无旧缓存）！'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS获取提示: $e'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadTodayAttendance() async {
    final auth = context.read<AuthProvider>();
    final record = await _attendanceService.getMyTodayRecord(
      phone: auth.username,
      staffName: auth.realName,
    );
    if (mounted) {
      setState(() => _todayRecord = record);
    }
  }

  bool get _isWithinFence => _locationService.isWithinAllowedRadius(_distanceMeters);

  void _showSimulationDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('🎯 定位来源模式切换', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('默认使用手机真实物理 GPS 定位，也可切换模拟场景：', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 14),
              ...LocationSourceMode.values.map((mode) {
                final isSelected = _locationService.sourceMode == mode;
                return ListTile(
                  leading: Icon(
                    mode == LocationSourceMode.realDevice ? Icons.satellite_alt : Icons.location_city,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  title: Text(mode.label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _locationService.setSourceMode(mode);
                    _refreshLocation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已切换定位来源为: ${mode.label}'), duration: const Duration(seconds: 1)),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _setStoreToCurrentLocation() {
    if (_currentLocation == null) return;
    _locationService.setStoreLocation(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _currentLocation!.address,
      name: '海马智慧商业 (当前打卡点/西安店)',
      radius: 500.0,
    );
    _refreshLocation();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 已将当前真实物理位置设为考勤打卡基准门店 (有效半径500米)！'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetStoreLocation() {
    _locationService.resetDefaultStoreLocation();
    _refreshLocation();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已恢复为默认考勤基准门店 (成都总店天府大道)'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleCheckInAction() async {
    if (_isSubmitting) return;

    final auth = context.read<AuthProvider>();
    final isWithin = _isWithinFence;
    final isCheckedIn = _todayRecord != null && _todayRecord!.isCheckedIn;

    if (!isWithin) {
      // 超出范围：弹出外勤事由录入对话框
      _showFieldWorkDialog(auth);
      return;
    }

    final type = isCheckedIn ? 'CHECK_OUT' : 'CHECK_IN';
    await _executeSubmit(
      type: type,
      notes: isCheckedIn ? '正常下班打卡' : '正常上班打卡',
    );
  }

  void _showFieldWorkDialog(AuthProvider auth) {
    final noteCtrl = TextEditingController(text: '拜访连锁意向客户/上门推拿SPA服务');
    final isCheckedIn = _todayRecord != null && _todayRecord!.isCheckedIn;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.directions_car_outlined, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(isCheckedIn ? '外勤下班打卡报备' : '外勤上班打卡报备', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '当前距离门店 ${_locationService.formatDistance(_distanceMeters)}，超出范围需录入外勤事由并附注定位。',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: '外勤工作事由 *',
                  hintText: '例如: 顾客定制专属上门理疗服务',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final note = noteCtrl.text.trim();
                if (note.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请录入外勤工作事由')));
                  return;
                }
                Navigator.pop(ctx);
                await _executeSubmit(
                  type: 'FIELD_WORK',
                  notes: note,
                );
              },
              child: const Text('确认外勤打卡', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeSubmit({required String type, required String notes}) async {
    final auth = context.read<AuthProvider>();
    setState(() => _isSubmitting = true);

    final loc = _currentLocation ?? await _locationService.getCurrentLocation();
    final record = await _attendanceService.submitCheckIn(
      staffName: auth.realName.isNotEmpty ? auth.realName : auth.username,
      phone: auth.username,
      postName: auth.role == 'STORE_MANAGER' ? '总店长' : '高级技师',
      type: type,
      latitude: loc.latitude,
      longitude: loc.longitude,
      locationName: loc.address,
      distanceMeters: _distanceMeters,
      notes: notes,
    );

    if (mounted) {
      setState(() {
        _todayRecord = record;
        _isSubmitting = false;
      });
      final actionLabel = type == 'CHECK_OUT' ? '下班打卡' : (type == 'FIELD_WORK' ? '外勤打卡' : '上班打卡');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 $actionLabel 成功！已记录至考勤流水'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isManager = _isManager(auth);
    final isWithin = _isWithinFence;
    final isCheckedIn = _todayRecord != null && _todayRecord!.isCheckedIn;
    final isCheckedOut = _todayRecord != null && _todayRecord!.isCheckedOut;
    final isRealMode = _locationService.sourceMode == LocationSourceMode.realDevice;
    final isCalibrated = _locationService.storeLatitude != 30.572800;

    // 时间格式化
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    final dateStr = DateFormat('yyyy年M月d日 EEEE', 'zh_CN').format(_currentTime);

    // 打卡主按钮文本与配色
    String btnTitle;
    String btnSub;
    LinearGradient btnGradient;
    Color pulseColor;

    if (!isCheckedIn) {
      if (isWithin) {
        btnTitle = '上班打卡';
        btnSub = timeStr;
        btnGradient = const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight);
        pulseColor = const Color(0xFFF59E0B);
      } else {
        btnTitle = '外勤打卡';
        btnSub = timeStr;
        btnGradient = const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFF97316)], begin: Alignment.topLeft, end: Alignment.bottomRight);
        pulseColor = const Color(0xFFEA580C);
      }
    } else if (!isCheckedOut) {
      if (isWithin) {
        btnTitle = '下班打卡';
        btnSub = timeStr;
        btnGradient = const LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF38BDF8)], begin: Alignment.topLeft, end: Alignment.bottomRight);
        pulseColor = const Color(0xFF0284C7);
      } else {
        btnTitle = '外勤下班';
        btnSub = timeStr;
        btnGradient = const LinearGradient(colors: [Color(0xFF475569), Color(0xFF64748B)], begin: Alignment.topLeft, end: Alignment.bottomRight);
        pulseColor = const Color(0xFF475569);
      }
    } else {
      btnTitle = '今日已完工';
      btnSub = '更新下班时间';
      btnGradient = const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      pulseColor = const Color(0xFF10B981);
    }

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('考勤定位打卡'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.beach_access_outlined, color: AppColors.primary),
                  tooltip: '请假申请与审批',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeaveManagementView()),
                  ),
                ),
                if (isManager)
                  IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.primary),
                    tooltip: '定位模式切换 (管理专享)',
                    onPressed: _showSimulationDialog,
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  tooltip: '重新探测实时GPS',
                  onPressed: () => _refreshLocation(forceRefresh: true),
                ),
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // 定位模式与状态提示横幅
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isRealMode ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isRealMode ? const Color(0xFFBFDBFE) : const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Icon(
                    isRealMode ? Icons.satellite_alt : Icons.science_outlined,
                    size: 16,
                    color: isRealMode ? AppColors.info : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRealMode
                          ? '已接入真实设备硬件 GPS 定位 (实时探测物理坐标)'
                          : '当前处于场景模拟模式 (${_locationService.sourceMode.label})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isRealMode ? const Color(0xFF1D4ED8) : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showSimulationDialog,
                    child: Text(
                      '切换模式',
                      style: TextStyle(fontSize: 11, color: isRealMode ? AppColors.info : AppColors.warning, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // 卫星/基站超时提示
            if (_locationService.satelliteTimeoutPrompt != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.satellite_alt_outlined, size: 20, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationService.satelliteTimeoutPrompt!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _refreshLocation,
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('重新探测', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                    ),
                  ],
                ),
              ),
            ],

            // 高德地图 API 错误提示（如Key未配置或失效）
            if (_locationService.amapError != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined, size: 20, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationService.amapError!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), height: 1.3, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 硬件定位异常提示卡片（如未开启GPS开关）
            if (_locationService.lastError != null && _locationService.satelliteTimeoutPrompt == null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 20, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationService.lastError!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), height: 1.3),
                      ),
                    ),
                    TextButton(
                      onPressed: _refreshLocation,
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('重试', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            // 1. 实时时钟看板
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
              ),
              child: Column(
                children: [
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                        child: const Text('工作日', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. 当前定位与围栏状态卡片
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isWithin ? Colors.green.withOpacity(0.12) : Colors.amber.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isWithin ? Icons.location_on : Icons.location_off,
                            color: isWithin ? Colors.green : Colors.amber.shade800,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _locationService.storeName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('(半径500m)', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isLocating
                                    ? '正在通过手机 GPS 卫星/基站探测当前物理位置...'
                                    : (_currentLocation?.address ?? '正在获取位置信息...'),
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _refreshLocation(forceRefresh: true),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: Row(
                            children: [
                              _isLocating
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                                  : const Icon(Icons.refresh, size: 14),
                              const SizedBox(width: 3),
                              Text(_isLocating ? '探测中' : '重新获取', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: isWithin ? Colors.green : Colors.amber.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isWithin
                                  ? '已在有效考勤范围内 (偏差 ${_locationService.formatDistance(_distanceMeters)})'
                                  : '超出考勤范围 (偏差 ${_locationService.formatDistance(_distanceMeters)} > 500米)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isWithin ? Colors.green.shade800 : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isWithin ? Colors.green.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isWithin ? '正常打卡' : '支持外勤打卡',
                            style: TextStyle(
                              fontSize: 10,
                              color: isWithin ? Colors.green.shade800 : Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 仅店长/管理员允许修改考勤基准点经纬度；收银员与普通员工严格隐藏
                    if (isManager && !isWithin && _currentLocation != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_location_alt_outlined, size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '在异地测试？可将当前真实物理位置(如西安)一键设为考勤门店点',
                                style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _setStoreToCurrentLocation,
                              child: const Text('设为考勤店', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (isManager && isCalibrated) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.restore, size: 14),
                            label: const Text('恢复默认成都总店基准', style: TextStyle(fontSize: 11)),
                            onPressed: _resetStoreLocation,
                          ),
                        ],
                      ),
                    ],

                    if (!isManager) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '考勤打卡基准点由店长统一维护；收银员仅允许查看本人考勤打卡流水',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. 打卡动效大按钮
            Center(
              child: GestureDetector(
                onTap: _isSubmitting ? null : _handleCheckInAction,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: btnGradient,
                    boxShadow: [
                      BoxShadow(
                        color: pulseColor.withOpacity(0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                !isCheckedIn
                                    ? (isWithin ? Icons.wb_sunny_outlined : Icons.directions_car_outlined)
                                    : (isCheckedOut ? Icons.verified : Icons.nightlight_outlined),
                                color: Colors.white,
                                size: 38,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                btnTitle,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                btnSub,
                                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3.5 常用人事打卡与休假：员工请假申请与审批
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.beach_access, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '员工请假申请与审批流',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isManager ? '支持事假/病假/年假/调休在线提交与移动端一键审批' : '支持在线发起请假、撤回编辑与审批时间线跟踪',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaveManagementView()),
                      );
                    },
                    child: Text(
                      isManager ? '请假/审批' : '我要请假',
                      style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // 4. 今日打卡时间轴流水
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('📋 今日打卡考勤时间轴', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('正常班次 09:00 - 21:00', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 上班卡
                    _buildTimelineRow(
                      icon: Icons.wb_sunny,
                      iconColor: Colors.amber,
                      title: '上班打卡',
                      time: _todayRecord?.checkInTime ?? '--:--',
                      status: _todayRecord?.checkInStatus == 'FIELD_WORK'
                          ? '外勤打卡'
                          : (_todayRecord?.checkInTime != null ? '正常打卡' : '待打卡'),
                      statusColor: _todayRecord?.checkInStatus == 'FIELD_WORK'
                          ? Colors.orange
                          : (_todayRecord?.checkInTime != null ? Colors.green : Colors.grey),
                      location: _todayRecord?.checkInLocation ?? '在考勤范围内完成打卡',
                      notes: _todayRecord?.notes,
                    ),

                    const Padding(
                      padding: EdgeInsets.only(left: 17),
                      child: SizedBox(height: 22, child: VerticalDivider(thickness: 1.5, color: Color(0xFFE2E8F0))),
                    ),

                    // 下班卡
                    _buildTimelineRow(
                      icon: Icons.nightlight,
                      iconColor: Colors.blue,
                      title: '下班打卡',
                      time: _todayRecord?.checkOutTime ?? '--:--',
                      status: _todayRecord?.checkOutTime != null ? '正常打卡' : (isCheckedIn ? '待下班打卡' : '未开始'),
                      statusColor: _todayRecord?.checkOutTime != null ? Colors.green : Colors.grey,
                      location: _todayRecord?.checkOutTime != null
                          ? '工时统计约 ${_todayRecord?.workHours ?? 8.5} 小时'
                          : '下班前请复查工位复位',
                      notes: null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 5. 本月考勤汇总
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildSummaryItem('本月出勤', '22 天', AppColors.primary)),
                  Expanded(child: _buildSummaryItem('全勤天数', '21 天', Colors.green)),
                  Expanded(child: _buildSummaryItem('外勤出差', '1 次', Colors.orange)),
                  Expanded(child: _buildSummaryItem('迟到/早退', '0 次', Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required String status,
    required Color statusColor,
    required String location,
    String? notes,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 17, backgroundColor: iconColor.withOpacity(0.15), child: Icon(icon, color: iconColor, size: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '打卡时间: $time',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(location, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              if (notes != null && notes.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('备注: $notes', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/constants.dart';

enum ScanPurpose {
  payment,      // 扫顾客付款码收款 (微信/支付宝)
  inventory,    // 扫商品条形码入库 / 盘点
  cashierAdd,   // 扫商品条形码快捷点单加车
  memberLookup, // 扫会员二维码核销建档
}

class CameraScannerView extends StatefulWidget {
  final ScanPurpose purpose;
  final String? title;
  final double? orderAmount;

  const CameraScannerView({
    Key? key,
    this.purpose = ScanPurpose.payment,
    this.title,
    this.orderAmount,
  }) : super(key: key);

  @override
  State<CameraScannerView> createState() => _CameraScannerViewState();
}

class _CameraScannerViewState extends State<CameraScannerView> with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  late ScanPurpose _currentPurpose;

  @override
  void initState() {
    super.initState();
    _currentPurpose = widget.purpose;
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    _handleCodeScanned(code.trim());
  }

  static const MethodChannel _soundChannel = MethodChannel('com.seahorse.app/scanner_sound');

  void _playScanSound() async {
    try {
      await _soundChannel.invokeMethod('playScanSuccessSound');
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void _handleCodeScanned(String rawCode) async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    _playScanSound();

    // 暂停相机扫描
    await _scannerController.stop();

    if (!mounted) return;

    _showScanResultSheet(rawCode);
  }

  void _showScanResultSheet(String rawCode) {
    String scanType = '通用条码 / 二维码';
    String cleanValue = rawCode;
    Color typeColor = Colors.purple;
    IconData typeIcon = Icons.qr_code;
    String tipText = '已成功识别条码内容';
    String? paymentType;

    if (_currentPurpose == ScanPurpose.memberLookup ||
        rawCode.startsWith('SEAHORSE:MEMBER:') ||
        RegExp(r'^1[3-9]\d{9}$').hasMatch(rawCode) ||
        RegExp(r'^(M|VIP|CARD)\d+', caseSensitive: false).hasMatch(rawCode)) {
      scanType = '顾客专属会员码';
      if (rawCode.startsWith('SEAHORSE:MEMBER:')) {
        cleanValue = rawCode.replaceFirst('SEAHORSE:MEMBER:', '');
      }
      typeColor = const Color(0xFF0D9488);
      typeIcon = Icons.card_membership;
      tipText = '会员专属身份凭证 · 可快速检索顾客档案或扣卡消费';
    } else if (RegExp(r'^(10|11|12|13|14|15)\d{16}$').hasMatch(rawCode) || rawCode.startsWith('wxp://')) {
      scanType = '微信支付付款码';
      paymentType = 'wechat';
      typeColor = const Color(0xFF07C160);
      typeIcon = Icons.chat_bubble_outline;
      tipText = '18位微信付款条码 · 点击确认即可发起自动反扫结算';
    } else if (RegExp(r'^(25|26|27|28|29|30)\d{14,22}$').hasMatch(rawCode) || rawCode.toLowerCase().contains('alipay')) {
      scanType = '支付宝付款码';
      paymentType = 'alipay';
      typeColor = const Color(0xFF1677FF);
      typeIcon = Icons.account_balance_wallet_outlined;
      tipText = '支付宝付款条码 · 点击确认即可发起自动反扫结算';
    } else if (rawCode.startsWith('69') && rawCode.length == 13) {
      scanType = '国际国标 69 商品条码';
      typeColor = Colors.orange.shade700;
      typeIcon = Icons.shopping_bag_outlined;
      tipText = '中国大陆商品条码 (EAN-13) · 适用于零售加购或商品盘点';
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部状态栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎯 扫描识别成功',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          scanType,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    Navigator.pop(sheetCtx);
                    setState(() => _isProcessing = false);
                    _scannerController.start();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 识别内容详情卡
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('识别到的码值内容：', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: cleanValue));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已复制扫描内容到剪贴板'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.copy, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('复制', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    cleanValue,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (cleanValue != rawCode) ...[
                    const SizedBox(height: 4),
                    Text(
                      '原始码: $rawCode',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    tipText,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 底部操作区
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('重新扫描'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      setState(() => _isProcessing = false);
                      _scannerController.start();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('确认识别并使用', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.of(context).pop({
                        'success': true,
                        'code': cleanValue,
                        'rawCode': rawCode,
                        'barcode': cleanValue,
                        'paymentType': paymentType,
                        'scanType': scanType,
                        'purpose': _currentPurpose,
                        'isMemberCode': _currentPurpose == ScanPurpose.memberLookup || scanType == '顾客专属会员码',
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('手动输入条形码 / 付款码'),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: '请输入18位付款码或商品条码',
            prefixIcon: Icon(Icons.qr_code),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                _handleCodeScanned(val);
              }
            },
            child: const Text('确定识别'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPay = _currentPurpose == ScanPurpose.payment;
    final titleText = widget.title ?? (isPay ? '移动扫码盒子 · 扫码收款' : '智能扫码入库 / 盘点');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 真实摄像头扫码预览
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off, size: 48, color: Colors.white70),
                      const SizedBox(height: 12),
                      const Text(
                        '未检测到物理摄像头或无相机权限',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '您可以使用下方的“手动输入条形码”模式进行入库和收款测试',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.keyboard),
                        label: const Text('手动键盘输入'),
                        onPressed: _showManualInputDialog,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. 扫码盒子准星 HUD
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.black45,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isPay && widget.orderAmount != null
                                  ? '待收金额: ￥${widget.orderAmount!.toStringAsFixed(2)} 元'
                                  : '支持商品包装条码 / 微信支付宝付款码 / 电子会员码',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: _isTorchOn ? Colors.amber : Colors.white),
                        tooltip: '开关闪光补光灯',
                        onPressed: () {
                          _scannerController.toggleTorch();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                        tooltip: '切换前后镜头',
                        onPressed: () => _scannerController.switchCamera(),
                      ),
                    ],
                  ),
                ),

                // 扫码模式快速切换药丸
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeChip('💳 扫付款码', ScanPurpose.payment),
                      _buildModeChip('📦 扫码入库', ScanPurpose.inventory),
                      _buildModeChip('🛒 扫码点单', ScanPurpose.cashierAdd),
                      _buildModeChip('👤 会员码', ScanPurpose.memberLookup),
                    ],
                  ),
                ),

                // 扫码瞄准取景框
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        children: [
                          // 4 个边角瞄准线
                          CustomPaint(
                            size: const Size(280, 280),
                            painter: _ScannerBoxPainter(),
                          ),
                          // 激光上下扫描线
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (ctx, child) {
                              return Positioned(
                                top: 280 * _laserAnimation.value,
                                left: 15,
                                right: 15,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        isPay ? Colors.greenAccent : AppColors.primaryLight,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isPay ? Colors.greenAccent : AppColors.primary,
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // 状态提示文字
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getInstructionText(),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 底部手动输入条码按钮
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white60),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text('手动键盘输入条形码 / 付款码'),
                    onPressed: _showManualInputDialog,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, ScanPurpose purpose) {
    final isSelected = _currentPurpose == purpose;
    return GestureDetector(
      onTap: () => setState(() => _currentPurpose = purpose),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    switch (_currentPurpose) {
      case ScanPurpose.payment:
        return '请将取景框对准顾客微信/支付宝付款码';
      case ScanPurpose.inventory:
        return '请将取景框对准商品条形码 (EAN/UPC)';
      case ScanPurpose.cashierAdd:
        return '请将取景框对准待点单商品的条形码';
      case ScanPurpose.memberLookup:
        return '请将取景框对准顾客微信会员卡二维码';
    }
  }
}

class _ScannerBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 26.0;

    // 左上角
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // 右上角
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // 左下角
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // 右下角
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

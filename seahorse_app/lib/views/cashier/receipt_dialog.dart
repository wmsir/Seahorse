import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/order_model.dart';

class ReceiptDialog extends StatelessWidget {
  final OrderModel order;
  final String storeName;

  const ReceiptDialog({Key? key, required this.order, required this.storeName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 小票头部
              const Icon(Icons.receipt_long, color: AppColors.primary, size: 36),
              const SizedBox(height: 8),
              Text(
                storeName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('结账收款凭条', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Divider(height: 20),

              // 基础信息
              _buildRow('订单编号：', order.orderNo),
              _buildRow('开单时间：', Formatters.dateTime(order.createTime)),
              if (order.spaceName != null) _buildRow('消费包厢：', order.spaceName!),
              if (order.customerName != null) _buildRow('就诊顾客：', '${order.customerName} (${Formatters.maskPhone(order.customerPhone)})'),
              _buildRow('结算通道：', order.paymentMethod.label),
              const Divider(height: 20),

              // 消费项目明细
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('消费项目与商品明细：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              ...order.items.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${i.title} x${i.quantity}', style: const TextStyle(fontSize: 12))),
                    Text(Formatters.currency(i.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
              const Divider(height: 20),

              // 金额汇总
              _buildRow('消费原价合计：', Formatters.currency(order.totalAmount)),
              if (order.discountAmount > 0)
                _buildRow('会员专属折扣优惠：', '-${Formatters.currency(order.discountAmount)}', valueColor: AppColors.error),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('实收金额：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    Formatters.currency(order.payableAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 尾部提示
              const Text(
                '海马店务 · 感谢您的光临与惠顾\n欢迎再次体验高品质门店服务',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成并返回'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

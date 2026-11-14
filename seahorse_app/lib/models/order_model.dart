import '../core/constants/constants.dart';

class OrderLineItem {
  final int id;
  final String title;
  final double price;
  int quantity;
  final String? technicianName;
  final String type; // SERVICE, RETAIL, FEE

  OrderLineItem({
    required this.id,
    required this.title,
    required this.price,
    this.quantity = 1,
    this.technicianName,
    this.type = 'SERVICE',
  });

  double get subtotal => price * quantity;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      technicianName: json['technicianName'],
      type: json['type'] ?? 'SERVICE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'quantity': quantity,
      'technicianName': technicianName,
      'type': type,
    };
  }
}

class OrderModel {
  final String orderNo;
  final String storeId;
  final String? spaceCode;
  final String? spaceName;
  final String? customerName;
  final String? customerPhone;
  final List<OrderLineItem> items;
  final double totalAmount;
  final double discountAmount;
  final double payableAmount;
  final PaymentMethod paymentMethod;
  final String status; // UNPAID, PAID, REFUNDED
  final DateTime createTime;
  final DateTime? payTime;

  OrderModel({
    required this.orderNo,
    required this.storeId,
    this.spaceCode,
    this.spaceName,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.totalAmount,
    this.discountAmount = 0.0,
    required this.payableAmount,
    this.paymentMethod = PaymentMethod.wechat,
    this.status = 'PAID',
    required this.createTime,
    this.payTime,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsJson = json['items'] as List? ?? [];
    List<OrderLineItem> parsedItems = itemsJson.map((e) => OrderLineItem.fromJson(e)).toList();

    final rawCreateTime = (json['createTime'] ?? json['createdAt'] ?? '').toString();
    final rawPayTime = json['payTime'] ?? json['settledAt'];
    final rawPayable = json['payableAmount'] ?? json['actualAmount'] ?? json['paidAmount'] ?? json['totalAmount'] ?? 0;

    return OrderModel(
      orderNo: json['orderNo'] ?? '',
      storeId: json['storeId'] ?? '',
      spaceCode: json['spaceCode'],
      spaceName: json['spaceName'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      items: parsedItems,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      payableAmount: (rawPayable is num) ? rawPayable.toDouble() : (double.tryParse(rawPayable.toString()) ?? 0.0),
      paymentMethod: PaymentMethod.fromCode(
        (json['paymentMethod'] ?? json['payChannel'] ?? json['channel'])?.toString(),
      ),
      status: json['status']?.toString() ?? 'PAID',
      createTime: DateTime.tryParse(rawCreateTime) ?? DateTime.now(),
      payTime: rawPayTime != null ? DateTime.tryParse(rawPayTime.toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderNo': orderNo,
      'storeId': storeId,
      'spaceCode': spaceCode,
      'spaceName': spaceName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'payableAmount': payableAmount,
      'paymentMethod': paymentMethod.code,
      'status': status,
      'createTime': createTime.toIso8601String(),
      'payTime': payTime?.toIso8601String(),
    };
  }
}

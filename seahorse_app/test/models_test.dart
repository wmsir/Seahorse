import 'package:flutter_test/flutter_test.dart';
import 'package:seahorse_app/core/constants/constants.dart';
import 'package:seahorse_app/models/appointment_model.dart';
import 'package:seahorse_app/models/attendance_model.dart';
import 'package:seahorse_app/models/dashboard_stats_model.dart';
import 'package:seahorse_app/models/member_model.dart';
import 'package:seahorse_app/models/order_model.dart';
import 'package:seahorse_app/models/product_model.dart';
import 'package:seahorse_app/models/space_model.dart';

void main() {
  group('1. ProductModel Tests', () {
    test('ProductModel.fromJson should parse standard JSON correctly', () {
      final json = {
        'id': 101,
        'productCode': '690123456789',
        'name': '特级大红袍',
        'categoryName': '茶饮茗品',
        'price': 68.0,
        'costPrice': 20.0,
        'durationMinutes': 45,
        'productType': 'PHYSICAL',
        'description': '醇厚甘甜',
        'stock': 50,
        'unit': '壶',
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 101);
      expect(product.productCode, '690123456789');
      expect(product.title, '特级大红袍');
      expect(product.category, '茶饮茗品');
      expect(product.price, 68.0);
      expect(product.cost, 20.0);
      expect(product.stock, 50);
      expect(product.unit, '壶');
      expect(product.isPhysical, isTrue);
      expect(product.isService, isFalse);
    });

    test('ProductModel fallback handling for legacy or missing keys', () {
      final legacyJson = {
        'title': '精油肩颈SPA',
        'type': 'SERVICE',
        'price': 198,
        'cost': 30,
      };

      final product = ProductModel.fromJson(legacyJson);

      expect(product.id, 0);
      expect(product.productCode, '');
      expect(product.title, '精油肩颈SPA');
      expect(product.category, '通用商品');
      expect(product.price, 198.0);
      expect(product.cost, 30.0);
      expect(product.stock, 999);
      expect(product.isService, isTrue);
    });

    test('ProductModel.toJson should output correct map for backend syncing', () {
      final product = ProductModel(
        id: 202,
        productCode: '69888888',
        title: '冷泡乌龙茶',
        category: '酒水饮料',
        price: 25.0,
        cost: 8.0,
        type: 'PHYSICAL',
        stock: 30,
        unit: '瓶',
      );

      final json = product.toJson();

      expect(json['id'], 202);
      expect(json['productCode'], '69888888');
      expect(json['name'], '冷泡乌龙茶');
      expect(json['categoryName'], '酒水饮料');
      expect(json['price'], 25.0);
      expect(json['costPrice'], 8.0);
      expect(json['productType'], 'PHYSICAL');
      expect(json['available'], isTrue);
    });
  });

  group('2. OrderModel & OrderLineItem Tests', () {
    test('OrderLineItem calculates subtotal accurately', () {
      final item = OrderLineItem(
        id: 1,
        title: '养生足道60分钟',
        price: 128.0,
        quantity: 2,
        type: 'SERVICE',
      );

      expect(item.subtotal, 256.0);

      item.quantity = 3;
      expect(item.subtotal, 384.0);
    });

    test('OrderModel.fromJson parses order details correctly', () {
      final json = {
        'orderNo': 'ORD20260914001',
        'storeId': 'S001',
        'customerName': '张先生',
        'customerPhone': '13800138000',
        'totalAmount': 200.0,
        'discountAmount': 20.0,
        'payableAmount': 180.0,
        'paymentMethod': 'WECHAT',
        'status': 'PAID',
        'createTime': '2026-09-14 15:30:00',
        'items': [
          {'id': 1, 'title': '服务A', 'price': 100.0, 'quantity': 2, 'type': 'SERVICE'}
        ],
      };

      final order = OrderModel.fromJson(json);

      expect(order.orderNo, 'ORD20260914001');
      expect(order.customerName, '张先生');
      expect(order.totalAmount, 200.0);
      expect(order.payableAmount, 180.0);
      expect(order.paymentMethod, PaymentMethod.wechat);
      expect(order.status, 'PAID');
      expect(order.items.length, 1);
    });

    test('OrderModel.fromJson maps backend BillingOrder keys and IndustryType codes', () {
      final backendOrderJson = {
        'orderNo': 'BO20260915009',
        'storeId': 'S001',
        'totalAmount': 300.0,
        'discountAmount': 45.0,
        'actualAmount': 255.0,
        'payChannel': 'STORED_VALUE',
        'status': 'PAID',
        'createdAt': '2026-09-15T18:20:00',
        'settledAt': '2026-09-15T18:21:05',
      };

      final order = OrderModel.fromJson(backendOrderJson);
      expect(order.payableAmount, 255.0);
      expect(order.paymentMethod, PaymentMethod.memberCard);
      expect(order.createTime, DateTime.parse('2026-09-15T18:20:00'));
      expect(order.payTime, DateTime.parse('2026-09-15T18:21:05'));

      expect(IndustryType.fromCode('TEA_HOUSE'), IndustryType.teaHouse);
      expect(IndustryType.fromCode('PET'), IndustryType.pet);
      expect(IndustryType.fromCode('DINING'), IndustryType.restaurant);
      expect(IndustryType.fromCode('AUTO_SERVICE'), IndustryType.auto);
    });
  });

  group('3. SpaceModel Tests', () {
    test('SpaceModel calculates servedMinutes and parses correctly', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 75));
      final space = SpaceModel(
        id: 1,
        storeId: 'S001',
        spaceCode: 'VIP-888',
        spaceName: '天权尊荣包厢',
        status: SpaceStatus.occupied,
        serviceStartTime: startTime,
        currentBillAmount: 388.0,
        hourlyFee: 120.0,
      );

      expect(space.servedMinutes, greaterThanOrEqualTo(74));
      expect(space.servedMinutes, lessThanOrEqualTo(76));
      expect(space.status, SpaceStatus.occupied);
      expect(space.currentBillAmount, 388.0);
    });
  });

  group('4. AppointmentModel Tests', () {
    test('AppointmentModel status mapping and serialization', () {
      final json = {
        'id': 50,
        'aptNo': 'APT1001',
        'storeId': 'S001',
        'customerName': '李女士',
        'phone': '13912345678',
        'serviceName': '泰式芳香精油SPA',
        'servicePrice': 298.0,
        'aptDate': '2026-09-15',
        'aptTime': '14:00',
        'status': 'SERVING',
        'staffName': '8号技师(王琳)',
      };

      final apt = AppointmentModel.fromJson(json);

      expect(apt.id, 50);
      expect(apt.customerName, '李女士');
      expect(apt.servicePrice, 298.0);
      expect(apt.status, AppointmentStatus.serving);
      expect(apt.staffName, '8号技师(王琳)');
    });
  });

  group('5. MemberModel & AttendanceRecordModel Tests', () {
    test('MemberModel handles balance, phone and VIP levelName', () {
      final json = {
        'id': 1,
        'memberNo': 'VIP8888',
        'name': '陈总',
        'phone': '18888888888',
        'levelName': '黑金至尊VIP',
        'discountRate': 0.85,
        'balance': 5800.0,
        'points': 1200,
      };

      final member = MemberModel.fromJson(json);

      expect(member.name, '陈总');
      expect(member.phone, '18888888888');
      expect(member.balance, 5800.0);
      expect(member.points, 1200);
      expect(member.levelName, '黑金至尊VIP');
      expect(member.discountRate, 0.85);
    });

    test('AttendanceRecordModel parses and formats punch records', () {
      final json = {
        'id': 'ATT-20260914-01',
        'staffName': '王强',
        'phone': '13900001111',
        'postName': '金牌技师',
        'workDate': '2026-09-14',
        'checkInTime': '08:55:12',
        'checkInStatus': 'NORMAL',
        'checkInLocation': '陕西省西安市高新区高新路海马商业中心1号店',
        'platformSource': 'APP_MOBILE',
      };

      final att = AttendanceRecordModel.fromJson(json);

      expect(att.id, 'ATT-20260914-01');
      expect(att.staffName, '王强');
      expect(att.checkInStatus, 'NORMAL');
      expect(att.platformSource, 'APP_MOBILE');
    });

    test('DashboardStatsModel parses dashboard summaries', () {
      final json = {
        'todayRevenue': 15880.0,
        'todayOrderCount': 42,
        'totalSpaces': 12,
        'occupiedSpaces': 9,
        'spaceUtilizationRate': 0.75,
        'activeSessions': 9,
        'totalMembers': 128,
        'todayCommissions': 2560.0,
      };

      final stats = DashboardStatsModel.fromJson(json);

      expect(stats.todayRevenue, 15880.0);
      expect(stats.todayOrderCount, 42);
      expect(stats.spaceUtilizationRate, 0.75);
      expect(stats.occupiedSpaces, 9);
      expect(stats.totalMembers, 128);
    });
  });
}

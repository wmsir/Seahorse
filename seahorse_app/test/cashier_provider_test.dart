import 'package:flutter_test/flutter_test.dart';
import 'package:seahorse_app/models/product_model.dart';
import 'package:seahorse_app/providers/cashier_provider.dart';

void main() {
  group('CashierProvider Automated Feature Tests', () {
    late CashierProvider provider;

    setUp(() {
      provider = CashierProvider();
    });

    test('1. Adding newly entered product updates product list immediately', () {
      final initialCount = provider.products.length;

      final newProduct = ProductModel(
        id: 9999,
        productCode: '699999999999',
        title: '西湖龙井明前茶',
        category: '茶饮茗品',
        price: 88.0,
        cost: 25.0,
        stock: 30,
        type: 'PHYSICAL',
      );

      provider.addProduct(newProduct);

      expect(provider.products.length, initialCount + 1);
      expect(provider.products.first.title, '西湖龙井明前茶');
      expect(provider.products.first.price, 88.0);
    });

    test('2. Updating existing product by ID replaces existing item without duplicating', () {
      final prod1 = ProductModel(
        id: 888,
        productCode: '691111111111',
        title: '香薰精油',
        category: '护理耗材',
        price: 50.0,
      );
      provider.addProduct(prod1);
      final countAfterAdd = provider.products.length;

      // Update price and title
      final prodUpdated = ProductModel(
        id: 888,
        productCode: '691111111111',
        title: '香薰精油 (特级升级版)',
        category: '护理耗材',
        price: 68.0,
      );
      provider.addProduct(prodUpdated);

      expect(provider.products.length, countAfterAdd);
      final found = provider.products.firstWhere((p) => p.id == 888);
      expect(found.title, '香薰精油 (特级升级版)');
      expect(found.price, 68.0);
    });

    test('3. Finding product by barcode (exact, case-insensitive, fuzzy)', () {
      final prod = ProductModel(
        id: 777,
        productCode: '697890123456',
        title: '云南普洱茶饼',
        category: '茶饮茗品',
        price: 158.0,
      );
      provider.addProduct(prod);

      // Exact match
      expect(provider.findProductByBarcode('697890123456'), isNotNull);
      expect(provider.findProductByBarcode('697890123456')!.title, '云南普洱茶饼');

      // UPC-A with leading 0 tolerance match
      expect(provider.findProductByBarcode('0697890123456'), isNotNull);
      expect(provider.findProductByBarcode('0697890123456')!.title, '云南普洱茶饼');

      // Forward substring match with length >= 4
      expect(provider.findProductByBarcode('789012'), isNotNull);

      // Short code anti-collision: short noise under 4 chars must not fuzzy match
      expect(provider.findProductByBarcode('69'), isNull);

      // Empty barcode
      expect(provider.findProductByBarcode(''), isNull);
      expect(provider.findProductByBarcode('   '), isNull);
    });

    test('4. Cart operations: addToCart, updateQuantity, clearCart', () {
      final p1 = ProductModel(id: 1, productCode: 'P01', title: '服务A', category: '项目', price: 100.0);
      final p2 = ProductModel(id: 2, productCode: 'P02', title: '商品B', category: '实物', price: 50.0);

      // Add to cart
      provider.addToCart(p1);
      expect(provider.cartItems.length, 1);
      expect(provider.cartItems.first.quantity, 1);
      expect(provider.rawTotalAmount, 100.0);

      // Add same item again -> quantity increases
      provider.addToCart(p1);
      expect(provider.cartItems.length, 1);
      expect(provider.cartItems.first.quantity, 2);
      expect(provider.rawTotalAmount, 200.0);

      // Add different item
      provider.addToCart(p2);
      expect(provider.cartItems.length, 2);
      expect(provider.rawTotalAmount, 250.0);

      // Update quantity
      provider.updateQuantity(p2.id, 3);
      expect(provider.rawTotalAmount, 350.0); // 100*2 + 50*3 = 350

      // Remove item by setting quantity to 0
      provider.updateQuantity(p2.id, 0);
      expect(provider.cartItems.length, 1);
      expect(provider.rawTotalAmount, 200.0);

      // Clear cart
      provider.clearCart();
      expect(provider.cartItems.isEmpty, isTrue);
      expect(provider.rawTotalAmount, 0.0);
    });

    test('5. Discount calculations: VIP discount, payable amount', () {
      final p = ProductModel(id: 10, productCode: 'P10', title: 'SPA全身按摩', category: '项目', price: 200.0);
      provider.addToCart(p);

      // Default rate 1.0 (no discount)
      expect(provider.rawTotalAmount, 200.0);
      expect(provider.discountAmount, 0.0);
      expect(provider.payableAmount, 200.0);

      // Apply 85折 VIP
      provider.setDiscountRate(0.85);
      expect(provider.discountRate, 0.85);
      expect(provider.rawTotalAmount, 200.0);
      expect(provider.discountAmount, closeTo(30.0, 0.001));
      expect(provider.payableAmount, closeTo(170.0, 0.001));

      // Apply 8折 VIP
      provider.setDiscountRate(0.80);
      expect(provider.discountAmount, closeTo(40.0, 0.001));
      expect(provider.payableAmount, closeTo(160.0, 0.001));
    });

    test('6. Space & Customer binding', () {
      provider.bindSpace(
        spaceId: 101,
        sessionId: 202,
        spaceCode: 'VIP-01',
        spaceName: '天王星包厢',
        customerName: '李总',
        customerPhone: '13888888888',
      );

      expect(provider.selectedSpaceId, 101);
      expect(provider.selectedSessionId, 202);
      expect(provider.selectedSpaceCode, 'VIP-01');
      expect(provider.selectedSpaceName, '天王星包厢');
      expect(provider.customerName, '李总');
      expect(provider.customerPhone, '13888888888');

      provider.clearCart();
      expect(provider.selectedSpaceId, isNull);
      expect(provider.customerName, isNull);
    });

    test('7. Product deletion removes from products list and cleans up cart items', () async {
      final p1 = ProductModel(id: 99, productCode: 'DEL_01', title: '待删除项目', category: '项目', price: 88.0);
      provider.addProduct(p1);
      provider.addToCart(p1);

      expect(provider.products.any((p) => p.id == 99), isTrue);
      expect(provider.cartItems.any((item) => item.id == 99), isTrue);

      // Trigger deletion
      final deleted = await provider.deleteProductFromServer(99);
      expect(deleted, isTrue);
      expect(provider.products.any((p) => p.id == 99), isFalse);
      expect(provider.cartItems.any((item) => item.id == 99), isFalse);
    });
  });
}

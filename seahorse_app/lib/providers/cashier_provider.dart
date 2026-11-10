import 'package:flutter/material.dart';
import '../core/constants/constants.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/cashier_service.dart';

class CashierProvider extends ChangeNotifier {
  final CashierService _service = CashierService();

  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> get categories => _categories;

  final List<OrderLineItem> _cartItems = [];
  List<OrderLineItem> get cartItems => _cartItems;

  int? _selectedSpaceId;
  int? get selectedSpaceId => _selectedSpaceId;

  int? _selectedSessionId;
  int? get selectedSessionId => _selectedSessionId;

  String? _selectedSpaceCode;
  String? get selectedSpaceCode => _selectedSpaceCode;

  String? _selectedSpaceName;
  String? get selectedSpaceName => _selectedSpaceName;

  String? _customerName;
  String? get customerName => _customerName;

  String? _customerPhone;
  String? get customerPhone => _customerPhone;

  double _discountRate = 1.0;
  double get discountRate => _discountRate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double get rawTotalAmount {
    double sum = 0.0;
    for (var item in _cartItems) {
      sum += item.subtotal;
    }
    return sum;
  }

  double get discountAmount {
    return rawTotalAmount * (1 - _discountRate);
  }

  double get payableAmount {
    return rawTotalAmount - discountAmount;
  }

  CashierProvider() {
    loadProducts();
    loadCategories();
  }

  Future<bool> loadProducts({String? storeId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await _service.getProducts(storeId: storeId);
      _products = list;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 拉取服务端最新项目与商品分类列表
  Future<bool> loadCategories({String? industry, String? storeId, String? tenantId}) async {
    try {
      final list = await _service.getCategories(industry: industry, storeId: storeId, tenantId: tenantId);
      if (list.isNotEmpty) {
        _categories = list;
      } else {
        // 自动从当前已加载的商品中提取分类
        final Set<String> extracted = {};
        for (var p in _products) {
          if (p.category.isNotEmpty) extracted.add(p.category);
        }
        if (extracted.isNotEmpty) {
          _categories = extracted.map((name) => {'id': null, 'name': name}).toList();
        } else {
          _categories = [];
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 保存或新建分类至服务端，若为重命名则批量更新关联商品
  Future<Map<String, dynamic>?> saveCategoryToServer(Map<String, dynamic> data, {String? oldName}) async {
    final saved = await _service.saveCategory(data);
    final finalName = data['name']?.toString() ?? '';
    final dynamic finalId = saved?['id'] ?? data['id'];
    final categoryItem = {'id': finalId, 'name': finalName, 'available': true};

    final existingIdx = _categories.indexWhere((c) =>
      (finalId != null && c['id'] == finalId) ||
      (oldName != null && c['name'] == oldName) ||
      c['name'] == finalName
    );

    if (existingIdx != -1) {
      _categories[existingIdx] = categoryItem;
    } else {
      _categories.add(categoryItem);
    }

    // 若名称发生变化，同步更新关联商品的分类属性
    if (oldName != null && oldName.isNotEmpty && oldName != finalName) {
      for (int i = 0; i < _products.length; i++) {
        if (_products[i].category == oldName) {
          _products[i] = _products[i].copyWith(
            category: finalName,
          );
        }
      }
    }
    notifyListeners();
    return saved ?? categoryItem;
  }

  /// 删除分类并从本地移除
  Future<bool> deleteCategoryFromServer(dynamic id, String categoryName) async {
    bool success = false;
    if (id != null) {
      success = await _service.deleteCategory(id);
    } else {
      success = true;
    }
    _categories.removeWhere((c) => (id != null && c['id'] == id) || c['name'] == categoryName);
    notifyListeners();
    return success;
  }

  /// 统计某分类下的在售商品与服务数量
  int getProductCountByCategory(String categoryName) {
    if (categoryName.isEmpty) return 0;
    return _products.where((p) =>
      p.category == categoryName ||
      (categoryName == 'ALL')
    ).length;
  }

  /// 依据条形码/编码精准或容错查找商品 (优化去除反向模糊匹配，防止同条码识别不一致)
  ProductModel? findProductByBarcode(String barcode) {
    if (barcode.trim().isEmpty) return null;
    final clean = barcode.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (clean.isEmpty) return null;

    // 1. 第一优先级：全等精准匹配 (忽略大小写及特殊字符)
    for (var p in _products) {
      final pCode = p.productCode.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (pCode.isNotEmpty && pCode == clean) {
        return p;
      }
    }

    // 2. 第二优先级：针对 EAN-13 与 UPC-A 的前导 0 容错匹配 (例如 069xxx 与 69xxx 互转)
    final noLeadingZero = clean.replaceFirst(RegExp(r'^0+'), '');
    if (noLeadingZero.isNotEmpty && noLeadingZero != clean) {
      for (var p in _products) {
        final pCode = p.productCode.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        final pNoZero = pCode.replaceFirst(RegExp(r'^0+'), '');
        if (pNoZero.isNotEmpty && (pCode == noLeadingZero || pNoZero == clean || pNoZero == noLeadingZero)) {
          return p;
        }
      }
    }

    // 3. 第三优先级：正向精准包含匹配 (仅当编码有效长度>=4位时才允许，绝不反向包含，杜绝短码被所有长条码误伤)
    if (clean.length >= 4) {
      for (var p in _products) {
        final pCode = p.productCode.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (pCode.length >= clean.length && pCode.contains(clean)) {
          return p;
        }
      }
    }

    return null;
  }

  /// 登记或新增商品并同步状态
  void addProduct(ProductModel product) {
    final idx = _products.indexWhere((p) => p.id == product.id && p.id > 0);
    if (idx != -1) {
      _products[idx] = product;
    } else {
      final codeIdx = _products.indexWhere((p) => p.productCode.isNotEmpty && p.productCode == product.productCode);
      if (codeIdx != -1) {
        _products[codeIdx] = product;
      } else {
        _products.insert(0, product);
      }
    }
    notifyListeners();
  }

  /// 向服务端持久化保存商品
  Future<ProductModel?> saveProductToServer(ProductModel product) async {
    final saved = await _service.saveProduct(product);
    if (saved != null) {
      addProduct(saved);
      return saved;
    } else {
      addProduct(product);
      return product;
    }
  }

  /// 从服务端删除商品或服务项，并同步移除本地缓存与购物车
  Future<bool> deleteProductFromServer(dynamic id, {String? productCode}) async {
    bool success = false;
    if (id != null && id > 0) {
      success = await _service.deleteProduct(id);
    } else {
      success = true;
    }
    _products.removeWhere((p) => (id != null && id > 0 && p.id == id) || (productCode != null && productCode.isNotEmpty && p.productCode == productCode));
    _cartItems.removeWhere((item) => (id != null && id > 0 && item.id == id));
    notifyListeners();
    return success;
  }

  void bindSpace({int? spaceId, int? sessionId, String? spaceCode, String? spaceName, String? customerName, String? customerPhone}) {
    _selectedSpaceId = spaceId;
    _selectedSessionId = sessionId;
    _selectedSpaceCode = spaceCode;
    _selectedSpaceName = spaceName;
    _customerName = customerName;
    _customerPhone = customerPhone;
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    final existingIndex = _cartItems.indexWhere((i) => i.id == product.id);
    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity += 1;
    } else {
      _cartItems.add(OrderLineItem(
        id: product.id,
        title: product.title,
        price: product.price,
        quantity: 1,
        type: product.type,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(int itemId, int newQuantity) {
    final index = _cartItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void setCustomer(String? name, String? phone, {double? discountRate}) {
    _customerName = name;
    _customerPhone = phone;
    if (discountRate != null) {
      _discountRate = discountRate;
    }
    notifyListeners();
  }

  void setDiscountRate(double rate) {
    _discountRate = rate;
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _selectedSpaceId = null;
    _selectedSessionId = null;
    _selectedSpaceCode = null;
    _selectedSpaceName = null;
    _customerName = null;
    _customerPhone = null;
    _discountRate = 1.0;
    notifyListeners();
  }

  void setCartItemsFromSession(List<OrderLineItem> items) {
    _cartItems.clear();
    _cartItems.addAll(items);
    notifyListeners();
  }

  Future<OrderModel> checkout({
    required String storeId,
    required PaymentMethod paymentMethod,
    int? memberId,
    String? customerName,
    String? customerPhone,
    String? timeCardNo,
  }) async {
    final order = await _service.checkout(
      storeId: storeId,
      spaceId: _selectedSpaceId,
      sessionId: _selectedSessionId,
      spaceCode: _selectedSpaceCode,
      spaceName: _selectedSpaceName,
      memberId: memberId,
      customerName: customerName ?? _customerName,
      customerPhone: customerPhone ?? _customerPhone,
      timeCardNo: timeCardNo,
      items: List.from(_cartItems),
      totalAmount: rawTotalAmount,
      discountAmount: discountAmount,
      payableAmount: payableAmount,
      paymentMethod: paymentMethod,
    );

    // 本地立即就地扣减实物商品剩余物理库存，保持界面即时响应
    for (final item in _cartItems) {
      final pIdx = _products.indexWhere((p) => (p.id > 0 && p.id == item.id) || (p.title.isNotEmpty && p.title == item.title));
      if (pIdx != -1) {
        final p = _products[pIdx];
        if (p.isPhysical) {
          final newStock = (p.stock - item.quantity).clamp(0, 999999);
          _products[pIdx] = p.copyWith(stock: newStock);
        }
      }
    }
    notifyListeners();

    clearCart();
    return order;
  }
}

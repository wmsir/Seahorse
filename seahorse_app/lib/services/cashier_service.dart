import '../core/storage/local_storage.dart';
import '../core/constants/constants.dart';
import '../core/network/api_client.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
class CashierService {
  final ApiClient _client = ApiClient();
  final List<OrderModel> _recentOrders = [];

  Future<List<ProductModel>> getProducts({String? storeId}) async {
    try {
      final response = await _client.dio.get('/product/list', queryParameters: {
        if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
      });
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          return list.map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
    } catch (e) {
      print('CashierService getProducts from server error: $e');
      rethrow;
    }
    return [];
  }

  /// 保存或录入新商品至云端服务端
  Future<ProductModel?> saveProduct(ProductModel product, {String? storeId}) async {
    try {
      final payload = product.toJson();
      final effStoreId = (storeId != null && storeId.isNotEmpty)
          ? storeId
          : (LocalStorage.getString('seahorse_store_id') ?? 'S001');
      final effTenantId = LocalStorage.getString('seahorse_tenant_id') ?? 'T001';
      payload['storeId'] = effStoreId;
      payload['tenantId'] = effTenantId;
      final response = await _client.dio.post('/product/save', data: payload);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map) {
          return ProductModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      print('CashierService saveProduct error: $e');
    }
    return null;
  }

  /// 删除商品或服务项目
  Future<bool> deleteProduct(dynamic id) async {
    try {
      final response = await _client.dio.delete('/product/$id');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('CashierService deleteProduct server response: $e');
    }
    return false;
  }

  /// 获取项目与商品分类列表
  Future<List<Map<String, dynamic>>> getCategories({String? industry, String? storeId, String? tenantId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (industry != null && industry.isNotEmpty) params['industry'] = industry;
      if (storeId != null && storeId.isNotEmpty) params['storeId'] = storeId;
      if (tenantId != null && tenantId.isNotEmpty) params['tenantId'] = tenantId;

      final response = await _client.dio.get(
        '/product/categories',
        queryParameters: params.isNotEmpty ? params : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List) {
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      print('CashierService getCategories error: $e');
    }
    return [];
  }

  /// 创建或更新分类
  Future<Map<String, dynamic>?> saveCategory(Map<String, dynamic> categoryData) async {
    try {
      final response = await _client.dio.post('/product/category/save', data: categoryData);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      print('CashierService saveCategory error: $e');
    }
    return null;
  }

  /// 删除分类
  Future<bool> deleteCategory(dynamic id) async {
    try {
      final response = await _client.dio.delete('/product/category/$id');
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('CashierService deleteCategory error: $e');
    }
    return false;
  }



  /// 执行移动收银结账
  Future<OrderModel> checkout({
    required String storeId,
    int? spaceId,
    int? sessionId,
    String? spaceCode,
    String? spaceName,
    int? memberId,
    String? customerName,
    String? customerPhone,
    String? timeCardNo,
    required List<OrderLineItem> items,
    required double totalAmount,
    double discountAmount = 0.0,
    required double payableAmount,
    required PaymentMethod paymentMethod,
  }) async {
    final now = DateTime.now();
    final orderNo = 'ORD${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch % 100000}';

    final order = OrderModel(
      orderNo: orderNo,
      storeId: storeId,
      spaceCode: spaceCode,
      spaceName: spaceName,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      payableAmount: payableAmount,
      paymentMethod: paymentMethod,
      status: 'PAID',
      createTime: now,
      payTime: now,
    );

    _recentOrders.insert(0, order);

    String backendChannel;
    switch (paymentMethod) {
      case PaymentMethod.memberCard:
        backendChannel = 'STORED_VALUE';
        break;
      case PaymentMethod.timesCard:
        backendChannel = 'TIME_CARD';
        break;
      case PaymentMethod.wechat:
        backendChannel = 'WECHAT';
        break;
      case PaymentMethod.alipay:
        backendChannel = 'ALIPAY';
        break;
      case PaymentMethod.cash:
        backendChannel = 'CASH';
        break;
    }

    try {
      final checkoutCmd = {
        'orderNo': orderNo,
        if (memberId != null) 'memberId': memberId,
        if (spaceId != null) 'spaceId': spaceId,
        if (sessionId != null) 'sessionId': sessionId,
        'totalAmount': totalAmount,
        'actualAmount': payableAmount,
        'discountAmount': discountAmount,
        'spaceName': spaceName ?? '移动收银台',
        'customerName': customerName ?? '散客顾客',
        'customerPhone': customerPhone ?? '',
        'cashierName': '移动店员',
        if (timeCardNo != null && timeCardNo.isNotEmpty) 'timeCardNo': timeCardNo,
        'splitItems': [
          {
            'channel': backendChannel,
            'amount': payableAmount,
            if (backendChannel == 'CASH') 'tenderedAmount': payableAmount,
            if (timeCardNo != null && timeCardNo.isNotEmpty) 'timeCardNo': timeCardNo,
          }
        ],
        'items': items.map((it) => {
          'productId': it.id,
          'productName': it.title,
          'productType': it.type == 'RETAIL' ? 'PHYSICAL' : it.type,
          'price': it.price,
          'quantity': it.quantity,
        }).toList(),
      };
      final response = await _client.dio.post('/billing/checkout', data: checkoutCmd);
      if (response.data is Map && response.data['code'] != null && response.data['code'] != 200) {
        final errMsg = response.data['message']?.toString() ?? '结账校验未通过';
        if (errMsg.contains('余额不足') || errMsg.contains('储值') || errMsg.contains('次卡') || errMsg.contains('金额不足')) {
          _recentOrders.remove(order);
          throw Exception(errMsg);
        }
      }

      if (spaceId != null) {
        try {
          await _client.dio.post('/space/$spaceId/reset');
        } catch (_) {}
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('余额不足') || errStr.contains('储值') || errStr.contains('次卡') || errStr.contains('金额不足')) {
        _recentOrders.remove(order);
        rethrow;
      }
      print('CashierService checkout API note: $e');
    }

    return order;
  }

  /// 获取门店常用服务要求与特殊备注标签 (多端云端双向同步)
  Future<List<String>> getCommonRemarks(String storeId, [String? industry]) async {
    try {
      final response = await _client.dio.get('/store/common-remarks', queryParameters: {
        'storeId': storeId,
        if (industry != null) 'industry': industry,
      });
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is List) {
          return data.map((e) => e.toString()).toList();
        }
      }
    } catch (e) {
      print('CashierService getCommonRemarks error: $e');
    }
    return [];
  }

  /// 保存门店常用服务要求与特殊备注标签 (手机端/浏览器双向同步)
  Future<bool> saveCommonRemarks(String storeId, List<String> remarks) async {
    try {
      final response = await _client.dio.post('/store/common-remarks', data: {
        'storeId': storeId,
        'remarks': remarks,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('CashierService saveCommonRemarks error: $e');
      return false;
    }
  }

  /// 获取门店服务人员称谓展示规则 (NICKNAME_FIRST, NICKNAME, REAL_NAME, BOTH)
  Future<String> getStaffDisplayMode(String storeId) async {
    try {
      final response = await _client.dio.get('/store/staff-display-mode', queryParameters: {
        'storeId': storeId,
      });
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (data is Map && data['staffDisplayMode'] != null) {
          return data['staffDisplayMode'].toString();
        }
      }
    } catch (e) {
      print('CashierService getStaffDisplayMode error: $e');
    }
    return 'NICKNAME_FIRST';
  }

  List<OrderModel> getRecentOrders() => _recentOrders;
}

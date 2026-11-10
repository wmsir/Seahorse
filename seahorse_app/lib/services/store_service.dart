import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import '../models/store_model.dart';
class StoreService {
  final ApiClient _client = ApiClient();

  Future<List<StoreModel>> getStores() async {
    try {
      final response = await _client.dio.get('/space/stores');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        final list = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
        if (list is List && list.isNotEmpty) {
          return list.map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      }
    } catch (e) {
      print('StoreService getStores from server: $e');
    }
    return [];
  }

  Future<void> switchStore(String storeId, String storeName, {String? tenantId}) async {
    await LocalStorage.setString('seahorse_store_id', storeId);
    await LocalStorage.setString('seahorse_store_name', storeName);
    if (tenantId != null && tenantId.isNotEmpty) {
      await LocalStorage.setString('seahorse_tenant_id', tenantId);
    }
  }

  String getCurrentStoreId() {
    final id = LocalStorage.getString('seahorse_store_id');
    if (id != null && id.isNotEmpty) {
      return id;
    }
    return '';
  }

  String getCurrentStoreName() {
    final name = LocalStorage.getString('seahorse_store_name');
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return '暂未关联实体门店';
  }
}

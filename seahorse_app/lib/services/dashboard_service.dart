import '../core/network/api_client.dart';
import '../models/dashboard_stats_model.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  /// 获取今日经营核心看板数据 (支持指定门店 storeId)
  Future<DashboardStatsModel> getStats({String? storeId}) async {
    try {
      final Map<String, dynamic> params = {};
      if (storeId != null && storeId.isNotEmpty) {
        params['storeId'] = storeId;
      }
      final response = await _client.dio.get(
        '/dashboard/stats',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return DashboardStatsModel.fromJson(data);
        }
      }
      return DashboardStatsModel();
    } catch (e) {
      // 网络异常时严格返回纯净真实初始值，绝不注入假数据
      return DashboardStatsModel();
    }
  }

  /// 门店管理专属接口：获取当前门店真实经营简报
  Future<DashboardStatsModel> getStoreDashboardStats(String storeId) async {
    return getStats(storeId: storeId);
  }
}

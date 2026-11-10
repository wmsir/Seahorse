import '../core/network/api_client.dart';

class StoreNoticeModel {
  final String id;
  final String storeId;
  final String title;
  final String category; // REGULATION, NOTICE, URGENT
  final String categoryName;
  final String summary;
  final String content;
  final List<String> keyPoints;
  final String version;
  final String effectiveDate;
  final String publisher;
  final bool isUrgent;
  final bool playMusic;
  final bool requireSignature;
  final String status;

  StoreNoticeModel({
    required this.id,
    required this.storeId,
    required this.title,
    required this.category,
    required this.categoryName,
    required this.summary,
    required this.content,
    required this.keyPoints,
    required this.version,
    required this.effectiveDate,
    required this.publisher,
    required this.isUrgent,
    required this.playMusic,
    required this.requireSignature,
    required this.status,
  });

  factory StoreNoticeModel.fromJson(Map<String, dynamic> json) {
    List<String> kpList = [];
    if (json['keyPoints'] != null) {
      final kpStr = json['keyPoints'].toString();
      kpList = kpStr.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return StoreNoticeModel(
      id: json['id']?.toString() ?? '',
      storeId: json['storeId']?.toString() ?? 'ALL',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'NOTICE',
      categoryName: json['categoryName']?.toString() ?? '日常公告',
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      keyPoints: kpList,
      version: json['version']?.toString() ?? 'V1.0',
      effectiveDate: json['effectiveDate']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '门店管理',
      isUrgent: json['isUrgent'] == true || json['urgent'] == true,
      playMusic: json['playMusic'] == true,
      requireSignature: json['requireSignature'] == true,
      status: json['status']?.toString() ?? 'PUBLISHED',
    );
  }
}

class NoticeService {
  final ApiClient _client = ApiClient();

  /// 获取当前门店现行运营规范与日常公告
  Future<List<StoreNoticeModel>> getStoreNotices(String storeId, {String? category}) async {
    try {
      final query = <String, dynamic>{'storeId': storeId};
      if (category != null && category.isNotEmpty && category != 'ALL') {
        query['category'] = category;
      }
      final response = await _client.dio.get('/store/notice/list', queryParameters: query);
      if (response.statusCode == 200 && response.data != null) {
        final list = response.data['data'];
        if (list is List) {
          return list.map((item) => StoreNoticeModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      // 容错降级
    }
    return [];
  }

  /// 获取当前门店最新特急重要通知 (用于触发提示音乐与弹窗)
  Future<StoreNoticeModel?> getLatestUrgentNotice(String storeId) async {
    try {
      final response = await _client.dio.get(
        '/store/notice/urgent-latest',
        queryParameters: {'storeId': storeId},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          return StoreNoticeModel.fromJson(data);
        }
      }
    } catch (e) {
      // 容错
    }
    return null;
  }
}

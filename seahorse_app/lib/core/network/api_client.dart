import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  static const String defaultServerUrl = 'https://fwpt.cn/api';
  static const String fallbackServerUrl = 'http://39.97.158.22/api';
  String baseUrl = defaultServerUrl;

  ApiClient._internal() {
    final savedUrl = LocalStorage.getString('seahorse_server_url');
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      var normalized = savedUrl.trim();
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      baseUrl = normalized;
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = LocalStorage.getString('seahorse_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final storeId = LocalStorage.getString('seahorse_store_id');
        options.headers['X-Store-Id'] = (storeId != null && storeId.isNotEmpty) ? storeId : 'S001';
        final tenantId = LocalStorage.getString('seahorse_tenant_id');
        options.headers['X-Tenant-Id'] = (tenantId != null && tenantId.isNotEmpty) ? tenantId : 'T001';

        // 真实移动终端设备与系统标识注入 (HTTP 请求头必须严格使用 ASCII 字符，避免 FormatException)
        final String platformName = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'MobileApp');
        final String deviceDesc = Platform.isAndroid ? 'Android-App' : (Platform.isIOS ? 'iOS-App' : 'MobileApp');
        options.headers['X-Client-Platform'] = platformName;
        options.headers['X-Device-Type'] = deviceDesc;
        options.headers['User-Agent'] = 'SeahorseApp/1.0 ($platformName)';

        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  void updateBaseUrl(String newUrl) {
    var url = newUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    baseUrl = url;
    dio.options.baseUrl = url;
  }
}

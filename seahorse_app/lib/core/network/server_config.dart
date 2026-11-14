import 'package:dio/dio.dart';
import '../storage/local_storage.dart';
import 'api_client.dart';

class ServerConfig {
  static const String defaultRemoteUrl = 'https://fwpt.cn/api';
  static const String fallbackRemoteUrl = 'http://39.97.158.22/api';
  static const String localDebugUrl = 'http://127.0.0.1:8082/api';
  static const String storageKeyUrl = 'seahorse_server_url';

  static const List<Map<String, String>> serverPresets = [
    {
      'title': '官方 HTTPS 安全云网关 (推荐)',
      'url': 'https://fwpt.cn/api',
      'tag': 'SSL加密·全网直通',
    },
    {
      'title': '官方云端标准通道 (80端口)',
      'url': 'http://39.97.158.22/api',
      'tag': '80端口·兼容旧设备',
    },
    {
      'title': '本地安卓模拟器调试 (8082)',
      'url': 'http://10.0.2.2:8082/api',
      'tag': '开发调试',
    },
    {
      'title': '本机电脑直连调试 (8082)',
      'url': 'http://127.0.0.1:8082/api',
      'tag': '开发调试',
    },
  ];

  /// 获取当前配置的后端服务器 URL
  static String get currentUrl {
    final url = LocalStorage.getString(storageKeyUrl);
    if (url != null && url.isNotEmpty) {
      return url;
    }
    return defaultRemoteUrl;
  }

  /// 脱敏友好的服务节点名称展示（避免在登录界面直接裸露底层服务器IP）
  static String get displayNodeLabel {
    final u = currentUrl;
    if (u.contains('fwpt.cn')) {
      return '官方云端安全网关 (fwpt.cn)';
    }
    if (u.contains('39.97.158.22')) {
      return '官方云端标准通道 (主节点)';
    }
    return u.replaceAll('https://', '').replaceAll('http://', '');
  }

  /// 更新自定义服务器地址
  static Future<void> updateServerUrl(String url) async {
    await LocalStorage.setString(storageKeyUrl, url.trim());
    ApiClient().updateBaseUrl(url.trim());
  }

  /// 始终使用真实远程/后端接口模式
  static bool get isRemoteMode => true;

  /// 测试服务器连通性与网络延迟 (Ping)
  static Future<Map<String, dynamic>> testConnection([String? customUrl]) async {
    var baseUrl = (customUrl ?? currentUrl).trim();
    if (baseUrl.isEmpty) {
      baseUrl = defaultRemoteUrl;
    }
    while (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      validateStatus: (status) => status != null && status < 500,
    ));

    final probeCandidates = <String>[];
    if (baseUrl.endsWith('/ping') ||
        baseUrl.endsWith('/health') ||
        baseUrl.endsWith('/auth/plans')) {
      probeCandidates.add(baseUrl);
    } else {
      probeCandidates.addAll([
        '$baseUrl/ping',
        '$baseUrl/health',
        '$baseUrl/auth/plans',
        baseUrl,
      ]);
    }

    final stopwatch = Stopwatch()..start();
    DioException? lastDioError;
    int? lastStatusCode;

    for (final probeUrl in probeCandidates) {
      try {
        final res = await dio.get(probeUrl);
        final code = res.statusCode ?? 200;
        lastStatusCode = code;
        if (code >= 200 && code < 400) {
          stopwatch.stop();
          return {
            'success': true,
            'statusCode': code,
            'durationMs': stopwatch.elapsedMilliseconds,
            'message': 'HTTP $code · 响应极速',
          };
        }
      } on DioException catch (e) {
        lastDioError = e;
        if (e.response != null) {
          lastStatusCode = e.response?.statusCode;
        }
      } catch (_) {}
    }
    stopwatch.stop();

    if (lastStatusCode != null) {
      return {
        'success': true,
        'statusCode': lastStatusCode,
        'durationMs': stopwatch.elapsedMilliseconds,
        'message': lastStatusCode == 404
            ? '服务在线 (网关握手完成)'
            : '服务在线 (HTTP $lastStatusCode)',
      };
    }

    String failMsg = '无法连接到服务器';
    if (lastDioError != null) {
      if (lastDioError.type == DioExceptionType.connectionTimeout) {
        failMsg = '连接超时 (4s未响应)';
      } else if (lastDioError.type == DioExceptionType.receiveTimeout) {
        failMsg = '响应超时 (服务器未应答)';
      } else if (lastDioError.type == DioExceptionType.connectionError) {
        failMsg = '无法建立连接 (网络或IP不可达)';
      } else {
        failMsg = lastDioError.message ?? '网络连接异常';
      }
    }

    return {
      'success': false,
      'statusCode': null,
      'durationMs': stopwatch.elapsedMilliseconds,
      'message': failMsg,
    };
  }
}

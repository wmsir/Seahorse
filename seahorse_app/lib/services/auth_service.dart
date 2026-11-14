import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';
import 'account_manager.dart';
import 'leave_service.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(
    String username,
    String password, {
    bool rememberPassword = true,
  }) async {
    try {
      // 确保使用最新配置的服务器地址
      final currentConfigUrl = LocalStorage.getString('seahorse_server_url');
      if (currentConfigUrl != null && currentConfigUrl.isNotEmpty && _client.baseUrl != currentConfigUrl) {
        _client.updateBaseUrl(currentConfigUrl);
      }

      final String platform = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'MobileApp');
      final String device = Platform.isAndroid ? '安卓手机 APP (Android)' : (Platform.isIOS ? '苹果手机 APP (iOS)' : '海马App移动终端');

      // 1. 发起远程服务器认证请求 (支持标准 /auth/login)
      Response response;
      try {
        response = await _client.dio.post('/auth/login', data: {
          'username': username,
          'password': password,
          'clientPlatform': platform,
          'clientDevice': device,
        });
      } on DioException catch (dioErr) {
        // 如果网络超时或无法连通，尝试云端与本地 8082 开发端口通道自愈重试
        final isNetworkErr = dioErr.type == DioExceptionType.connectionTimeout ||
            dioErr.type == DioExceptionType.connectionError ||
            dioErr.type == DioExceptionType.sendTimeout ||
            dioErr.type == DioExceptionType.receiveTimeout;
        if (isNetworkErr) {
          final candidates = <String>[
            'https://fwpt.cn/api',
            'http://39.97.158.22/api',
            if (Platform.isAndroid) 'http://10.0.2.2:8082/api',
            'http://127.0.0.1:8082/api',
          ].where((u) => u != _client.baseUrl).toList();
          Response? recovered;
          for (final altUrl in candidates) {
            try {
              _client.updateBaseUrl(altUrl);
              await LocalStorage.setString('seahorse_server_url', altUrl);
              recovered = await _client.dio.post('/auth/login', data: {
                'username': username,
                'password': password,
                'clientPlatform': platform,
                'clientDevice': device,
              });
              break;
            } catch (_) {}
          }
          if (recovered != null) {
            response = recovered;
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final dynamic raw = response.data;
        // 关键校验 1：后端业务返回码必须为 200
        if (raw is Map && raw['code'] != null && raw['code'] != 200) {
          final msg = raw['message'] ?? '登录失败，请检查账号密码';
          return {'success': false, 'message': msg.toString()};
        }

        final Map<String, dynamic> data = (raw is Map<String, dynamic> && raw.containsKey('data') && raw['data'] is Map<String, dynamic>)
            ? raw['data'] as Map<String, dynamic>
            : (raw is Map<String, dynamic> ? raw : <String, dynamic>{});

        final token = data['token']?.toString() ?? '';
        // 关键校验 2：必须包含有效的授权 JWT Token，杜绝已清空账号登录
        if (token.isEmpty) {
          final msg = (raw is Map && raw['message'] != null) ? raw['message'].toString() : '登录鉴权失败：账号不存在或密码错误';
          return {'success': false, 'message': msg};
        }

        final role = data['role']?.toString() ?? (username.contains('admin') ? 'SUPER_ADMIN' : 'STORE_MANAGER');
        final realName = data['realName']?.toString() ?? data['username']?.toString() ?? username;
        final phone = data['phone']?.toString() ?? username;
        final storeId = data['storeId']?.toString() ?? '';
        final storeName = data['storeName']?.toString() ?? '';
        final tenantId = data['tenantId']?.toString() ?? '';
        final tenantName = data['tenantName']?.toString() ?? '';

        await LocalStorage.setString('seahorse_token', token);
        await LocalStorage.setString('seahorse_user', username);
        await LocalStorage.setString('seahorse_role', role);
        await LocalStorage.setString('seahorse_real_name', realName);
        await LocalStorage.setString('seahorse_phone', phone);
        if (tenantId.isNotEmpty) {
          await LocalStorage.setString('seahorse_tenant_id', tenantId);
        } else {
          await LocalStorage.remove('seahorse_tenant_id');
        }
        if (tenantName.isNotEmpty) {
          await LocalStorage.setString('seahorse_tenant_name', tenantName);
        } else {
          await LocalStorage.remove('seahorse_tenant_name');
        }
        if (storeId.isNotEmpty) {
          await LocalStorage.setString('seahorse_store_id', storeId);
        } else {
          await LocalStorage.remove('seahorse_store_id');
        }
        if (storeName.isNotEmpty) {
          await LocalStorage.setString('seahorse_store_name', storeName);
        } else {
          await LocalStorage.remove('seahorse_store_name');
        }

        // 保存账号至多账号管理器，支持记住密码与快速账号切换
        await AccountManager.saveLoginAccount(
          username: username,
          password: password,
          rememberPassword: rememberPassword,
          realName: realName,
          role: role,
          storeName: storeName,
          tenantName: tenantName,
          phone: phone,
        );

        return {
          'success': true,
          'data': {
            'token': token,
            'username': username,
            'realName': realName,
            'role': role,
            'phone': phone,
            'tenantId': tenantId,
            'tenantName': tenantName,
            'storeId': storeId,
            'storeName': storeName,
          }
        };
      } else {
        final msg = response.data is Map ? (response.data['message'] ?? '登录失败') : '登录失败';
        return {'success': false, 'message': msg.toString()};
      }
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        return {'success': false, 'message': e.response!.data['message'].toString()};
      }
      if (e.response?.statusCode == 401) {
        return {'success': false, 'message': '用户名或密码错误，请重新输入'};
      }
      if (e.response?.statusCode == 403) {
        return {'success': false, 'message': '账号无访问权限或已被禁用'};
      }
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      final isConnErr = e.type == DioExceptionType.connectionError;
      if (isTimeout || isConnErr) {
        return {
          'success': false,
          'message': '无法连接至服务器，请检查网络或点击右上角切换连接通道',
        };
      }
      final errorMsg = e.message ?? (e.error != null ? e.error.toString() : '网络连接异常，请重试');
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': '网络连接异常: $e'};
    }
  }

  Future<void> logout() async {
    LeaveService.clearLocalCache();
    await LocalStorage.remove('seahorse_token');
    await LocalStorage.remove('seahorse_user');
    await LocalStorage.remove('seahorse_role');
    await LocalStorage.remove('seahorse_real_name');
    await LocalStorage.remove('seahorse_phone');
    await LocalStorage.remove('seahorse_tenant_id');
    await LocalStorage.remove('seahorse_tenant_name');
    await LocalStorage.remove('seahorse_store_id');
    await LocalStorage.remove('seahorse_store_name');
  }

  bool isLoggedIn() {
    final token = LocalStorage.getString('seahorse_token');
    return token != null && token.isNotEmpty;
  }
}

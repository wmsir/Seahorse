import 'package:flutter_test/flutter_test.dart';
import 'package:seahorse_app/core/network/api_client.dart';
import 'package:seahorse_app/core/network/server_config.dart';
import 'package:seahorse_app/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    ApiClient().updateBaseUrl(ServerConfig.defaultRemoteUrl);
  });

  test('ServerConfig falls back to defaultRemoteUrl when storage is empty', () {
    expect(ServerConfig.currentUrl, equals(ServerConfig.defaultRemoteUrl));
    expect(ServerConfig.isRemoteMode, isTrue);
    expect(ServerConfig.displayNodeLabel, equals('官方云端安全网关 (fwpt.cn)'));
  });

  test('ServerConfig.updateServerUrl trims whitespace and normalizes trailing slashes on ApiClient', () async {
    await ServerConfig.updateServerUrl('  http://127.0.0.1:8082/api///  ');

    expect(ServerConfig.currentUrl, equals('http://127.0.0.1:8082/api///'));
    expect(ApiClient().baseUrl, equals('http://127.0.0.1:8082/api'));
    expect(ApiClient().dio.options.baseUrl, equals('http://127.0.0.1:8082/api'));
  });

  test('ServerConfig.displayNodeLabel formats custom local endpoint without scheme prefix', () async {
    await ServerConfig.updateServerUrl('http://127.0.0.1:8082/api');

    expect(ServerConfig.displayNodeLabel, equals('127.0.0.1:8082/api'));
  });
}

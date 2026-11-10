import 'package:flutter_test/flutter_test.dart';
import 'package:seahorse_app/core/network/server_config.dart';
import 'package:seahorse_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seahorse_app/core/storage/local_storage.dart';

void main() {
  test('AuthService login test with correct admin password', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final authService = AuthService();
    final result = await authService.login('admin', '123456');
    print('AuthService login result: $result');
    expect(result['success'], isTrue);
    expect(authService.isLoggedIn(), isTrue);
    expect(LocalStorage.getString('seahorse_user'), equals('admin'));
  });

  test('AuthService login test with wrong password', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    final authService = AuthService();
    final result = await authService.login('admin', 'wrongpassword');
    print('Wrong password result: $result');
    expect(result['success'], isFalse);
    expect(result['message'], contains('密码错误'));
  });

  test('ServerConfig ping test 80 and 8080', () async {
    final res80 = await ServerConfig.testConnection('http://39.97.158.22/api');
    expect(res80['success'], isTrue);
    expect(res80['statusCode'], equals(200));

    final res8080 = await ServerConfig.testConnection('http://39.97.158.22:8080/api');
    expect(res8080['success'], isTrue);
    expect(res8080['statusCode'], equals(200));
  });
}

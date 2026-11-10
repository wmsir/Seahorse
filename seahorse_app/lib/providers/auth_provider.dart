import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/storage/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String _username = '';
  String get username => _username;

  String _realName = '';
  String get realName => _realName;

  String _role = 'STORE_MANAGER';
  String get role => _role;

  AuthProvider() {
    checkLoginStatus();
  }

  void checkLoginStatus() {
    _isLoggedIn = _authService.isLoggedIn();
    _username = LocalStorage.getString('seahorse_user') ?? '';
    _realName = LocalStorage.getString('seahorse_real_name') ?? (_username.contains('admin') ? '系统超级管理员' : '店长');
    _role = LocalStorage.getString('seahorse_role') ?? (_username.contains('admin') ? 'SUPER_ADMIN' : 'STORE_MANAGER');
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password, {bool rememberPassword = true}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(username, password, rememberPassword: rememberPassword);
    _isLoading = false;

    if (result['success'] == true) {
      _isLoggedIn = true;
      _username = username;
      _realName = result['data']['realName'] ?? username;
      _role = result['data']['role'] ?? 'STORE_MANAGER';
      notifyListeners();
      return true;
    }

    _errorMessage = result['message']?.toString() ?? '登录失败，请检查账号密码或服务器状态';
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _username = '';
    _realName = '';
    notifyListeners();
  }
}

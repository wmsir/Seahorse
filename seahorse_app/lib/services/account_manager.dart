import 'dart:convert';
import '../core/storage/local_storage.dart';

class SavedAccountModel {
  final String username;
  final String realName;
  final String role;
  final String storeName;
  final String tenantName;
  final String phone;
  final bool rememberPassword;
  final String savedPassword;
  final String lastLoginTime;

  SavedAccountModel({
    required this.username,
    this.realName = '',
    this.role = 'STORE_MANAGER',
    this.storeName = '',
    this.tenantName = '',
    this.phone = '',
    this.rememberPassword = true,
    this.savedPassword = '',
    required this.lastLoginTime,
  });

  factory SavedAccountModel.fromJson(Map<String, dynamic> json) {
    return SavedAccountModel(
      username: json['username']?.toString() ?? '',
      realName: json['realName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'STORE_MANAGER',
      storeName: json['storeName']?.toString() ?? '',
      tenantName: json['tenantName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      rememberPassword: json['rememberPassword'] != false,
      savedPassword: json['savedPassword']?.toString() ?? '',
      lastLoginTime: json['lastLoginTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'realName': realName,
      'role': role,
      'storeName': storeName,
      'tenantName': tenantName,
      'phone': phone,
      'rememberPassword': rememberPassword,
      'savedPassword': savedPassword,
      'lastLoginTime': lastLoginTime,
    };
  }
}

class AccountManager {
  static const String _storageKeyAccounts = 'seahorse_account_history';
  static const String _storageKeyRememberPassword = 'seahorse_remember_password';
  static const String _storageKeyLastUser = 'seahorse_last_login_user';

  /// 获取所有已保存的登录账号历史
  static List<SavedAccountModel> getSavedAccounts() {
    try {
      final raw = LocalStorage.getString(_storageKeyAccounts);
      if (raw == null || raw.trim().isEmpty) {
        return [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final list = decoded
            .whereType<Map>()
            .map((e) => SavedAccountModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        list.sort((a, b) => b.lastLoginTime.compareTo(a.lastLoginTime));
        return list;
      }
    } catch (e) {
      print('AccountManager getSavedAccounts error: $e');
    }
    return [];
  }

  /// 获取上次登录使用的账号（用于启动时自动填充）
  static SavedAccountModel? getLastUsedAccount() {
    final accounts = getSavedAccounts();
    if (accounts.isEmpty) return null;
    final lastUser = LocalStorage.getString(_storageKeyLastUser);
    if (lastUser != null && lastUser.isNotEmpty) {
      final match = accounts.where((a) => a.username == lastUser).toList();
      if (match.isNotEmpty) return match.first;
    }
    return accounts.first;
  }

  /// 是否开启记住密码偏好
  static bool isRememberPasswordEnabled() {
    return LocalStorage.getBool(_storageKeyRememberPassword) ?? true;
  }

  /// 设置记住密码开关状态
  static Future<void> setRememberPasswordEnabled(bool enabled) async {
    await LocalStorage.setBool(_storageKeyRememberPassword, enabled);
  }

  /// 保存登录成功的账号信息
  static Future<void> saveLoginAccount({
    required String username,
    required String password,
    required bool rememberPassword,
    String? realName,
    String? role,
    String? storeName,
    String? tenantName,
    String? phone,
  }) async {
    try {
      await LocalStorage.setBool(_storageKeyRememberPassword, rememberPassword);
      await LocalStorage.setString(_storageKeyLastUser, username);

      final accounts = getSavedAccounts();
      final nowStr = DateTime.now().toIso8601String();

      final existingIndex = accounts.indexWhere((a) => a.username == username);
      final newAccount = SavedAccountModel(
        username: username,
        realName: (realName != null && realName.isNotEmpty)
            ? realName
            : (existingIndex != -1 ? accounts[existingIndex].realName : ''),
        role: (role != null && role.isNotEmpty)
            ? role
            : (existingIndex != -1 ? accounts[existingIndex].role : 'STORE_MANAGER'),
        storeName: (storeName != null && storeName.isNotEmpty)
            ? storeName
            : (existingIndex != -1 ? accounts[existingIndex].storeName : ''),
        tenantName: (tenantName != null && tenantName.isNotEmpty)
            ? tenantName
            : (existingIndex != -1 ? accounts[existingIndex].tenantName : ''),
        phone: (phone != null && phone.isNotEmpty)
            ? phone
            : (existingIndex != -1 ? accounts[existingIndex].phone : username),
        rememberPassword: rememberPassword,
        savedPassword: rememberPassword ? password : '',
        lastLoginTime: nowStr,
      );

      if (existingIndex != -1) {
        accounts[existingIndex] = newAccount;
      } else {
        accounts.insert(0, newAccount);
      }

      final jsonStr = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await LocalStorage.setString(_storageKeyAccounts, jsonStr);
    } catch (e) {
      print('AccountManager saveLoginAccount error: $e');
    }
  }

  /// 移除指定历史账号
  static Future<void> removeAccount(String username) async {
    try {
      final accounts = getSavedAccounts();
      accounts.removeWhere((a) => a.username == username);
      final jsonStr = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await LocalStorage.setString(_storageKeyAccounts, jsonStr);

      final lastUser = LocalStorage.getString(_storageKeyLastUser);
      if (lastUser == username) {
        if (accounts.isNotEmpty) {
          await LocalStorage.setString(_storageKeyLastUser, accounts.first.username);
        } else {
          await LocalStorage.remove(_storageKeyLastUser);
        }
      }
    } catch (e) {
      print('AccountManager removeAccount error: $e');
    }
  }
}

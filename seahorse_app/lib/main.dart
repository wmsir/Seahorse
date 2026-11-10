import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/network/server_config.dart';
import 'core/storage/local_storage.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏沉浸式透明
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 初始化本地持久化存储并彻底清理脏缓存
  await LocalStorage.init();
  await LocalStorage.remove('seahorse_data_mode');
  await LocalStorage.remove('seahorse_appointments_data');
  await LocalStorage.remove('mock_appointments');
  await LocalStorage.remove('seahorse_mock_orders');

  // 初始化默认服务器地址：默认采用 HTTPS 官方安全网关 (https://fwpt.cn/api)
  final existingUrl = LocalStorage.getString('seahorse_server_url');
  if (existingUrl == null ||
      existingUrl.isEmpty ||
      existingUrl.contains(':8080') ||
      existingUrl == 'http://39.97.158.22/api') {
    await LocalStorage.setString('seahorse_server_url', ServerConfig.defaultRemoteUrl);
  }

  runApp(const SeahorseApp());
}

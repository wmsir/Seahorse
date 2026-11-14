import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';
import '../core/network/api_client.dart';

enum LocationSourceMode {
  realDevice('真实设备定位 (GPS / 基站 / Wi-Fi)'),
  simulationInStore('模拟场景: 距离店内 35米 (范围内)'),
  simulationNearStore('模拟场景: 门外走廊 120米 (范围内)'),
  simulationOutStore('模拟场景: 离店外勤 1,250米 (范围外)');

  final String label;
  const LocationSourceMode(this.label);
}

class LocationService {
  // 单例模式
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
  ));

  // 默认门店基准坐标 (西安高新旗舰店，支持通过后台动态更新)
  double storeLatitude = 34.265500;
  double storeLongitude = 108.953400;
  String storeName = '海马智慧商业 (西安高新旗舰店)';
  String storeAddress = '陕西省西安市高新区高新路海马商业中心1号店';
  double allowedRadiusMeters = 500.0;

  static const String _envAmapWebKey = String.fromEnvironment('SEAHORSE_AMAP_WEB_KEY');
  static const String _envAmapJsKey = String.fromEnvironment('SEAHORSE_AMAP_JS_KEY');
  static const String _envAmapSecurityCode = String.fromEnvironment('SEAHORSE_AMAP_SECURITY_CODE');

  // 高德地图开放平台服务配置 (优先读取编译期环境变量或由浏览器后台配置动态拉取)
  String? amapWebApiKey = _envAmapWebKey.isNotEmpty ? _envAmapWebKey : null;
  String? amapJsApiKey = _envAmapJsKey.isNotEmpty ? _envAmapJsKey : null;
  String? amapSecurityCode = _envAmapSecurityCode.isNotEmpty ? _envAmapSecurityCode : null;
  String? amapError;
  String? satelliteTimeoutPrompt;
  bool isAmapConfigLoaded = false;

  // 定位来源模式：默认使用真实设备定位！
  LocationSourceMode _sourceMode = LocationSourceMode.realDevice;
  LocationSourceMode get sourceMode => _sourceMode;

  String? _lastError;
  String? get lastError => _lastError;

  void setSourceMode(LocationSourceMode mode) {
    _sourceMode = mode;
  }

  /// 从后端拉取浏览器后台配置的高德地图与考勤设置（手机端无需手动配置，全自动无感生效）
  Future<void> syncAmapConfigFromBackend() async {
    try {
      final response = await ApiClient().dio.get('/config/amap');
      if (response.statusCode == 200 && response.data is Map) {
        final res = response.data;
        if (res['code'] == 200 && res['data'] != null) {
          final data = res['data'] as Map;
          if (data['webApiKey'] != null && data['webApiKey'].toString().trim().isNotEmpty) {
            amapWebApiKey = data['webApiKey'].toString().trim();
          }
          if (data['jsApiKey'] != null) {
            amapJsApiKey = data['jsApiKey'].toString().trim();
          }
          if (data['securityCode'] != null) {
            amapSecurityCode = data['securityCode'].toString().trim();
          }
          if (data['allowedRadiusMeters'] != null) {
            allowedRadiusMeters = (data['allowedRadiusMeters'] as num).toDouble();
          }
          if (data['storeLatitude'] != null) {
            storeLatitude = (data['storeLatitude'] as num).toDouble();
          }
          if (data['storeLongitude'] != null) {
            storeLongitude = (data['storeLongitude'] as num).toDouble();
          }
          if (data['storeAddress'] != null && data['storeAddress'].toString().isNotEmpty) {
            storeAddress = data['storeAddress'].toString();
          }
          if (data['storeName'] != null && data['storeName'].toString().isNotEmpty) {
            storeName = data['storeName'].toString();
          }
          isAmapConfigLoaded = true;
          amapError = null;
        }
      }
    } catch (e) {
      print('LocationService syncAmapConfigFromBackend: $e');
    }
  }

  /// 设置门店基准位置 (支持一键将当前位置设为打卡点)
  void setStoreLocation(double lat, double lon, String address, {String? name, double radius = 500.0}) {
    storeLatitude = lat;
    storeLongitude = lon;
    storeAddress = address;
    if (name != null) storeName = name;
    allowedRadiusMeters = radius;
  }

  /// 恢复默认西安旗舰店位置
  void resetDefaultStoreLocation() {
    storeLatitude = 34.265500;
    storeLongitude = 108.953400;
    storeName = '海马智慧商业 (西安高新旗舰店)';
    storeAddress = '陕西省西安市高新区高新路海马商业中心1号店';
    allowedRadiusMeters = 500.0;
  }

  /// 获取当前定位点 (真实物理定位优先，支持强制刷新去缓存)
  Future<LocationPoint> getCurrentLocation({bool forceRefresh = false}) async {
    _lastError = null;
    satelliteTimeoutPrompt = null;
    amapError = null;

    // 自动无感拉取后台最新高德配置
    if (!isAmapConfigLoaded || (forceRefresh && (amapWebApiKey == null || amapWebApiKey!.isEmpty))) {
      await syncAmapConfigFromBackend();
    }

    if (_sourceMode == LocationSourceMode.realDevice) {
      try {
        final realPoint = await _getRealDevicePosition(forceRefresh: forceRefresh);
        if (realPoint != null) {
          return realPoint;
        }
      } catch (e) {
        _lastError = e.toString();
        print('LocationService real device location failed: $e, falling back');
        rethrow;
      }
    }

    // 模拟场景获取
    return _getSimulatedLocation();
  }

  /// 调用 Android 原生底层定位服务获取高精度真实经纬度（强制直连硬件GPS，杜绝咸阳等IP误判与陈旧缓存）
  Future<LocationPoint?> _getRealDevicePosition({bool forceRefresh = false}) async {
    // 1. 检查手机是否开启了“位置信息/GPS”开关
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw '手机系统定位(GPS)服务未开启，请下拉手机通知栏开启“位置信息”';
    }

    // 2. 检查并申请定位授权
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw '未授予定位权限，请在弹出的系统对话框中允许获取位置信息';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw '定位权限已被永久禁用，请在手机设置->应用管理中开启位置权限';
    }

    // 3. 构造平台高精设置：强制启用 Android 原生 LocationManager (硬件芯片GPS优先，绕过Google服务)
    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 1),
        timeLimit: const Duration(seconds: 10),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );
    }

    // 4. 每次强制采集设备最新的真实物理坐标 (不使用旧缓存)
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      print('GPS hardware satellite acquisition timeout or error: $e');
    }

    // 5. 若实时探测未返回且非强制刷新，仅在缓存记录时间在60秒内时才允许读取，超过60秒坚决抛弃
    if (position == null && !forceRefresh) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final age = DateTime.now().difference(lastKnown.timestamp).inSeconds.abs();
          if (age < 60) {
            position = lastKnown;
          }
        }
      } catch (_) {}
    }

    // 6. 校验真实物理坐标 (杜绝通过高德公网 IP 改写经纬度导致误入咸阳)
    if (position != null) {
      satelliteTimeoutPrompt = null;
    } else {
      satelliteTimeoutPrompt = '卫星/基站硬件信号搜网中，请在室外或靠近窗户处重新点击【刷新GPS】';
      throw '未能获取到卫星物理实时GPS信号，请在开阔或靠近窗户处点击【重新获取GPS】';
    }

    // 7. 对获取到的物理经纬度进行逆地理编码（优先调用高德 Web API）
    String addressName = await _reverseGeocodeWithAmap(position.latitude, position.longitude);

    return LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      address: addressName,
      accuracy: position.accuracy,
    );
  }

  /// 逆地理编码：优先使用高德地图 Web API
  Future<String> _reverseGeocodeWithAmap(double lat, double lon) async {
    if (amapWebApiKey != null && amapWebApiKey!.isNotEmpty) {
      try {
        final res = await _dio.get(
          'https://restapi.amap.com/v3/geocode/regeo',
          queryParameters: {
            'key': amapWebApiKey,
            'location': '${lon.toStringAsFixed(6)},${lat.toStringAsFixed(6)}',
            'extensions': 'base',
          },
        );
        if (res.statusCode == 200 && res.data is Map) {
          final data = res.data as Map;
          if (data['status']?.toString() == '1' && data['regeocode'] != null) {
            final regeo = data['regeocode'] as Map;
            final formatted = regeo['formatted_address']?.toString();
            if (formatted != null && formatted.isNotEmpty && formatted != '[]') {
              return '$formatted (GPS: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
            }
          } else {
            final info = data['info']?.toString() ?? '';
            final infocode = data['infocode']?.toString() ?? '';
            if (infocode != '10009' && info.isNotEmpty && info != 'OK') {
              amapError = '高德地图服务提示: $info (错误码:$infocode)，请联系管理员在浏览器后台【系统设置】配置有效Key';
            }
          }
        }
      } catch (e) {
        print('Amap regeocode request error: $e');
      }
    }

    // 降级使用公共逆地理
    return _reverseGeocode(lat, lon);
  }

  /// 公共逆地理编码：将真实经纬度转为中文地址
  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://api.bigdatacloud.net/data/reverse-geocode-client',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'localityLanguage': 'zh',
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final prov = (data['principalSubdivision'] ?? '').toString();
        final city = (data['city'] ?? '').toString();
        final locality = (data['locality'] ?? '').toString();
        final street = locality != city ? locality : '';
        if (prov.isNotEmpty || city.isNotEmpty || locality.isNotEmpty) {
          final merged = '$prov$city${street.isNotEmpty ? ' $street' : ''}'.trim();
          return '$merged (GPS: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
        }
      }
    } catch (_) {}

    String regionName = _inferRegionByCoordinates(lat, lon);
    return '$regionName (GPS: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)})';
  }

  String _inferRegionByCoordinates(double lat, double lon) {
    if (lat >= 33.6 && lat <= 34.9 && lon >= 108.4 && lon <= 109.8) {
      return '陕西省西安市 雁塔/高新物理实测点';
    }
    if (lat >= 30.1 && lat <= 31.2 && lon >= 103.7 && lon <= 104.6) {
      return '四川省成都市 高新/武侯物理实测点';
    }
    if (lat >= 22.8 && lat <= 23.6 && lon >= 112.9 && lon <= 113.8) {
      return '广东省广州市 天河/越秀物理实测点';
    }
    if (lat >= 39.5 && lat <= 40.5 && lon >= 115.8 && lon <= 116.8) {
      return '北京市 朝阳/海淀物理实测点';
    }
    if (lat >= 30.8 && lat <= 31.6 && lon >= 121.0 && lon <= 121.9) {
      return '上海市 浦东/徐汇物理实测点';
    }
    return '当前设备物理实测点';
  }

  LocationPoint _getSimulatedLocation() {
    switch (_sourceMode) {
      case LocationSourceMode.simulationInStore:
        return LocationPoint(
          latitude: storeLatitude,
          longitude: storeLongitude,
          address: '$storeAddress (店内打卡点·模拟)',
          accuracy: 5.0,
        );
      case LocationSourceMode.simulationNearStore:
        return LocationPoint(
          latitude: storeLatitude + 0.0008,
          longitude: storeLongitude + 0.0008,
          address: '$storeName 门外走廊 120米 (模拟)',
          accuracy: 10.0,
        );
      case LocationSourceMode.simulationOutStore:
        return LocationPoint(
          latitude: storeLatitude + 0.0100,
          longitude: storeLongitude + 0.0100,
          address: '离店外勤 1,250米 (范围外模拟)',
          accuracy: 25.0,
        );
      case LocationSourceMode.realDevice:
        return LocationPoint(
          latitude: storeLatitude,
          longitude: storeLongitude,
          address: '$storeAddress (已降级门店基准点)',
          accuracy: 30.0,
        );
    }
  }

  /// 基于 Haversine 球面大圆距离公式计算米数
  double calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000.0; // 地球平均半径(米)
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);

  /// 判定是否在考勤打卡有效半径内
  bool isWithinAllowedRadius(double distanceMeters) {
    return distanceMeters <= allowedRadiusMeters;
  }

  /// 格式化距离文本
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} 米';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} 公里';
    }
  }
}

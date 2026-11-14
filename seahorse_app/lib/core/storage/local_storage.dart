import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _memoryCache = {};

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _memoryCache.clear();
    } catch (e) {
      // Fallback to memory cache for environments where native shared_prefs is initializing
      print('LocalStorage initialized with memory fallback: $e');
    }
  }

  static Future<bool> setString(String key, String value) async {
    _memoryCache[key] = value;
    if (_prefs != null) {
      return await _prefs!.setString(key, value);
    }
    return true;
  }

  static String? getString(String key) {
    if (_prefs != null && _prefs!.containsKey(key)) {
      return _prefs!.getString(key);
    }
    return _memoryCache[key] as String?;
  }

  static Future<bool> setBool(String key, bool value) async {
    _memoryCache[key] = value;
    if (_prefs != null) {
      return await _prefs!.setBool(key, value);
    }
    return true;
  }

  static bool? getBool(String key) {
    if (_prefs != null && _prefs!.containsKey(key)) {
      return _prefs!.getBool(key);
    }
    return _memoryCache[key] as bool?;
  }

  static Future<bool> remove(String key) async {
    _memoryCache.remove(key);
    if (_prefs != null) {
      return await _prefs!.remove(key);
    }
    return true;
  }

  static Future<bool> clear() async {
    _memoryCache.clear();
    if (_prefs != null) {
      return await _prefs!.clear();
    }
    return true;
  }
}

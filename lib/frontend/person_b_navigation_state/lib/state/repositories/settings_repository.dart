import 'package:shared_preferences/shared_preferences.dart';

/// Settings Repository — Persistent settings storage.
class SettingsRepository {
  /// Save setting to local storage
  Future<void> saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  /// Load setting from local storage
  Future<dynamic> loadSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key);
  }

  /// Load all settings
  Future<Map<String, dynamic>> loadAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> settings = {};
    for (String key in keys) {
      settings[key] = prefs.get(key);
    }
    return settings;
  }
}

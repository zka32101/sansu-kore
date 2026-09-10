/// Storage helpers for common SharedPreferences patterns
/// Reduces code duplication and provides consistent error handling

import 'package:shared_preferences/shared_preferences.dart';


/// Cached SharedPreferences instance
SharedPreferences? _cachedPrefs;

/// Get or initialize SharedPreferences instance
Future<SharedPreferences> getPrefs() async {
  _cachedPrefs ??= await SharedPreferences.getInstance();
  return _cachedPrefs!;
}

/// Helper class for common SharedPreferences operations
class StorageHelper {
  /// Get a string value, return null if not found
  static Future<String?> getString(String key) async {
    final prefs = await getPrefs();
    return prefs.getString(key);
  }

  /// Get a string value with default fallback
  static Future<String> getStringWithDefault(String key, String defaultValue) async {
    final prefs = await getPrefs();
    return prefs.getString(key) ?? defaultValue;
  }

  /// Set a string value
  static Future<bool> setString(String key, String value) async {
    final prefs = await getPrefs();
    return prefs.setString(key, value);
  }

  /// Get an int value, return null if not found
  static Future<int?> getInt(String key) async {
    final prefs = await getPrefs();
    return prefs.getInt(key);
  }

  /// Get an int value with default fallback
  static Future<int> getIntWithDefault(String key, int defaultValue) async {
    final prefs = await getPrefs();
    return prefs.getInt(key) ?? defaultValue;
  }

  /// Set an int value
  static Future<bool> setInt(String key, int value) async {
    final prefs = await getPrefs();
    return prefs.setInt(key, value);
  }

  /// Get a bool value, return null if not found
  static Future<bool?> getBool(String key) async {
    final prefs = await getPrefs();
    return prefs.getBool(key);
  }

  /// Get a bool value with default fallback
  static Future<bool> getBoolWithDefault(String key, bool defaultValue) async {
    final prefs = await getPrefs();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Set a bool value
  static Future<bool> setBool(String key, bool value) async {
    final prefs = await getPrefs();
    return prefs.setBool(key, value);
  }

  /// Remove a key from storage
  static Future<bool> remove(String key) async {
    final prefs = await getPrefs();
    return prefs.remove(key);
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    final prefs = await getPrefs();
    return prefs.containsKey(key);
  }

  /// Clear all stored data
  static Future<bool> clear() async {
    final prefs = await getPrefs();
    return prefs.clear();
  }

  /// Get all stored keys
  static Future<Set<String>> getAllKeys() async {
    final prefs = await getPrefs();
    return prefs.getKeys();
  }
}

import 'package:shared_preferences/shared_preferences.dart';

import 'package:darttonconnect/storage/interface.dart';

class DefaultStorage implements IStorage {
  final String storagePrefix = 'darttonconnect_';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  DefaultStorage();

  @override
  Future<void> setItem({
    required String key,
    required String value,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final String storageKey = _getStorageKey(key);
    prefs.setString(storageKey, value);
  }

  @override
  Future<String?> getItem({
    required String key,
    String? defaultValue,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final String storageKey = _getStorageKey(key);
    final String? result = prefs.getString(storageKey);
    if (result == null) {
      return defaultValue;
    }
    return result;
  }

  @override
  Future<void> removeItem({required String key}) async {
    final SharedPreferences prefs = await _prefs;
    final String storageKey = _getStorageKey(key);
    await prefs.remove(storageKey);
  }

  String _getStorageKey(String key) {
    return storagePrefix + key;
  }
}

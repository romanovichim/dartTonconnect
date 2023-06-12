import 'package:shared_preferences/shared_preferences.dart';

import 'package:darttonconnect/storage/interface.dart';

class DefaultStorage implements IStorage {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  DefaultStorage();

  @override
  Future<void> setItem({
    required String key,
    required String value,
  }) async {
    final SharedPreferences prefs = await _prefs;
    prefs.setString(key, value);
  }

  @override
  Future<String?> getItem({
    required String key,
    String? defaultValue,
  }) async {
    final SharedPreferences prefs = await _prefs;
    final String? result = prefs.getString(key);
    if (result == null) {
      return defaultValue;
    }
    return result;
  }

  @override
  Future<void> removeItem({required String key}) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(key);
  }
}

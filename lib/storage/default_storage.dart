import 'package:darttonconnect/storage/interface.dart';

class DefaultStorage implements IStorage {
  Map<String, String> cache;

  DefaultStorage() : cache = {};

  @override
  Future<void> setItem({
    required String key,
    required String value,
  }) async {
    cache[key] = value;
  }

  @override
  Future<String?> getItem({
    required String key,
    String? defaultValue,
  }) async {
    if (!cache.containsKey(key)) {
      return defaultValue;
    }

    return cache[key];
  }

  @override
  Future<void> removeItem({required String key}) async {
    cache.remove(key);
  }
}

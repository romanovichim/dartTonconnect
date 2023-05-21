abstract class IStorage {
  static const keyLastEventId = 'last_event_id';
  static const keyConnection = 'connection';

  Future<void> setItem({
    required String key,
    required String value,
  });

  Future<String?> getItem({
    required String key,
    String? defaultValue,
  });

  Future<void> removeItem({
    required String key,
  });
}

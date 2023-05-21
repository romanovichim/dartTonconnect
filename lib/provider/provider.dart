abstract class BaseProvider {
  Future<void> restoreConnection();

  void closeConnection();

  Future<void> disconnect();

  Future<Map<String, dynamic>> sendRequest(dynamic request);

  void listen(Function eventsCallback);
}

abstract class RpcParser {
  Map<String, dynamic> convertToRpcRequest(Map<String, dynamic> args);

  Map<String, dynamic> convertFromRpcResponse(Map<String, dynamic> rpcResponse);

  void parseAndThrowError(Map<String, dynamic> response);

  bool isError(Map<String, dynamic> response);
}

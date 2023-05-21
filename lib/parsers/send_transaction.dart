import 'dart:convert';

import 'package:darttonconnect/exceptions.dart';
import 'package:darttonconnect/parsers/rpc_parser.dart';

enum SendTransactionErrorCodes {
  unknownError,
  badRequestError,
  unknownAppError,
  userRejectsError,
  methodNotSupported,
}

Map<SendTransactionErrorCodes, Type> sendTransactionErrors = {
  SendTransactionErrorCodes.unknownError: UnknownError,
  SendTransactionErrorCodes.badRequestError: BadRequestError,
  SendTransactionErrorCodes.unknownAppError: UnknownAppError,
  SendTransactionErrorCodes.userRejectsError: UserRejectsError,
};

class SendTransactionErrors {
  static TonConnectError getError(
      SendTransactionErrorCodes errorCodes, String? message) {
    switch (errorCodes) {
      case SendTransactionErrorCodes.unknownError:
        return UnknownError(message);
      case SendTransactionErrorCodes.badRequestError:
        return BadRequestError(message);
      case SendTransactionErrorCodes.unknownAppError:
        return UnknownAppError(message);
      case SendTransactionErrorCodes.userRejectsError:
        return UserRejectsError(message);
      default:
        return UnknownError(message);
    }
  }
}

class SendTransactionParser extends RpcParser {
  SendTransactionParser() : super();

  @override
  Map<String, dynamic> convertToRpcRequest(Map<String, dynamic> args) {
    return {
      'method': 'sendTransaction',
      'params': [jsonEncode(args)],
    };
  }

  @override
  Map<String, dynamic> convertFromRpcResponse(
      Map<String, dynamic> rpcResponse) {
    return {
      'boc': rpcResponse['result'],
    };
  }

  @override
  void parseAndThrowError(Map<String, dynamic> response) {
    final message = response['error']?['message'];
    var code = response['error']?['code'];

    if (code == null && !SendTransactionErrorCodes.values.contains(code)) {
      code = SendTransactionErrorCodes.unknownError;
    }

    throw SendTransactionErrors.getError(code, message);
  }

  @override
  bool isError(Map<String, dynamic> response) {
    return response.containsKey('error');
  }
}

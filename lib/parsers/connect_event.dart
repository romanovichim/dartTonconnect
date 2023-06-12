import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:pinenacl/ed25519.dart';

import 'package:darttonconnect/exceptions.dart';
import 'package:darttonconnect/logger.dart';

enum ConnectEventErrorCodes {
  unknownError,
  badRequestError,
  mainfestNotFoundError,
  mainfestConnectError,
  unknownAppError,
  userRejectsError,
  methodNotSupported
}

class ConnectEventErrors {
  static TonConnectError getError(
      ConnectEventErrorCodes errorCodes, String? message) {
    switch (errorCodes) {
      case ConnectEventErrorCodes.unknownError:
        return UnknownError(message);
      case ConnectEventErrorCodes.badRequestError:
        return BadRequestError(message);
      case ConnectEventErrorCodes.mainfestNotFoundError:
        return ManifestNotFoundError(message);
      case ConnectEventErrorCodes.mainfestConnectError:
        return ManifestContentError(message);
      case ConnectEventErrorCodes.unknownAppError:
        return UnknownAppError(message);
      case ConnectEventErrorCodes.userRejectsError:
        return UserRejectsError(message);
      case ConnectEventErrorCodes.methodNotSupported:
        return ManifestContentError(message);
      default:
        return UnknownError(message);
    }
  }
}

enum CHAIN {
  mainnet('-239'),
  testnet('-3');

  const CHAIN(this.value);
  final String value;

  static CHAIN getChainByValue(String code) {
    return CHAIN.values.firstWhere((e) => e.value == code);
  }
}

class DeviceInfo {
  late String
      platform; // 'iphone' | 'ipad' | 'android' | 'windows' | 'mac' | 'linux' | 'browser'
  late String appName; // e.g. "Tonkeeper"
  late String appVersion; // e.g. "2.3.367"
  late int maxProtocolVersion;
  late List<dynamic> features;

  static DeviceInfo fromMap(Map<String, dynamic> device) {
    final deviceInfo = DeviceInfo();
    deviceInfo.platform = device['platform'];
    deviceInfo.appName = device['appName'];
    deviceInfo.appVersion = device['appVersion'];
    deviceInfo.maxProtocolVersion = device['maxProtocolVersion'];
    deviceInfo.features = device['features'];
    return deviceInfo;
  }
}

class Account {
  // User's address in "hex" format: "<wc>:<hex>"
  late String address;

  // User's selected chain
  late CHAIN chain;

  // Base64 (not url safe) encoded wallet contract state_init.
  // Can be used to get user's public key from the state_init if the wallet contract doesn't support corresponding method
  late String walletStateInit;

  // Hex string without 0x prefix
  late String publicKey;

  @override
  String toString() => '<Account "$address">';

  static Account fromMap(Map<String, dynamic> tonAddr) {
    if (!tonAddr.containsKey('address')) {
      throw TonConnectError('address not contains in ton_addr');
    }

    final account = Account();
    account.address = tonAddr['address'];
    account.chain = CHAIN.getChainByValue(tonAddr['network']);
    account.walletStateInit = tonAddr['walletStateInit'];
    account.publicKey =
        tonAddr.containsKey('publicKey') ? tonAddr['publicKey'] : null;
    return account;
  }
}

class TonProof {
  late int timestamp;
  late int domainLen;
  late String domainVal;
  late String payload;
  late SignatureBase signature;

  static TonProof fromMap(Map<String, dynamic> reply) {
    final proof = reply['proof'];
    if (proof == null) {
      throw TonConnectError('proof not contains in ton_proof');
    }
    final tonProof = TonProof();
    tonProof.timestamp = proof['timestamp'];
    tonProof.domainLen = proof['domain']['lengthBytes'];
    tonProof.domainVal = proof['domain']['value'];
    tonProof.payload = proof['payload'];

    final Uint8List signedMessage = base64Decode(proof['signature']);
    final SignatureBase signature =
        SignedMessage.fromList(signedMessage: signedMessage).signature;
    tonProof.signature = signature;
    return tonProof;
  }
}

class WalletInfo {
  // Information about user's wallet's device
  DeviceInfo? device;

  // Provider type
  String provider = 'http'; // only http supported

  // Selected account
  Account? account;

  // Response for ton_proof item request
  TonProof? tonProof;

  WalletInfo();

  @override
  String toString() {
    return '<WalletInfo ${account.toString()}>';
  }

  bool checkProof({String? srcpayload}) {
    if (tonProof == null) {
      return false;
    }

    var wcWhash = account!.address.split(':')[2];
    var wc = int.parse(wcWhash[0]);
    var whash = wcWhash[1];

    Uint8List message = Uint8List(0);
    message.addAll(utf8.encode('ton-proof-item-v2/'));
    message.addAll(_intToBytes(wc, Endian.little));
    message.addAll(HEX.decode(whash));
    message.addAll(_intToBytes(tonProof!.domainLen, Endian.little));
    message.addAll(utf8.encode(tonProof!.domainVal));
    message.addAll(_intToBytes(tonProof!.timestamp, Endian.little));
    if (srcpayload != null) {
      message.addAll(utf8.encode(srcpayload));
    } else {
      message.addAll(utf8.encode(tonProof!.payload));
    }

    var signatureMessage = Uint8List(0);
    signatureMessage.addAll(HEX.decode('ffff'));
    signatureMessage.addAll(utf8.encode('ton-connect'));
    signatureMessage.addAll(sha256.convert(message).bytes);

    try {
      var verifyKey =
          VerifyKey(Uint8List.fromList(utf8.encode(account!.publicKey)));
      verifyKey.verify(
          message: Uint8List.fromList(sha256.convert(signatureMessage).bytes),
          signature: tonProof!.signature);
      logger.d('PROOF IS OK');
      return true;
    } catch (e) {
      logger.e('PROOF ERROR');
      return false;
    }
  }

  Uint8List _intToBytes(int value, Endian endian) {
    Uint8List bytes = Uint8List(4);
    ByteData byteData = ByteData.view(bytes.buffer);
    byteData.setInt32(0, value, endian);
    return bytes;
  }
}

class ConnectEventParser {
  static WalletInfo parseResponse(Map<String, dynamic> payload) {
    if (!payload.containsKey('items')) {
      throw TonConnectError('items not contains in payload');
    }

    final wallet = WalletInfo();

    for (final item in payload['items']) {
      if (item.containsKey('name')) {
        if (item['name'] == 'ton_addr') {
          wallet.account = Account.fromMap(item);
        } else if (item['name'] == 'ton_proof') {
          wallet.tonProof = TonProof.fromMap(item);
        }
      }
    }

    if (wallet.account == null) {
      throw TonConnectError('ton_addr not contains in items');
    }

    wallet.device = DeviceInfo.fromMap(payload['device']);

    return wallet;
  }

  static TonConnectError parseError(Map<String, dynamic> payload) {
    final message = payload['error']?['message'];
    var code = payload['error']?['code'];

    if (code == null || ConnectEventErrorCodes.values.contains(code)) {
      code = ConnectEventErrorCodes.unknownError;
    }
    return ConnectEventErrors.getError(code, message);
  }
}

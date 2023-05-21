import 'dart:convert';

import 'package:darttonconnect/crypto/session_crypto.dart';

class BridgeSession {
  late SessionCrypto sessionCrypto;
  String? walletPublicKey;
  String? bridgeUrl;

  BridgeSession({Map<String, dynamic>? stored}) {
    sessionCrypto = stored != null && stored.containsKey('session_private_key')
        ? SessionCrypto(pk: stored['session_private_key'])
        : SessionCrypto();
    walletPublicKey = stored?['wallet_public_key'];
    bridgeUrl = stored?['bridge_url'];
  }

  @override
  String toString() {
    return json.encode(getMap());
  }

  Map<String, dynamic> getMap() {
    return {
      'session_private_key': sessionCrypto.privateKey.encode(),
      'wallet_public_key': walletPublicKey,
      'bridge_url': bridgeUrl
    };
  }
}

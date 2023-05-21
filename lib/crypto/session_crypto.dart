import 'dart:convert';

import 'package:pinenacl/x25519.dart'
    show Box, PrivateKey, EncryptedMessage, PublicKey;
import 'package:pinenacl/api.dart';

class SessionCrypto {
  late final PrivateKey privateKey;
  late final String sessionId;

  SessionCrypto({String? pk}) {
    privateKey = pk != null
        ? PrivateKey(Uint8List.fromList(pk.codeUnits))
        : PrivateKey.generate();

    sessionId = privateKey.publicKey.encode().toLowerCase();
  }

  String encrypt(String message, String receiverPubKeyHex) {
    final receiverPk = PublicKey.decode(receiverPubKeyHex);
    final box = Box(myPrivateKey: privateKey, theirPublicKey: receiverPk);
    final encrypted = box.encrypt(Uint8List.fromList(utf8.encode(message)));

    return utf8.decode(encrypted);
  }

  String decrypt(String message, String senderPubKeyHex) {
    final Uint8List msg = base64.decode(message);

    final senderPk = PublicKey.decode(senderPubKeyHex);
    final box = Box(myPrivateKey: privateKey, theirPublicKey: senderPk);

    final decrypted = box.decrypt(EncryptedMessage.fromList(msg));
    return utf8.decode(decrypted);
  }
}

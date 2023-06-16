# Dart SDK for TON Connect

Dart SDK for TON Connect 2.0

Analogue of the [@tonconnect/sdk](https://github.com/ton-connect/sdk/tree/main/packages/sdk) library.

Use it to connect your app to TON wallets via TonConnect protocol. You can find more details and the protocol specification in the [docs](https://github.com/ton-connect/docs).

## TonConnect overview

TON Connect 2.0 is a communication protocol between wallets and apps in TON. Using TonConnect allows you to create authorization for applications, as well as send transactions within applications, confirming them using wallets integrated with TonConnect.

[Overview](https://docs.ton.org/develop/dapps/ton-connect/) in the TON documentation, a simple [example](https://docs.ton.org/develop/dapps/ton-connect/integration) of using TON Connect.

This SDK for Dart will allow you to use Ton Connect for cross-platform applications on [Flutter](https://flutter.dev/).

## Protocol specifications

If you implement an SDK, a wallet or want to learn more how Ton Connect works, please read below.

* [Protocol workflow](workflows.md): an overview of all the protocols.
* [Bridge API](bridge.md) specifies how the data is transmitted between the app and the wallet.
* [Session protocol](session.md) ensures end-to-end encrypted communication over the bridge.
* [Requests protocol](requests-responses.md) defines requests and responses for the app and the wallet.
* [Wallet guidelines](wallet-guidelines.md) defines guidelines for wallet developers.


## Tutorials

[ENG](https://dev.to/roma_i_m/how-to-authorize-the-ton-blockchain-on-dart-using-a-wallet-via-ton-connect-edo) | [RU](https://habr.com/ru/articles/742036/) 

# Installation

##### Run this command:

With Dart:

	 $ dart pub add darttonconnect
This will add a line like this to your package's pubspec.yaml (and run an implicit `dart pub get`):

	dependencies:
	  darttonconnect: ^1.0.1
Alternatively, your editor might support `dart pub get`. Check the docs for your editor to learn more.

##### Import it
Now in your Dart code, you can use:

	import 'package:darttonconnect/crypto/session_crypto.dart';
	import 'package:darttonconnect/exceptions.dart';
	import 'package:darttonconnect/logger.dart';
	import 'package:darttonconnect/parsers/connect_event.dart';
	import 'package:darttonconnect/parsers/rpc_parser.dart';
	import 'package:darttonconnect/parsers/send_transaction.dart';
	import 'package:darttonconnect/provider/bridge_gateway.dart';
	import 'package:darttonconnect/provider/bridge_provider.dart';
	import 'package:darttonconnect/provider/bridge_session.dart';
	import 'package:darttonconnect/provider/provider.dart';
	import 'package:darttonconnect/storage/default_storage.dart';
	import 'package:darttonconnect/storage/interface.dart';
	import 'package:darttonconnect/ton_connect.dart';
	import 'package:darttonconnect/wallets_list_manager.dart';

# Examples
## Add the tonconnect-manifest

App needs to have its manifest to pass meta information to the wallet. Manifest is a JSON file named as `tonconnect-manifest.json` following format:

```json
{
  "url": "<app-url>",                        // required
  "name": "<app-name>",                      // required
  "iconUrl": "<app-icon-url>",               // required
  "termsOfUseUrl": "<terms-of-use-url>",     // optional
  "privacyPolicyUrl": "<privacy-policy-url>" // optional
}
```

Make sure that manifest is available to GET by its URL.

## Init connector and call `restore_connection`.

If user connected his wallet before, connector will restore the connection

```
import 'package:darttonconnect/ton_connect.dart';

Future<void> main() async {
  final connector = TonConnect('https://raw.githubusercontent.com/XaBbl4/pytonconnect/main/pytonconnect-manifest.json');
  final bool isConnected = await connector.restoreConnection();
  print('isConnected: $isConnected');
}
```

## Fetch wallets list

You can fetch all supported wallets list

```
import 'package:darttonconnect/ton_connect.dart';

Future<void> main() async {
  final connector = TonConnect('https://raw.githubusercontent.com/XaBbl4/pytonconnect/main/pytonconnect-manifest.json');
  final List wallets = await connector.getWallets();
  print('Wallets: $wallets');
}
```

## Subscribe to the connection status changes

```
/// Update state/reactive variables to show updates in the ui.
void statusChanged(dynamic walletInfo) {
  print('Wallet info: $ walletInfo');
}

connector.onStatusChange(statusChanged);
```

## Initialize a wallet connection via universal link

```
import 'package:darttonconnect/ton_connect.dart';

final generatedUrl = await connector.connect(wallets.first);
print('Generated url: $generatedUrl');
}
```

Then you have to show this link to user as QR-code, or use it as a deep_link. You will receive an update in console when user approves connection in the wallet.

## Send transaction

```
const transaction = {
  "validUntil": 1718097354,
  "messages": [
    {
      "address":
          "0:575af9fc97311a11f423a1926e7fa17a93565babfd65fe39d2e58b8ccb38c911",
      "amount": "20000000",
    }
  ]
};

try {
  await connector.sendTransaction(transaction);
} catch (e) {
  if (e is UserRejectsError) {
    logger.d(
        'You rejected the transaction. Please confirm it to send to the blockchain');
  } else {
    logger.d('Unknown error happened $e');
  }
}
```

## Disconnect

```
connector.disconnect();
```



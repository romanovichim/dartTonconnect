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

ENG | RU TBD

# Installation

TBD

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

TBD

## Fetch wallets list

You can fetch all supported wallets list

TBD

## Subscribe to the connection status changes

TBD

## Initialize a wallet connection via universal link

TBD

Then you have to show this link to user as QR-code, or use it as a deep_link. You will receive an update in `TBD` when user approves connection in the wallet.

## Send transaction

TBD

## Disconnect

TBD



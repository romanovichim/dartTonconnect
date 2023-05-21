import 'dart:convert';
import 'package:darttonconnect/exceptions.dart';
import 'package:http/http.dart' as http;

const fallbackWalletsList = [
  {
    "name": "Tonkeeper",
    "image": "https://tonkeeper.com/assets/tonconnect-icon.png",
    "tondns": "tonkeeper.ton",
    "about_url": "https://tonkeeper.com",
    "universal_url": "https://app.tonkeeper.com/ton-connect",
    "bridge": [
      {"type": "sse", "url": "https://bridge.tonapi.io/bridge"},
      {"type": "js", "key": "tonkeeper"}
    ]
  },
  {
    "name": "Tonhub",
    "image": "https://tonhub.com/tonconnect_logo.png",
    "about_url": "https://tonhub.com",
    "universal_url": "https://tonhub.com/ton-connect",
    "bridge": [
      {"type": "js", "key": "tonhub"},
      {"type": "sse", "url": "https://connect.tonhubapi.com/tonconnect"}
    ]
  }
];

class WalletsListManager {
  String _walletsListSource =
      'https://raw.githubusercontent.com/ton-blockchain/wallets-list/main/wallets.json';
  final int? _cacheTtl;

  dynamic _dynamicWalletsListCache;
  List<Map<String, dynamic>> walletsListCache = [];
  int? _walletsListCacheCreationTimestamp;

  WalletsListManager({String? walletsListSource, int? cacheTtl})
      : _cacheTtl = cacheTtl {
    if (walletsListSource != null) {
      _walletsListSource = walletsListSource;
    }
  }

  Future<List<Map<String, dynamic>>> getWallets() async {
    final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_cacheTtl != null &&
        _walletsListCacheCreationTimestamp != null &&
        currentTimestamp > _walletsListCacheCreationTimestamp! + _cacheTtl!) {
      _dynamicWalletsListCache = null;
    }

    if (_dynamicWalletsListCache == null) {
      List<Map<String, dynamic>> walletsList = [];
      try {
        final response = await http.get(Uri.parse(_walletsListSource));
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody is List) {
            walletsList = responseBody.cast<Map<String, dynamic>>();
          } else {
            throw FetchWalletsError(
                'Wrong wallets list format, wallets list must be an array.');
          }
        } else {
          throw FetchWalletsError('Failed to fetch wallets list.');
        }
      } catch (e) {
        walletsList = fallbackWalletsList;
      }

      walletsListCache = [];
      for (final wallet in walletsList) {
        final supportedWallet = _getSupportedWalletConfig(wallet);
        if (supportedWallet != null) {
          walletsListCache.add(supportedWallet);
        }
      }

      _walletsListCacheCreationTimestamp = currentTimestamp;
    }

    return walletsListCache;
  }

  Map<String, dynamic>? _getSupportedWalletConfig(dynamic wallet) {
    if (wallet is! Map<String, dynamic>) {
      return null;
    }

    final containsName = wallet.containsKey('name');
    final containsImage = wallet.containsKey('image');
    final containsAbout = wallet.containsKey('about_url');

    if (!containsName || !containsImage || !containsAbout) {
      return null;
    }

    if (!wallet.containsKey('bridge') ||
        wallet['bridge'] is! List ||
        (wallet['bridge'] as List).isEmpty) {
      return null;
    }

    final bridgeList = wallet['bridge'] as List;
    final sseBridge = bridgeList.firstWhere((bridge) => bridge['type'] == 'sse',
        orElse: () => null);
    if (sseBridge == null || !sseBridge.containsKey('url')) {
      return null;
    }

    final walletConfig = <String, dynamic>{
      'name': wallet['name'],
      'image': wallet['image'],
      'about_url': wallet['about_url'],
      'bridge_url': sseBridge['url'],
    };

    if (wallet.containsKey('universal_url')) {
      walletConfig['universal_url'] = wallet['universal_url'];
    }

    return walletConfig;
  }
}

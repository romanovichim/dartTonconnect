class WalletApp {
  final String name;
  final String bridgeUrl;
  final String image;
  final String? universalUrl;
  final String aboutUrl;

  const WalletApp({
    required this.name,
    required this.bridgeUrl,
    required this.image,
    required this.aboutUrl,
    this.universalUrl,
  });

  factory WalletApp.fromMap(Map<String, dynamic> json) {
   String bridgeUrl = json.containsKey('bridge_url') ?
        json['bridge_url'].toString() :
        (json.containsKey('bridge')
            ? (json['bridge'] as List).firstWhere(
                (bridge) => bridge['type'] == 'sse',
                orElse: () => '')['url'].toString()
            : '');

    return WalletApp(
      name: json['name'].toString(),
      image: json['image'].toString(),
      bridgeUrl: bridgeUrl,
      aboutUrl: json['about_url'].toString(),
      universalUrl: json.containsKey('universal_url')
          ? json['universal_url'].toString()
          : null,
    );
  }
}

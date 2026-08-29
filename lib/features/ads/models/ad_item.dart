/// Une annonce publicitaire locale (annonceurs mauritaniens démarchés
/// directement par Khatam — voir `khatam-backend/src/routes/ads.js`,
/// `GET /api/ads/list`). Différent de Google AdSense (géré entièrement côté
/// Google, aucune donnée transitant par ce modèle).
class AdItem {
  final String id;
  final String advertiserName;

  /// URL absolue (préfixée avec la racine du serveur), ou `null` si
  /// l'annonce n'a pas d'image (auquel cas [AdCarousel] affiche un bandeau
  /// de secours avec juste le nom de l'annonceur).
  final String? imageUrl;

  final String? targetUrl;

  AdItem({
    required this.id,
    required this.advertiserName,
    required this.imageUrl,
    required this.targetUrl,
  });

  /// [apiOrigin] est la racine du serveur (ex.
  /// `https://khatam-backend-i6zn.onrender.com`, SANS le `/api` final) — le
  /// backend renvoie `imageUrl` en chemin relatif (`/uploads/ads/xxx.jpg`),
  /// même patron que `DocumentItem.previewUrl`.
  factory AdItem.fromJson(Map<String, dynamic> json, {required String apiOrigin}) {
    final rawImage = json['imageUrl'] as String?;
    String? absolute(String? relative) {
      if (relative == null || relative.isEmpty) return null;
      if (relative.startsWith('http://') || relative.startsWith('https://')) return relative;
      return '$apiOrigin$relative';
    }

    return AdItem(
      id: json['id'] as String? ?? '',
      advertiserName: json['advertiserName'] as String? ?? 'Annonce',
      imageUrl: absolute(rawImage),
      targetUrl: json['targetUrl'] as String?,
    );
  }
}

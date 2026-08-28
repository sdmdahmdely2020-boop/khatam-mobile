/// Document favori tel que renvoyé par `GET /api/favorites` — **attention**,
/// contrairement à `GET /api/documents`, cette route renvoie les colonnes
/// BRUTES de la table `documents` (`SELECT d.* FROM favorites f JOIN
/// documents d ...`), PAS la forme enrichie `toPublicDoc()` : pas de
/// `previewUrl`, pas de `professor`, pas de `unlocked`. D'où ce modèle
/// séparé, plus tolérant, plutôt que de réutiliser [DocumentItem] tel quel.
class FavoriteDocument {
  final String id;
  final String title;
  final String matiere;
  final String serie;
  final int annee;
  final String type;
  final num prix;
  final bool free;

  /// Construite manuellement à partir de l'id (le champ n'existe pas dans
  /// cette réponse) — la route `/api/documents/:id/preview` est un chemin
  /// fixe et public, donc fiable à reconstituer côté client.
  final String previewUrl;

  FavoriteDocument({
    required this.id,
    required this.title,
    required this.matiere,
    required this.serie,
    required this.annee,
    required this.type,
    required this.prix,
    required this.free,
    required this.previewUrl,
  });

  factory FavoriteDocument.fromJson(Map<String, dynamic> json, {required String apiOrigin}) {
    final id = json['id'] as String? ?? '';
    return FavoriteDocument(
      id: id,
      title: json['title'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      serie: json['serie'] as String? ?? '',
      annee: (json['annee'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      prix: (json['prix'] as num?) ?? 0,
      free: json['free'] as bool? ?? false,
      previewUrl: id.isEmpty ? '' : '$apiOrigin/api/documents/$id/preview',
    );
  }

  String get priceLabel => free ? 'Gratuit' : '${prix.toStringAsFixed(0)} MRU';
}

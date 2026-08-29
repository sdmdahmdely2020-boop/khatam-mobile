/// Représente un document du catalogue tel que renvoyé par
/// `GET /api/documents` ou `GET /api/documents/:id` (voir
/// `khatam-backend/src/routes/documents.js`, fonction `toPublicDoc`).
class DocumentItem {
  final String id;
  final String title;
  final String matiere;
  final String serie;
  final int annee;
  final String type;
  final num prix;

  /// Prix réellement affiché à CET élève, après réduction d'abonnement Basic
  /// éventuelle (voir `khatam-backend/src/routes/documents.js`,
  /// `effectivePriceFor()` — modèle hybride du 29/08). Égal à [prix] pour
  /// tout le monde d'autre (gratuit, non connecté, Free, Premium). [prix]
  /// lui-même n'est JAMAIS modifié par cette réduction — c'est le prix "de
  /// base" affiché au site web, qui ne connaît pas les abonnements.
  final num effectivePrix;

  /// true si [effectivePrix] < [prix] pour cet élève (abonné Basic actif).
  final bool subscriptionDiscountApplied;

  final bool free;
  final bool adUnlock;
  final bool aiGrading;
  final int views;
  final bool unlocked;
  final bool professorBoosted;
  final int professorLikes;

  /// 'publie' | 'brouillon' — un professeur voit ses propres brouillons dans
  /// cette même liste (voir `GET /api/documents` côté serveur), les élèves
  /// ne voient jamais que des documents publiés.
  final String statut;

  /// URL absolue (préfixée avec la racine du serveur) — prête pour
  /// `Image.network` directement.
  final String previewUrl;

  final String professorId;
  final String professorFullName;
  final String? professorMatieres;
  final String? professorPhotoUrl;

  DocumentItem({
    required this.id,
    required this.title,
    required this.matiere,
    required this.serie,
    required this.annee,
    required this.type,
    required this.prix,
    required this.effectivePrix,
    required this.subscriptionDiscountApplied,
    required this.free,
    required this.adUnlock,
    required this.aiGrading,
    required this.views,
    required this.unlocked,
    required this.professorBoosted,
    required this.professorLikes,
    required this.statut,
    required this.previewUrl,
    required this.professorId,
    required this.professorFullName,
    this.professorMatieres,
    this.professorPhotoUrl,
  });

  /// [apiOrigin] est la racine du serveur (ex. `https://khatam-backend-i6zn.onrender.com`,
  /// SANS le `/api` final) — le backend renvoie des chemins relatifs
  /// (`/api/documents/xxx/preview`, `/uploads/photos/xxx.jpg`) qu'il faut
  /// préfixer pour obtenir une URL utilisable par l'app.
  factory DocumentItem.fromJson(Map<String, dynamic> json, {required String apiOrigin}) {
    final professor = (json['professor'] as Map<String, dynamic>?) ?? const {};
    final rawPreview = json['previewUrl'] as String? ?? '';
    final rawPhoto = professor['photoUrl'] as String?;

    String? absolute(String? relative) {
      if (relative == null || relative.isEmpty) return null;
      if (relative.startsWith('http://') || relative.startsWith('https://')) return relative;
      return '$apiOrigin$relative';
    }

    return DocumentItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      matiere: json['matiere'] as String? ?? '',
      serie: json['serie'] as String? ?? '',
      annee: (json['annee'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      prix: (json['prix'] as num?) ?? 0,
      // effectivePrix/subscriptionDiscountApplied n'existent que depuis le
      // 29/08 (modèle hybride) — repli sur le prix normal si absents (ex.
      // réponse mise en cache d'avant cette date), jamais d'erreur.
      effectivePrix: (json['effectivePrix'] as num?) ?? (json['prix'] as num?) ?? 0,
      subscriptionDiscountApplied: json['subscriptionDiscountApplied'] as bool? ?? false,
      free: json['free'] as bool? ?? false,
      adUnlock: json['adUnlock'] as bool? ?? false,
      aiGrading: json['aiGrading'] as bool? ?? false,
      views: (json['views'] as num?)?.toInt() ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      professorBoosted: json['professorBoosted'] as bool? ?? false,
      professorLikes: (json['professorLikes'] as num?)?.toInt() ?? 0,
      statut: json['statut'] as String? ?? 'brouillon',
      previewUrl: absolute(rawPreview) ?? '',
      professorId: professor['id'] as String? ?? '',
      professorFullName: professor['fullName'] as String? ?? 'Professeur',
      professorMatieres: professor['matieres'] as String?,
      professorPhotoUrl: absolute(rawPhoto),
    );
  }

  /// Libellé lisible pour le type de document (`sujet`, `corrige`, ...).
  String get typeLabel {
    switch (type) {
      case 'sujet':
        return 'Sujet';
      case 'corrige':
        return 'Corrigé';
      case 'cours':
        return 'Cours';
      case 'exercices':
        return 'Exercices';
      case 'video':
        return 'Vidéo';
      case 'blanc':
        return 'Examen blanc';
      default:
        return type;
    }
  }

  /// Libellé prix pour affichage : "Gratuit" ou "XXX MRU".
  String get priceLabel => free ? 'Gratuit' : '${prix.toStringAsFixed(0)} MRU';

  /// Libellé du prix réduit (abonné Basic) — n'a de sens que si
  /// [subscriptionDiscountApplied] est vrai ; sinon identique à [priceLabel].
  String get effectivePriceLabel =>
      free ? 'Gratuit' : '${effectivePrix.toStringAsFixed(0)} MRU';

  bool get isPublished => statut == 'publie';
}

import '../../catalog/models/document_item.dart';

/// Une ligne de `GET /api/documents/mine` (profil élève, 29/08) : un document
/// que l'élève a réellement débloqué par une action concrète (achat confirmé
/// ou publicité vue) — voir `khatam-backend/src/routes/documents.js`,
/// route `GET /documents/mine`.
///
/// Volontairement DIFFÉRENT de "tous les documents accessibles" pour un
/// abonné Premium (qui couvrirait alors tout le catalogue publié) : cette
/// liste ne montre que ce que l'élève a explicitement acheté ou débloqué par
/// pub, jamais gonflée artificiellement par un abonnement — voir
/// [StudentProgress.isPremium] pour l'expliquer séparément à l'écran.
class MyDocumentEntry {
  final DocumentItem document;

  /// 'purchase' | 'ad'.
  final String acquiredVia;
  final DateTime? acquiredAt;
  final num amountPaid;
  final String? method;

  MyDocumentEntry({
    required this.document,
    required this.acquiredVia,
    required this.acquiredAt,
    required this.amountPaid,
    this.method,
  });

  bool get isPurchase => acquiredVia == 'purchase';
  bool get isAdUnlock => acquiredVia == 'ad';

  factory MyDocumentEntry.fromJson(Map<String, dynamic> json, {required String apiOrigin}) {
    final rawAcquiredAt = json['acquiredAt'] as String?;
    return MyDocumentEntry(
      document: DocumentItem.fromJson(json, apiOrigin: apiOrigin),
      acquiredVia: json['acquiredVia'] as String? ?? 'purchase',
      acquiredAt: rawAcquiredAt == null ? null : DateTime.tryParse(rawAcquiredAt),
      amountPaid: (json['amountPaid'] as num?) ?? 0,
      method: json['method'] as String?,
    );
  }
}

/// "Progression simple" — voir `progress` dans la réponse de
/// `GET /api/documents/mine`. Purement informatif/motivationnel, pas un
/// système de points/niveaux — juste un résumé de l'activité de l'élève.
class StudentProgress {
  final int totalUnlocked;
  final num totalSpentMru;

  /// matière -> nombre de documents débloqués dans cette matière.
  final Map<String, int> byMatiere;
  final DateTime? memberSince;
  final bool isPremium;
  final bool isBasic;

  StudentProgress({
    required this.totalUnlocked,
    required this.totalSpentMru,
    required this.byMatiere,
    required this.memberSince,
    required this.isPremium,
    required this.isBasic,
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    final rawByMatiere = (json['byMatiere'] as Map<String, dynamic>?) ?? const {};
    final rawMemberSince = json['memberSince'] as String?;
    return StudentProgress(
      totalUnlocked: (json['totalUnlocked'] as num?)?.toInt() ?? 0,
      totalSpentMru: (json['totalSpentMru'] as num?) ?? 0,
      byMatiere: rawByMatiere.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      memberSince: rawMemberSince == null ? null : DateTime.tryParse(rawMemberSince),
      isPremium: json['isPremium'] as bool? ?? false,
      isBasic: json['isBasic'] as bool? ?? false,
    );
  }

  static StudentProgress empty() => StudentProgress(
        totalUnlocked: 0,
        totalSpentMru: 0,
        byMatiere: const {},
        memberSince: null,
        isPremium: false,
        isBasic: false,
      );
}

/// Réponse complète de `GET /api/documents/mine`.
class MyDocumentsResult {
  final List<MyDocumentEntry> entries;
  final StudentProgress progress;

  MyDocumentsResult({required this.entries, required this.progress});
}

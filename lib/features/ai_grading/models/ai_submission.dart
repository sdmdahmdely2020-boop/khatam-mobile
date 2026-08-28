/// Résultat d'une correction IA d'une copie élève, tel que renvoyé par
/// `POST /api/documents/:id/ai-grade` (juste après la correction) ou par
/// `GET /api/ai/history` (historique complet — voir
/// `khatam-backend/src/routes/ai.js`).
///
/// Note toujours sur 20, avec un chiffre après la virgule (voir le prompt
/// exact dans `khatam-backend/src/lib/aiGrading.js`).
class AiSubmission {
  final String id;
  final num? note;
  final String? feedback;
  final List<String> strengths;
  final List<String> weaknesses;
  final String status;

  /// Champs présents seulement dans l'historique (`GET /api/ai/history`) —
  /// absents juste après une correction, puisque la requête était déjà pour
  /// ce document précis.
  final String? documentId;
  final String? documentTitle;
  final bool hasFile;
  final String? createdAt;

  AiSubmission({
    required this.id,
    required this.note,
    required this.feedback,
    required this.strengths,
    required this.weaknesses,
    required this.status,
    this.documentId,
    this.documentTitle,
    this.hasFile = false,
    this.createdAt,
  });

  /// Depuis la réponse immédiate de `POST /api/documents/:id/ai-grade`
  /// (clé `submission`).
  factory AiSubmission.fromGradeJson(Map<String, dynamic> json) {
    return AiSubmission(
      id: json['id'] as String? ?? '',
      note: json['note'] as num?,
      feedback: json['feedback'] as String?,
      strengths: ((json['strengths'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      weaknesses: ((json['weaknesses'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: json['status'] as String? ?? 'graded',
    );
  }

  /// Depuis une entrée de `GET /api/ai/history` (chaque ligne = colonnes SQL
  /// brutes + `title` du document joint + `hasFile`/`strengths`/`weaknesses`
  /// déjà recalculés côté serveur).
  factory AiSubmission.fromHistoryJson(Map<String, dynamic> json) {
    return AiSubmission(
      id: json['id'] as String? ?? '',
      note: json['note'] as num?,
      feedback: json['feedback'] as String?,
      strengths: ((json['strengths'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      weaknesses: ((json['weaknesses'] as List<dynamic>?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: json['status'] as String? ?? 'graded',
      documentId: json['documentId'] as String?,
      documentTitle: json['title'] as String?,
      hasFile: json['hasFile'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );
  }

  String get noteLabel => note == null ? '—' : '${note!.toStringAsFixed(1)}/20';
}

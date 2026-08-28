import '../../../core/api/api_client.dart';
import '../models/ai_submission.dart';

/// Correction IA côté élève — contrat vérifié dans
/// `khatam-backend/src/routes/ai.js`. Suppose que [ApiClient.baseUrl] pointe
/// déjà sur la racine `/api` (comme partout ailleurs dans l'app) : les
/// chemins ci-dessous (`/documents/:id/ai-grade`, `/ai/history`,
/// `/ai/status`) sont donc relatifs à `/api`, exactement comme montés dans
/// `khatam-backend/src/app.js` (`app.use('/api', aiRoutes)`).
class AiGradingService {
  final ApiClient apiClient;

  AiGradingService({required this.apiClient});

  /// `GET /api/ai/status` — public, pas besoin d'être connecté. Permet
  /// d'afficher un message clair si l'administrateur n'a pas encore activé
  /// la clé API plutôt que de laisser l'élève tomber sur une erreur au
  /// moment d'envoyer sa copie.
  Future<bool> fetchStatus() async {
    final data = await apiClient.get('/ai/status', withAuth: false);
    return data['configured'] as bool? ?? false;
  }

  /// Envoi d'une copie sous forme de photo ou de PDF. [mimeType] doit être
  /// l'un de : image/jpeg, image/png, image/webp, application/pdf (voir
  /// `khatam-backend/src/lib/submissionUpload.js` — le HEIC des iPhone est
  /// refusé par le serveur, d'où la conversion forcée en JPEG côté appel de
  /// cette méthode).
  Future<AiSubmission> submitFile({
    required String documentId,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final data = await apiClient.multipartPost(
      '/documents/$documentId/ai-grade',
      const {},
      fileBytes: fileBytes,
      fileName: fileName,
      fileField: 'answerFile',
      fileMimeType: mimeType,
    );
    return AiSubmission.fromGradeJson(data['submission'] as Map<String, dynamic>);
  }

  /// Solution de repli : réponse tapée directement (minimum 10 caractères
  /// côté serveur, sinon `ANSWER_TOO_SHORT`).
  Future<AiSubmission> submitText({
    required String documentId,
    required String answerText,
  }) async {
    final data = await apiClient.post('/documents/$documentId/ai-grade', {
      'answerText': answerText,
    });
    return AiSubmission.fromGradeJson(data['submission'] as Map<String, dynamic>);
  }

  /// `GET /api/ai/history` — historique complet de l'élève connecté, plus
  /// récent en premier.
  Future<List<AiSubmission>> fetchHistory() async {
    final data = await apiClient.get('/ai/history');
    final list = (data['submissions'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return list.map(AiSubmission.fromHistoryJson).toList();
  }
}

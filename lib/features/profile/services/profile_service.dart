import '../../../core/api/api_client.dart';
import '../models/my_document_entry.dart';

/// Profil élève (29/08) — documents déjà débloqués (achat ou publicité) +
/// progression simple. Un seul appel réseau (`GET /api/documents/mine`,
/// `khatam-backend/src/routes/documents.js`) fournit les deux à la fois.
class ProfileService {
  final ApiClient apiClient;

  ProfileService({required this.apiClient});

  Future<MyDocumentsResult> fetchMine() async {
    final data = await apiClient.get('/documents/mine');
    final list = (data['documents'] as List<dynamic>? ?? const []);
    final entries = list
        .cast<Map<String, dynamic>>()
        .map((json) => MyDocumentEntry.fromJson(json, apiOrigin: apiClient.origin))
        .toList();
    final progress = data['progress'] != null
        ? StudentProgress.fromJson(data['progress'] as Map<String, dynamic>)
        : StudentProgress.empty();
    return MyDocumentsResult(entries: entries, progress: progress);
  }
}

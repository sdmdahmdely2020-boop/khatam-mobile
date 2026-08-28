import '../../../core/api/api_client.dart';
import '../../catalog/models/document_item.dart';

/// Gestion des documents d'un professeur — réutilise la même route
/// `GET /api/documents` que le catalogue élève : côté serveur, un
/// professeur connecté y voit EN PLUS ses propres brouillons (voir
/// `khatam-backend/src/routes/documents.js`), mélangés avec les documents
/// publiés de tout le monde. On filtre donc ici, côté app, pour ne garder
/// que les documents dont ce professeur est l'auteur.
class ProfessorService {
  final ApiClient apiClient;

  ProfessorService({required this.apiClient});

  Future<List<DocumentItem>> fetchMyDocuments({required String professorId}) async {
    final data = await apiClient.get('/documents');
    final list = (data['documents'] as List<dynamic>? ?? const []);
    return list
        .cast<Map<String, dynamic>>()
        .map((json) => DocumentItem.fromJson(json, apiOrigin: apiClient.origin))
        .where((doc) => doc.professorId == professorId)
        .toList();
  }

  /// Publie ou dépublie un document. Le serveur refuse de publier
  /// (`PROFESSOR_NOT_APPROVED`) tant que le compte professeur n'a pas été
  /// approuvé par un administrateur — l'erreur remonte telle quelle
  /// (message déjà en français) si ça arrive.
  Future<DocumentItem> setPublished(String documentId, bool published) async {
    final data = await apiClient.patch(
      '/documents/$documentId',
      {'statut': published ? 'publie' : 'brouillon'},
    );
    return DocumentItem.fromJson(
      data['document'] as Map<String, dynamic>,
      apiOrigin: apiClient.origin,
    );
  }
}

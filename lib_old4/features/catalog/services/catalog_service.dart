import '../../../core/api/api_client.dart';
import '../models/document_item.dart';

/// Accès au catalogue de documents (`GET /api/documents`,
/// `GET /api/documents/:id`) — même backend que le site web.
class CatalogService {
  final ApiClient apiClient;

  CatalogService({required this.apiClient});

  /// [serie] : 'A' | 'C' | 'D' (ou null = toutes les séries).
  /// [q] : recherche texte sur le titre.
  Future<List<DocumentItem>> fetchDocuments({
    String? serie,
    String? matiere,
    int? annee,
    String? type,
    String? q,
  }) async {
    final query = <String, String>{};
    if (serie != null && serie.isNotEmpty) query['serie'] = serie;
    if (matiere != null && matiere.isNotEmpty) query['matiere'] = matiere;
    if (annee != null) query['annee'] = annee.toString();
    if (type != null && type.isNotEmpty) query['type'] = type;
    if (q != null && q.isNotEmpty) query['q'] = q;

    final queryString = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';

    // withAuth: true (par défaut) — un élève/professeur connecté reçoit
    // `unlocked` correctement calculé par le serveur ; un visiteur non
    // connecté reçoit quand même la liste, mais tout apparaît verrouillé.
    final data = await apiClient.get('/documents$queryString');
    final list = (data['documents'] as List<dynamic>? ?? const []);

    return list
        .cast<Map<String, dynamic>>()
        .map((json) => DocumentItem.fromJson(json, apiOrigin: apiClient.origin))
        .toList();
  }

  Future<DocumentItem> fetchDocument(String id) async {
    final data = await apiClient.get('/documents/$id');
    return DocumentItem.fromJson(
      data['document'] as Map<String, dynamic>,
      apiOrigin: apiClient.origin,
    );
  }
}

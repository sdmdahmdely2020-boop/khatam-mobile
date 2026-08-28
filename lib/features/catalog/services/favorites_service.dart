import '../../../core/api/api_client.dart';
import '../models/favorite_document.dart';

/// Favoris — élève uniquement côté serveur (`requireAuth({roles: ['STUDENT']})`
/// sur les deux routes concernées).
class FavoritesService {
  final ApiClient apiClient;

  FavoritesService({required this.apiClient});

  Future<List<FavoriteDocument>> fetchFavorites() async {
    final data = await apiClient.get('/favorites');
    final list = (data['documents'] as List<dynamic>? ?? const []);
    return list
        .cast<Map<String, dynamic>>()
        .map((json) => FavoriteDocument.fromJson(json, apiOrigin: apiClient.origin))
        .toList();
  }

  Future<Set<String>> fetchFavoriteIds() async {
    final favorites = await fetchFavorites();
    return favorites.map((f) => f.id).toSet();
  }

  /// Bascule l'état favori d'un document. Renvoie le nouvel état
  /// (`true` = maintenant en favori).
  Future<bool> toggle(String documentId) async {
    final data = await apiClient.post('/documents/$documentId/favorite', {});
    return data['favorited'] == true;
  }
}

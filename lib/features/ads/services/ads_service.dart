import '../../../core/api/api_client.dart';
import '../models/ad_item.dart';

/// Publicités locales (bandeau `banner`) — voir
/// `khatam-backend/src/routes/ads.js`. Route publique, aucun jeton requis.
class AdsService {
  final ApiClient apiClient;

  AdsService({required this.apiClient});

  /// [zone] : `'catalog'` (catalogue élève) ou `'dashboard'` ("Mes
  /// documents" professeur) — même découpage que le bandeau déjà en place
  /// sur le site web.
  Future<List<AdItem>> fetchBannerAds({required String zone}) async {
    final json = await apiClient.get(
      '/ads/list?placement=banner&zone=$zone',
      withAuth: false,
    );
    final rows = (json['ads'] as List<dynamic>?) ?? const [];
    return rows
        .map((row) => AdItem.fromJson(row as Map<String, dynamic>, apiOrigin: apiClient.origin))
        .toList();
  }

  /// Signalé à chaque fois qu'une annonce devient visible dans le carrousel
  /// (changement de page). Volontairement silencieux en cas d'échec — un
  /// compteur de vues raté ne doit jamais perturber l'utilisateur.
  Future<void> reportImpression(String adId) async {
    try {
      await apiClient.post('/ads/$adId/impression', const {}, withAuth: false);
    } catch (_) {
      // Ignoré volontairement, voir commentaire ci-dessus.
    }
  }

  /// Signalé quand l'utilisateur touche l'annonce (avant l'ouverture du
  /// lien). Même tolérance à l'échec que [reportImpression].
  Future<void> reportClick(String adId) async {
    try {
      await apiClient.post('/ads/$adId/click', const {}, withAuth: false);
    } catch (_) {
      // Ignoré volontairement.
    }
  }
}

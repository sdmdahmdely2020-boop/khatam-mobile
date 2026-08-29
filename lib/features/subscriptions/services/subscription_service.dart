import '../../../core/api/api_client.dart';
import '../models/subscription_models.dart';

/// Abonnements Basic/Premium — même circuit de paiement manuel que
/// `catalog/services/payment_service.dart` (Bankily/Masrivi/Sedad, numéro de
/// reçu, confirmation TOUJOURS manuelle par l'administrateur). Service
/// volontairement séparé de `PaymentService` — voir `subscription_models.dart`
/// pour la raison.
class SubscriptionService {
  final ApiClient apiClient;

  SubscriptionService({required this.apiClient});

  /// `GET /api/subscriptions/plans` — public, pas besoin d'être connecté
  /// (utile pour un écran d'upsell affiché avant inscription).
  Future<SubscriptionPlansInfo> fetchPlans() async {
    final data = await apiClient.get('/subscriptions/plans', withAuth: false);
    return SubscriptionPlansInfo.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /api/subscriptions/me` — plan réellement actif de l'élève connecté.
  Future<SubscriptionStatusInfo> fetchMe() async {
    final data = await apiClient.get('/subscriptions/me');
    return SubscriptionStatusInfo.fromJson(data as Map<String, dynamic>);
  }

  Future<InitiatedSubscriptionPurchase> purchase({
    required SubscriptionPlanKind plan,
    required String method,
  }) async {
    final data = await apiClient.post('/subscriptions/purchase', {
      'plan': plan.apiValue,
      'method': method,
    });
    return InitiatedSubscriptionPurchase.fromJson(
      data as Map<String, dynamic>,
      method: method,
      plan: plan,
    );
  }

  Future<SubscriptionPurchaseStatus> submitReference({
    required String purchaseId,
    required String reference,
  }) async {
    final data = await apiClient.post('/subscriptions/$purchaseId/submit-reference', {
      'reference': reference,
    });
    return SubscriptionPurchaseStatus.fromJson(data['purchase'] as Map<String, dynamic>);
  }

  Future<SubscriptionPurchaseStatus> getStatus(String purchaseId) async {
    final data = await apiClient.get('/subscriptions/$purchaseId/status');
    return SubscriptionPurchaseStatus.fromJson(data['purchase'] as Map<String, dynamic>);
  }
}

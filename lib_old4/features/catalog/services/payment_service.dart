import '../../../core/api/api_client.dart';
import '../models/purchase.dart';

/// Paiement Bankily/Masrivi/Sedad et déblocage par publicité.
///
/// IMPORTANT : ces paiements ne sont JAMAIS confirmés automatiquement par
/// l'app — le déblocage réel n'arrive qu'après vérification manuelle par
/// l'administrateur (voir `khatam-backend/src/routes/payments.js`). L'élève
/// paie en dehors de l'app (sur son téléphone, via Bankily/Masrivi/Sedad),
/// puis colle ici le numéro de reçu donné par son opérateur.
class PaymentService {
  final ApiClient apiClient;

  PaymentService({required this.apiClient});

  Future<InitiatedPurchase> initiate({
    required String documentId,
    required String method,
  }) async {
    final data = await apiClient.post('/payments/initiate', {
      'documentId': documentId,
      'method': method,
    });
    return InitiatedPurchase.fromJson(data, method: method);
  }

  Future<PurchaseStatus> submitReference({
    required String purchaseId,
    required String reference,
  }) async {
    final data = await apiClient.post('/payments/$purchaseId/submit-reference', {
      'reference': reference,
    });
    return PurchaseStatus.fromJson(data['purchase'] as Map<String, dynamic>);
  }

  Future<PurchaseStatus> getStatus(String purchaseId) async {
    final data = await apiClient.get('/payments/$purchaseId/status');
    return PurchaseStatus.fromJson(data['purchase'] as Map<String, dynamic>);
  }

  /// Déblocage gratuit après visionnage complet d'une publicité (uniquement
  /// si le document l'autorise, voir `DocumentItem.adUnlock`). Le serveur
  /// exige au moins 4000 ms visionnées — on envoie toujours la durée réelle
  /// de la simulation, jamais une valeur inventée plus grande.
  Future<bool> adUnlock({required String documentId, required int watchedMs}) async {
    final data = await apiClient.post('/documents/$documentId/ad-unlock', {
      'watchedMs': watchedMs,
    });
    return data['unlocked'] == true;
  }
}

/// Moyens de paiement mauritaniens supportés par le backend
/// (`khatam-backend/src/lib/payments.js`, `PROVIDERS`). Valeurs exactes
/// attendues par le serveur — NE PAS changer la casse.
const List<String> kPaymentMethods = ['bankily', 'masrivi', 'sedad'];

String paymentMethodLabel(String method) {
  switch (method) {
    case 'bankily':
      return 'Bankily';
    case 'masrivi':
      return 'Masrivi';
    case 'sedad':
      return 'Sedad';
    default:
      return method;
  }
}

/// Réponse de `POST /api/payments/initiate` — un achat vient d'être créé
/// côté serveur ("pending"), avec le numéro réel sur lequel envoyer l'argent.
class InitiatedPurchase {
  final String purchaseId;
  final String status;
  final String providerRef;
  final num amount;
  final String payTo;
  final String instructions;
  final String method;

  InitiatedPurchase({
    required this.purchaseId,
    required this.status,
    required this.providerRef,
    required this.amount,
    required this.payTo,
    required this.instructions,
    required this.method,
  });

  factory InitiatedPurchase.fromJson(Map<String, dynamic> json, {required String method}) {
    return InitiatedPurchase(
      purchaseId: json['purchaseId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      providerRef: json['providerRef'] as String? ?? '',
      amount: (json['amount'] as num?) ?? 0,
      payTo: json['payTo'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      method: method,
    );
  }
}

/// Reflète une ligne de la table `purchases` — utilisé pour le suivi de
/// statut (`GET /api/payments/:id/status`) après soumission de la référence.
class PurchaseStatus {
  final String id;
  final String status; // 'pending' | 'confirmed' | 'failed'
  final num amount;
  final String method;
  final String? studentRef;

  PurchaseStatus({
    required this.id,
    required this.status,
    required this.amount,
    required this.method,
    this.studentRef,
  });

  factory PurchaseStatus.fromJson(Map<String, dynamic> json) {
    return PurchaseStatus(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      amount: (json['amount'] as num?) ?? 0,
      method: json['method'] as String? ?? '',
      studentRef: json['studentRef'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isFailed => status == 'failed';
}

/// Modèles pour le système d'abonnement Basic/Premium (modèle HYBRIDE,
/// 29/08) — voir `khatam-backend/src/lib/subscriptions.js` côté serveur et
/// `khatam-backend/src/routes/subscriptions.js` pour les routes.
///
/// Ce système S'AJOUTE à l'achat de document à l'unité (voir
/// `catalog/models/purchase.dart`), il ne le remplace pas. Les modèles
/// ci-dessous sont volontairement séparés de ceux de `purchase.dart` plutôt
/// que partagés — même si les formes JSON se ressemblent beaucoup — pour ne
/// jamais risquer de casser le flux d'achat de document déjà en production
/// en modifiant un modèle partagé.

/// 'basic' ou 'premium' — jamais 'free' ici (on n'achète pas le plan
/// gratuit, c'est l'état par défaut).
enum SubscriptionPlanKind { basic, premium }

extension SubscriptionPlanKindX on SubscriptionPlanKind {
  String get apiValue => this == SubscriptionPlanKind.basic ? 'basic' : 'premium';
  String get label => this == SubscriptionPlanKind.basic ? 'Basic' : 'Premium';
}

/// Réponse de `GET /api/subscriptions/plans` (public, prix/durée/réduction
/// configurés par l'administrateur — jamais codés en dur côté app).
class SubscriptionPlansInfo {
  final num basicPrice;
  final int basicDurationDays;
  final num basicDiscountPercent;
  final num premiumPrice;
  final int premiumDurationDays;

  SubscriptionPlansInfo({
    required this.basicPrice,
    required this.basicDurationDays,
    required this.basicDiscountPercent,
    required this.premiumPrice,
    required this.premiumDurationDays,
  });

  factory SubscriptionPlansInfo.fromJson(Map<String, dynamic> json) {
    final plans = (json['plans'] as Map<String, dynamic>?) ?? const {};
    final basic = (plans['basic'] as Map<String, dynamic>?) ?? const {};
    final premium = (plans['premium'] as Map<String, dynamic>?) ?? const {};
    return SubscriptionPlansInfo(
      basicPrice: (basic['price'] as num?) ?? 0,
      basicDurationDays: (basic['durationDays'] as num?)?.toInt() ?? 30,
      basicDiscountPercent: (basic['discountPercent'] as num?) ?? 0,
      premiumPrice: (premium['price'] as num?) ?? 0,
      premiumDurationDays: (premium['durationDays'] as num?)?.toInt() ?? 30,
    );
  }
}

/// Réponse de `GET /api/subscriptions/me` — plan RÉELLEMENT actif à
/// l'instant présent (un abonnement expiré redevient 'free' automatiquement
/// côté serveur, sans action de l'app).
class SubscriptionStatusInfo {
  final String plan; // 'free' | 'basic' | 'premium'
  final DateTime? expiresAt;

  SubscriptionStatusInfo({required this.plan, this.expiresAt});

  factory SubscriptionStatusInfo.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expiresAt'] as String?;
    return SubscriptionStatusInfo(
      plan: json['plan'] as String? ?? 'free',
      expiresAt: rawExpiry == null ? null : DateTime.tryParse(rawExpiry),
    );
  }

  static SubscriptionStatusInfo free() => SubscriptionStatusInfo(plan: 'free');

  bool get isFree => plan == 'free';
  bool get isBasic => plan == 'basic';
  bool get isPremium => plan == 'premium';
}

/// Réponse de `POST /api/subscriptions/purchase` — un abonnement vient
/// d'être créé côté serveur ("pending"), avec le numéro réel sur lequel
/// envoyer l'argent (même circuit que l'achat de document, confirmation
/// TOUJOURS manuelle par l'administrateur).
class InitiatedSubscriptionPurchase {
  final String purchaseId;
  final String status;
  final String providerRef;
  final num amount;
  final int durationDays;
  final String payTo;
  final String instructions;
  final String method;
  final SubscriptionPlanKind plan;

  InitiatedSubscriptionPurchase({
    required this.purchaseId,
    required this.status,
    required this.providerRef,
    required this.amount,
    required this.durationDays,
    required this.payTo,
    required this.instructions,
    required this.method,
    required this.plan,
  });

  factory InitiatedSubscriptionPurchase.fromJson(
    Map<String, dynamic> json, {
    required String method,
    required SubscriptionPlanKind plan,
  }) {
    return InitiatedSubscriptionPurchase(
      purchaseId: json['purchaseId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      providerRef: json['providerRef'] as String? ?? '',
      amount: (json['amount'] as num?) ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      payTo: json['payTo'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      method: method,
      plan: plan,
    );
  }
}

/// Reflète une ligne de `subscription_purchases` — suivi de statut après
/// soumission de la référence.
class SubscriptionPurchaseStatus {
  final String id;
  final String status; // 'pending' | 'confirmed' | 'failed'
  final num amount;
  final String method;
  final String? studentRef;

  SubscriptionPurchaseStatus({
    required this.id,
    required this.status,
    required this.amount,
    required this.method,
    this.studentRef,
  });

  factory SubscriptionPurchaseStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionPurchaseStatus(
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

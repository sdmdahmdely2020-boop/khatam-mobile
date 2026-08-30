import '../../profile/models/my_document_entry.dart';

/// Résumé "motivation" (29/08) calculé côté app à partir de
/// `GET /api/documents/mine` (déjà utilisé par le profil élève) — aucune
/// nouvelle route backend.
///
/// Note honnête sur les "économies" : cette route ne renvoie que les
/// documents achetés à l'unité ou débloqués par publicité. Un abonné
/// Premium n'a, par définition, aucun achat individuel une fois abonné
/// (voir `hasAccess()` côté serveur — le Premium court-circuite l'achat) :
/// il n'existe donc AUCUNE donnée permettant de calculer un montant "économisé"
/// réel pour lui. Plutôt que d'inventer un chiffre, [monthlySavingsMru] reste
/// à 0 pour un Premium et l'écran affiche un message de valeur différent
/// (accès illimité) au lieu d'un montant.
class MotivationSummary {
  /// Nombre de documents débloqués (achat confirmé OU publicité) depuis le
  /// début de la semaine calendaire en cours (lundi 00:00, heure locale).
  final int weeklyUnlockedCount;

  /// Somme réelle (prix normal - montant payé) pour les achats confirmés du
  /// mois calendaire en cours. Toujours calculée à partir de montants
  /// réellement payés, jamais estimée.
  final num monthlySavingsMru;

  MotivationSummary({required this.weeklyUnlockedCount, required this.monthlySavingsMru});

  static MotivationSummary empty() => MotivationSummary(weeklyUnlockedCount: 0, monthlySavingsMru: 0);

  factory MotivationSummary.fromEntries(List<MyDocumentEntry> entries) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    var weeklyCount = 0;
    num savings = 0;

    for (final entry in entries) {
      final acquiredAt = entry.acquiredAt;
      if (acquiredAt == null) continue;

      if (!acquiredAt.isBefore(startOfWeek)) {
        weeklyCount += 1;
      }

      if (entry.isPurchase && !acquiredAt.isBefore(startOfMonth)) {
        final saved = entry.document.prix - entry.amountPaid;
        if (saved > 0) savings += saved;
      }
    }

    return MotivationSummary(weeklyUnlockedCount: weeklyCount, monthlySavingsMru: savings);
  }
}

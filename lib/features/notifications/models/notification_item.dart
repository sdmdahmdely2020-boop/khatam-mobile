/// Modèle "structure only" (29/08) — prépare le terrain pour un vrai
/// système de notifications plus tard (nouveau TD disponible, rappel de
/// progression, abonnement qui expire bientôt...), SANS backend ni service
/// de push pour l'instant. Volontairement séparé plutôt qu'ajouté à un
/// module existant, pour ne rien casser en attendant la vraie implémentation.
enum NotificationType {
  /// Un professeur a publié un nouveau document dans une matière suivie.
  newDocument,

  /// Rappel doux si l'élève n'a pas ouvert l'app depuis un moment, ou n'a
  /// pas atteint son objectif hebdomadaire.
  progressReminder,

  /// L'abonnement Basic/Premium de l'élève arrive bientôt à expiration.
  subscriptionExpiring,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/notification_item.dart';

/// Écran "Notifications" — STRUCTURE UNIQUEMENT (29/08), comme demandé
/// explicitement par sidi ("Add notifications system (structure only)").
///
/// Ce qui existe déjà : l'écran, le modèle [NotificationItem] (3 types
/// prévus : nouveau document, rappel de progression, abonnement qui
/// expire), l'icône d'accès depuis l'accueil.
///
/// Ce qui N'existe PAS encore, volontairement : un vrai backend de
/// notifications (route API, table en base, déclenchement quand un
/// professeur publie un document) ni de notifications push sur le
/// téléphone. La liste ci-dessous est donc TOUJOURS vide pour l'instant —
/// délibérément, pour ne jamais montrer à un élève une fausse notification
/// qui n'est pas réelle. Quand la vraie route backend existera, il suffira
/// de remplacer `_items` par un appel réseau : le reste de l'écran (liste,
/// icônes par type, état vide) est déjà prêt à l'accueillir.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Volontairement vide — voir le commentaire de la classe.
  static const List<NotificationItem> _items = [];

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.newDocument:
        return Icons.fiber_new_outlined;
      case NotificationType.progressReminder:
        return Icons.local_fire_department_outlined;
      case NotificationType.subscriptionExpiring:
        return Icons.workspace_premium_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none, size: 44, color: Colors.black26),
                      const SizedBox(height: 14),
                      const Text(
                        'Aucune notification pour l\'instant',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Tu seras prévenu ici quand un nouveau document sera "
                        "publié dans tes matières, ou pour un rappel de "
                        "progression.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE7EBF1)),
                    ),
                    child: ListTile(
                      leading: Icon(_iconFor(item.type), color: AppTheme.brandBlue),
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(item.body),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

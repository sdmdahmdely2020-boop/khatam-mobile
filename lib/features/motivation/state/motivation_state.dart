import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../profile/services/profile_service.dart';
import '../models/motivation_summary.dart';

enum MotivationLoadStatus { idle, loading, loaded, error }

/// État "motivation" de l'accueil élève (série de jours + objectif
/// hebdomadaire + économies du mois) — Provider/ChangeNotifier fourni
/// localement dans `CatalogHome`, même schéma que `CatalogState` et
/// `SubscriptionState`. Un seul appel réseau, vers une route qui existe déjà
/// (`GET /api/documents/mine`).
class MotivationState extends ChangeNotifier {
  final ProfileService profileService;

  MotivationState({required this.profileService});

  MotivationLoadStatus status = MotivationLoadStatus.idle;
  MotivationSummary summary = MotivationSummary.empty();
  String? errorMessage;

  /// Objectif hebdomadaire par défaut. "Chapitre" n'existe pas comme notion
  /// dans les données actuelles (un document a une matière/série/année/type,
  /// pas de découpage en chapitres) — approximé par "documents débloqués",
  /// ce qui est mesurable dès aujourd'hui sans changement backend. Pourra
  /// devenir configurable par l'administrateur plus tard si besoin.
  static const int weeklyGoal = 2;

  Future<void> load() async {
    status = MotivationLoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await profileService.fetchMine();
      summary = MotivationSummary.fromEntries(result.entries);
      status = MotivationLoadStatus.loaded;
      notifyListeners();
    } on ApiException catch (e) {
      status = MotivationLoadStatus.error;
      errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      status = MotivationLoadStatus.error;
      errorMessage = "Impossible de contacter le serveur.";
      notifyListeners();
    }
  }
}

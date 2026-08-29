import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';

enum SubscriptionLoadStatus { idle, loading, loaded, error }

/// État partagé de l'abonnement de l'élève connecté (Provider/ChangeNotifier),
/// sur le même modèle que `catalog/state/catalog_state.dart`. Fourni
/// localement dans `CatalogHome` (comme `CatalogState`), pas dans `app.dart` —
/// voir `subscription_models.dart` pour la justification de cette séparation.
class SubscriptionState extends ChangeNotifier {
  final SubscriptionService subscriptionService;

  SubscriptionState({required this.subscriptionService});

  SubscriptionLoadStatus status = SubscriptionLoadStatus.idle;
  SubscriptionStatusInfo current = SubscriptionStatusInfo.free();
  String? errorMessage;

  bool get isFree => current.isFree;
  bool get isBasic => current.isBasic;
  bool get isPremium => current.isPremium;

  Future<void> load() async {
    status = SubscriptionLoadStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      current = await subscriptionService.fetchMe();
      status = SubscriptionLoadStatus.loaded;
      notifyListeners();
    } on ApiException catch (e) {
      status = SubscriptionLoadStatus.error;
      errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      status = SubscriptionLoadStatus.error;
      errorMessage =
          "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      notifyListeners();
    }
  }
}

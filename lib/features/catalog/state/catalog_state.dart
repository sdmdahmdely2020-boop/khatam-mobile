import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../models/document_item.dart';
import '../services/catalog_service.dart';

enum CatalogStatus { idle, loading, loaded, error }

/// État partagé du catalogue (Provider/ChangeNotifier). Un seul jeu de
/// filtres actif à la fois : série sélectionnée (null = "Toutes") + texte
/// de recherche libre sur le titre.
class CatalogState extends ChangeNotifier {
  final CatalogService catalogService;

  CatalogState({required this.catalogService});

  CatalogStatus status = CatalogStatus.idle;
  List<DocumentItem> documents = [];
  String? errorMessage;

  /// null = "Toutes les séries".
  String? serieFilter;
  String searchQuery = '';

  Future<void> load() async {
    status = CatalogStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      documents = await catalogService.fetchDocuments(
        serie: serieFilter,
        q: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
      );
      status = CatalogStatus.loaded;
      notifyListeners();
    } on ApiException catch (e) {
      status = CatalogStatus.error;
      errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      status = CatalogStatus.error;
      errorMessage =
          "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      notifyListeners();
    }
  }

  Future<void> setSerie(String? serie) async {
    if (serieFilter == serie) return;
    serieFilter = serie;
    await load();
  }

  Future<void> search(String query) async {
    searchQuery = query;
    await load();
  }
}

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/subject_icons.dart';
import '../models/document_item.dart';
import '../services/catalog_service.dart';

enum CatalogStatus { idle, loading, loaded, error }

/// État partagé du catalogue (Provider/ChangeNotifier). Filtres actifs :
/// série sélectionnée (null = "Toutes") + texte de recherche libre sur le
/// titre (tous deux envoyés au serveur, voir [load]), et un filtre rapide
/// par matière (voir [matiereKeywordFilter]) appliqué côté app uniquement
/// sur la liste déjà chargée — voir le commentaire de [visibleDocuments].
class CatalogState extends ChangeNotifier {
  final CatalogService catalogService;

  CatalogState({required this.catalogService});

  CatalogStatus status = CatalogStatus.idle;
  List<DocumentItem> documents = [];
  String? errorMessage;

  /// null = "Toutes les séries".
  String? serieFilter;
  String searchQuery = '';

  /// Mot-clé du filtre rapide par matière (icônes du catalogue), ex.
  /// `'math'`, `'physique'`... — `null` = pas de filtre. Volontairement
  /// appliqué côté app (voir [visibleDocuments]) et non transmis au serveur :
  /// le paramètre `matiere` de `GET /api/documents` exige une égalité EXACTE
  /// avec le texte tapé par le professeur, ce qui raterait la plupart des
  /// documents (`matiere` est un champ libre, pas une liste fermée — même
  /// remarque déjà documentée pour `SubjectIcon`).
  String? matiereKeywordFilter;

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

  /// Sélectionne/désélectionne le filtre rapide par matière (toucher la même
  /// icône une seconde fois l'efface). Ne relance pas de requête réseau —
  /// voir [visibleDocuments].
  void setMatiereKeyword(String? keyword) {
    matiereKeywordFilter = (matiereKeywordFilter == keyword) ? null : keyword;
    notifyListeners();
  }

  /// [documents] déjà filtrés par le serveur (série + recherche), avec en
  /// plus le filtre rapide par matière appliqué ici. C'est cette liste qu'un
  /// écran doit afficher, jamais [documents] directement.
  List<DocumentItem> get visibleDocuments {
    final keyword = matiereKeywordFilter;
    if (keyword == null) return documents;
    return documents.where((doc) => SubjectIcons.matches(doc.matiere, keyword)).toList();
  }
}

# ROADMAP — Application mobile Khatam (Flutter)

Application mobile native pour Khatam, connectée au backend existant
(`khatam-backend`, déjà en production sur Render — même API que le site
web actuel `khatam-site`, laissé intact comme prévu).

Légende : ✅ fait et livré · 🔄 en cours / en attente de validation · ⬜ pas commencé

---

## Phase 0 — Fondations

- ✅ Structure du projet (`core/` pour le transverse, `features/` par domaine métier)
- ✅ Thème Material 3 — palette bleu (`#1E5FA8`) / vert (`#1E8A4C`), générée via `ColorScheme.fromSeed`
- ✅ Client API générique (`core/api/api_client.dart`) — pointe vers `https://khatam-backend-i6zn.onrender.com/api`, GET/POST/PATCH/DELETE
- ✅ Stockage local (jeton de connexion, identifiant d'appareil, écran d'accueil déjà vu) — `core/storage/local_storage.dart`
- ✅ **Écran d'accueil (onboarding, 3 pages)** — illustrations lot 2, affiché une seule fois par appareil avant l'écran de connexion (`features/onboarding/`)
- ⬜ Écran de démarrage (splash) — restaure la session si un jeton existe déjà localement

## Phase 1 — Authentification ✅ TERMINÉE

- ✅ Connexion, inscription (élève/professeur), vérification email, mot de passe oublié — testés en conditions réelles
- ✅ **Aiguillage par rôle** : après connexion/vérification, un professeur atterrit sur son espace ("Mes documents"), un élève sur le catalogue (`HomeRouter`)
- Note : la limite "un seul appareil par compte" reste temporairement **désactivée** côté serveur — réactivable via une variable d'environnement sur Render, sans changement de code.

## Phase 2 — Contenu principal

- ✅ Catalogue de documents (liste + recherche par titre + filtre par Série)
- ✅ Fiche document (aperçu, prix, bouton Ouvrir/Débloquer, cœur favoris pour un élève)
- ✅ **Icônes de matière** (lot 3) sur les cartes de documents (catalogue, favoris, "Mes documents" professeur) et sur la fiche document
- ✅ **Accueil élève repensé** — salutation personnalisée ("Bonjour, Prénom"), filtre rapide par matière (icônes du lot 3, appliqué côté app puisque `matiere` est un texte libre — voir note technique), section "Sélection de la semaine" (mise en avant éditoriale de quelques documents existants, change chaque semaine, aucun nouveau prix/backend), le tout dans une page qui défile d'un bloc
- ✅ **Accueil élève : badge de plan, cadenas, bouton Premium, progression (29/08)** — quatre ajouts purement visuels, aucun changement serveur : (1) badge coloré Free/Basic/Premium à côté de la salutation, (2) icône cadenas sur la vignette + étiquette "Inclus dans Premium" pour un document payant non débloqué, (3) bouton "Devenir Premium" directement dans le bandeau d'abonnement pour un élève non-Premium, (4) bloc "Ma progression" avec une barre par matière (ex. "Mathématiques 60 %"), calculée sur les documents déjà chargés. Rien retiré ni déplacé — recherche, filtres, sélection de la semaine et publicités restent identiques.
- ⬜ Profil public d'un professeur (bio, matières, tous ses documents, likes)
- ⬜ Filtres supplémentaires côté serveur (Année, Type) — Matière est maintenant filtrable (côté app), Série déjà branchée côté serveur

## Phase 3 — Paiement et déblocage ✅ (hors reçu photo)

- ✅ Visionneuse sécurisée (pages filigranées au nom du lecteur)
- ✅ Achat Bankily / Masrivi / Sedad (numéro affiché, numéro de reçu, attente de confirmation admin)
- ✅ Déblocage par publicité (simulation — pas encore de vrai SDK publicitaire)
- ✅ **Favoris** — cœur sur la fiche document + écran "Mes favoris" (accessible depuis le catalogue)
- ⬜ Envoi d'une capture d'écran du reçu de paiement (facultatif côté serveur, nécessite un nouveau paquet Flutter)
- ✅ **Abonnements Basic/Premium (modèle hybride, 29/08)** — écran "Mon abonnement" (accessible depuis "Mon compte") : formules Basic/Premium (prix/durée/réduction configurés par l'administrateur), même circuit de paiement manuel Bankily/Masrivi/Sedad que l'achat de document. Accueil élève : bandeau du plan actif (ou invitation à souscrire), publicités automatiquement masquées pour un abonné Premium, prix réduit affiché (barré/nouveau prix) sur les cartes du catalogue, la fiche document et l'écran de déblocage pour un abonné Basic. S'ajoute à l'achat document par document, ne le remplace pas.

## Phase 4 — Espace élève

- ✅ **Mon compte** (lecture seule : nom, téléphone, email, rôle) + déconnexion
- ⬜ Modification du profil (photo, changement de série)
- ✅ **Mes documents (achetés + débloqués par pub) et progression simple (29/08)** — nouvel écran "Mes documents" (depuis "Mon compte") : liste des documents réellement débloqués (achat confirmé ou publicité vue, badge distinct pour chaque), avec la date et le montant payé. En haut, un résumé "progression" : nombre total de documents débloqués, total dépensé en MRU, badge Basic/Premium si abonné, répartition par matière. Nouvelle route backend `GET /api/documents/mine`.
- ✅ **Correction IA** — envoi d'une copie (photo, PDF, ou texte tapé) pour un document où c'est activé, note sur 20 + retour détaillé (points forts/à travailler), historique complet (accessible depuis la fiche document et depuis "Mon compte")
- ⬜ Note de l'application (étoiles)

## Phase 5 — Espace professeur (démarrée)

- ✅ **"Mes documents"** — liste de ses propres documents (publiés + brouillons), bouton Publier/Dépublier
- ✅ **Présentation retravaillée de "Mes documents" (29/08, dernière étape du plan initial)** — salutation personnalisée, mini-résumé (nombre de documents / publiés / vues totales) en un coup d'œil sans quitter l'écran, recherche par titre, filtre par statut (Tous/Publiés/Brouillons) — tout appliqué côté app (peu de documents par professeur, pas besoin d'aller-retour serveur à chaque frappe). Les statistiques complètes restent sur l'écran dédié, pas dupliquées ici.
- ✅ **Upload d'un NOUVEAU document** directement depuis l'app (titre, matière, série, année, type, prix, gratuit/pub/correction IA, fichier PDF) — bouton "Nouveau document" sur l'écran "Mes documents"
- ⬜ Modifier le prix d'un document existant depuis l'app (possible côté serveur, pas encore construit côté app)
- ✅ **Portefeuille et demande de retrait** — solde disponible, historique des ventes confirmées, demande de retrait Bankily/Masrivi/Sedad (traitement manuel par un administrateur, comme sur le site web)
- ✅ **Statistiques avancées** — vues totales, ventes, revenu total, taux de conversion estimé, document le plus consulté, meilleure vente, tendance des revenus sur 6 mois, vues par matière (icône dans l'AppBar de "Mes documents")
- ⬜ Boost (mise en avant payante)
- ⬜ Messagerie avec l'administrateur

## Phase 6 — Contenu dynamique et engagement

- ⬜ FAQ
- ⬜ À propos
- ⬜ Formulaire de feedback
- ✅ **Bandeau publicitaire (carrousel)** — publicités locales (annonceurs mauritaniens gérés depuis `admin.html`), défilement automatique toutes les 6s, sur le catalogue élève ET le tableau de bord professeur ; entièrement invisible tant qu'aucune annonce active n'existe pour la zone concernée

## Phase 7 — Finitions

- ✅ **Icône de l'application Android** (logo Khatam, lot 1) — générée via `flutter_launcher_icons`, icône adaptative moderne (fond + premier plan)
- ⬜ Nom d'application personnalisé, écran de démarrage natif
- ⬜ Gestion hors-ligne basique (messages d'erreur réseau clairs, pas de crash)
- ✅ **Tests sur appareil réel** (Android) — testé en conditions réelles sur Galaxy Tab A9 (APK release) : connexion, icône de l'app, tout confirmé fonctionnel après le correctif de la permission `INTERNET`
- ⬜ Préparation à la publication (Google Play en priorité)

---

## Notes techniques (décisions prises pour ce projet)

- **Gestion d'état** : `provider` + `ChangeNotifier` — simple et suffisant pour la taille de l'application.
- **Navigation** : `Navigator` standard, avec un aiguillage par rôle (`HomeRouter`) après connexion.
- **Réseau** : package `http` officiel — `ApiClient` supporte GET, POST, PATCH, DELETE et l'envoi `multipart/form-data` (upload de document PDF, envoi d'une copie pour la correction IA).
- **Paiement** : le déblocage n'est JAMAIS automatique — confirmation manuelle par un administrateur, comme sur le site web.
- **Favoris** : `GET /api/favorites` renvoie une forme de données différente de `GET /api/documents` (lignes brutes de la base, pas la forme enrichie) — un modèle séparé (`FavoriteDocument`) gère ça plutôt que de forcer la réutilisation de `DocumentItem`.
- **Un seul appareil par compte** : contrainte disponible côté backend mais **désactivée pour l'instant**.
- **Modèle économique** : mis à jour le 29/08 — Khatam garde l'achat document par document (achat unique via Bankily/Masrivi/Sedad) ET propose désormais de vrais abonnements Basic/Premium (modèle HYBRIDE, décision explicite de sidi) : Basic donne une réduction sur les documents payants, Premium retire les publicités. Les deux circuits coexistent, l'un n'a jamais remplacé l'autre.
- **Filtre par matière** : `matiere` est un texte libre tapé par chaque professeur (pas une liste fermée), et le paramètre serveur `GET /api/documents?matiere=` exige une égalité EXACTE — donc le filtre rapide par matière de l'accueil (`SubjectQuickFilter`) est appliqué CÔTÉ APP sur la liste déjà chargée (`CatalogState.visibleDocuments`, via `SubjectIcons.matches()`), pas via ce paramètre serveur.

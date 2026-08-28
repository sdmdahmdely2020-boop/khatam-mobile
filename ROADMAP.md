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
- ⬜ Profil public d'un professeur (bio, matières, tous ses documents, likes)
- ⬜ Filtres supplémentaires (Année, Matière, Type) — seule la Série est branchée pour l'instant

## Phase 3 — Paiement et déblocage ✅ (hors reçu photo)

- ✅ Visionneuse sécurisée (pages filigranées au nom du lecteur)
- ✅ Achat Bankily / Masrivi / Sedad (numéro affiché, numéro de reçu, attente de confirmation admin)
- ✅ Déblocage par publicité (simulation — pas encore de vrai SDK publicitaire)
- ✅ **Favoris** — cœur sur la fiche document + écran "Mes favoris" (accessible depuis le catalogue)
- ⬜ Envoi d'une capture d'écran du reçu de paiement (facultatif côté serveur, nécessite un nouveau paquet Flutter)

## Phase 4 — Espace élève

- ✅ **Mon compte** (lecture seule : nom, téléphone, email, rôle) + déconnexion
- ⬜ Modification du profil (photo, changement de série)
- ⬜ Mes documents achetés / téléchargements
- ✅ **Correction IA** — envoi d'une copie (photo, PDF, ou texte tapé) pour un document où c'est activé, note sur 20 + retour détaillé (points forts/à travailler), historique complet (accessible depuis la fiche document et depuis "Mon compte")
- ⬜ Note de l'application (étoiles)

## Phase 5 — Espace professeur (démarrée)

- ✅ **"Mes documents"** — liste de ses propres documents (publiés + brouillons), bouton Publier/Dépublier
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
- ⬜ Bandeau publicitaire (carrousel)

## Phase 7 — Finitions

- ⬜ Icône et nom d'application, écran de démarrage natif
- ⬜ Gestion hors-ligne basique (messages d'erreur réseau clairs, pas de crash)
- ⬜ Tests sur appareil réel (Android en priorité, vu l'usage majoritairement mobile en Mauritanie)
- ⬜ Préparation à la publication (Google Play en priorité)

---

## Notes techniques (décisions prises pour ce projet)

- **Gestion d'état** : `provider` + `ChangeNotifier` — simple et suffisant pour la taille de l'application.
- **Navigation** : `Navigator` standard, avec un aiguillage par rôle (`HomeRouter`) après connexion.
- **Réseau** : package `http` officiel — `ApiClient` supporte GET, POST, PATCH, DELETE et l'envoi `multipart/form-data` (upload de document PDF, envoi d'une copie pour la correction IA).
- **Paiement** : le déblocage n'est JAMAIS automatique — confirmation manuelle par un administrateur, comme sur le site web.
- **Favoris** : `GET /api/favorites` renvoie une forme de données différente de `GET /api/documents` (lignes brutes de la base, pas la forme enrichie) — un modèle séparé (`FavoriteDocument`) gère ça plutôt que de forcer la réutilisation de `DocumentItem`.
- **Un seul appareil par compte** : contrainte disponible côté backend mais **désactivée pour l'instant**.

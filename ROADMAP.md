# ROADMAP — Application mobile Khatam (Flutter)

Application mobile native pour Khatam, connectée au backend existant
(`khatam-backend`, déjà en production sur Render — même API que le site
web actuel `khatam-site`, laissé intact comme prévu). Construite écran par
écran, chaque écran étant soumis à validation avant de passer au suivant.

Légende : ✅ fait et livré · 🔄 en cours / en attente de validation · ⬜ pas commencé

---

## Phase 0 — Fondations

- ✅ Structure du projet (`core/` pour le transverse, `features/` par domaine métier)
- ✅ Thème Material 3 — palette bleu (`#1E5FA8`) / vert (`#1E8A4C`), générée via `ColorScheme.fromSeed`
- ✅ Client API générique (`core/api/api_client.dart`) — pointe vers `https://khatam-backend-i6zn.onrender.com/api`
- ✅ Stockage local (jeton de connexion, identifiant d'appareil) — `core/storage/local_storage.dart`
- ⬜ Écran de démarrage (splash) — restaure la session si un jeton existe déjà localement

## Phase 1 — Authentification

- 🔄 **Écran de connexion** — Material 3, badge éducatif en dégradé, animation d'entrée, branché sur `POST /auth/login`, gère les 3 cas d'erreur du backend (identifiants invalides, email non vérifié, appareil déjà lié à un autre téléphone). **En attente de validation avant de continuer.**
- ⬜ Écran d'inscription (élève / professeur, avec champs spécifiques professeur : établissement, matière, expérience)
- ⬜ Écran de vérification email (code à 6 chiffres)
- ⬜ Écran mot de passe oublié / réinitialisation

## Phase 2 — Contenu principal

- ⬜ Catalogue de documents (liste + filtres Série / Année / Matière / Type)
- ⬜ Fiche document (aperçu, prix, bouton débloquer/acheter)
- ⬜ Profil public d'un professeur (bio, matières, documents, likes)
- ⬜ Recherche

## Phase 3 — Paiement et déblocage

- ⬜ Écran d'achat (Bankily / Masrivi / Sedad — saisie du numéro de reçu)
- ⬜ Déblocage par publicité
- ⬜ Favoris

## Phase 4 — Espace élève

- ⬜ Mon compte (profil, photo, changement de série)
- ⬜ Mes documents achetés / téléchargements
- ⬜ Correction IA (envoi de copie, note et retour détaillé)
- ⬜ Note de l'application (étoiles)

## Phase 5 — Espace professeur

- ⬜ Tableau de bord (statistiques, documents publiés)
- ⬜ Upload d'un document (titre, matière, série, année, prix, fichier)
- ⬜ Portefeuille et demande de retrait
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

- **Gestion d'état** : `provider` + `ChangeNotifier` — simple et suffisant pour la taille de l'application, pas de Bloc/Riverpod pour l'instant. Changeable plus tard si le besoin s'en fait sentir.
- **Navigation** : `Navigator` standard pour l'instant (pas de `go_router`) — sera reconsidéré si l'app grandit et a besoin de liens profonds (deep links).
- **Réseau** : package `http` officiel, appels REST classiques vers l'API déjà utilisée par le site web — aucun changement côté backend n'est nécessaire.
- **Un seul appareil par compte** : contrainte déjà appliquée côté backend (voir `khatam-backend`) — l'app génère et conserve un identifiant d'appareil unique dès le premier lancement (`core/storage/local_storage.dart`).

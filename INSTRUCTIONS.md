# Khatam — Écran d'inscription (Phase 1, écran 2/4)

## Ce qu'il y a dans ce zip

Le dossier `lib/` complet (core + features/auth), à jour avec :
- L'écran de connexion (identique à avant, juste reconstruit pour rester cohérent avec les nouveaux fichiers).
- **Le nouvel écran d'inscription** : bascule Élève/Professeur, champs communs (nom, téléphone, email, mot de passe, confirmation), puis champs spécifiques (Série pour un élève ; Établissement, Matières, Années d'expérience pour un professeur).
- Le bouton "Créer un compte" de l'écran de connexion ouvre maintenant vraiment cet écran (au lieu du message "bientôt disponible").
- Après une inscription réussie : écran de confirmation ("Compte créé ! Vérifiez votre email...") — l'écran de vérification par code à 6 chiffres est la prochaine étape (pas encore construit).
- Deux corrections de propreté : les 4 avertissements `withOpacity` relevés par `flutter analyze` la dernière fois ont été remplacés par `withValues()` (la méthode recommandée).

## Comment l'installer

1. Dans `C:\Users\lenovo\Documents\khatam_app`, **supprime le dossier `lib` actuel** (ou renomme-le en `lib_old` par sécurité).
2. Copie le dossier `lib` de ce zip à la place.
3. Dans PowerShell (au même endroit qu'avant) :
   ```
   flutter pub get
   flutter analyze
   ```
4. Colle-moi le résultat de `flutter analyze`. S'il y a des erreurs, envoie-les-moi telles quelles.
5. Une fois propre, relance l'app (bouton ▶ dans Android Studio, cible "Chrome (web)" comme la dernière fois) et teste : clique sur "Créer un compte", bascule entre Élève et Professeur, remplis le formulaire.

## ⚠️ Point à vérifier ensemble

Je n'ai pas pu vérifier les noms exacts des champs attendus par le serveur pour l'inscription (`/auth/signup`) dans cette session — j'ai utilisé les noms les plus probables (`fullName`, `phone`, `email`, `password`, `serie`, `etablissement`, `matieres`, `experienceYears`). **Si tu remplis le formulaire et obtiens une erreur inattendue à la création du compte, montre-moi le message affiché** (il apparaîtra dans un bandeau rouge en haut du formulaire) — je corrigerai les noms de champs immédiatement, c'est un ajustement mineur.

## Après validation

Prochain écran (avec ta validation) : la vérification par email (code à 6 chiffres), puis mot de passe oublié.

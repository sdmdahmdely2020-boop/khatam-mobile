# Khatam — Application mobile (Flutter)

Application mobile pour Khatam, connectée au backend existant
`khatam-backend` (déjà en production, même API que le site web actuel).

## ⚠️ Important avant de démarrer

Ce projet a été écrit à la main (fichiers `pubspec.yaml` et `lib/`) dans un
environnement où le SDK Flutter n'a **pas pu être installé** (le
téléchargement du moteur Flutter est bloqué par les restrictions réseau de
cet environnement). Le code suit des schémas Flutter/Dart standards et a été
relu avec attention, mais **n'a pas pu être compilé ni exécuté avant
livraison**. Suis les étapes ci-dessous, et si `flutter run` ou
`flutter analyze` signale une erreur, envoie-moi le message d'erreur exact
et je corrige immédiatement.

## Mise en route

Ce dossier contient uniquement le code applicatif (`lib/`) et `pubspec.yaml`
— pas les dossiers `android/`, `ios/`, etc. (générés automatiquement par
Flutter, inutile de les écrire à la main). Pour démarrer :

1. Installer le SDK Flutter si ce n'est pas déjà fait : https://docs.flutter.dev/get-started/install
2. Créer un nouveau projet Flutter vide :
   ```
   flutter create --org com.khatam khatam_app
   cd khatam_app
   ```
3. Remplacer le `pubspec.yaml` généré par celui fourni ici (ou fusionner la
   section `dependencies`).
4. Copier le dossier `lib/` fourni ici par-dessus celui généré (remplace le
   `lib/main.dart` par défaut).
5. Récupérer les dépendances :
   ```
   flutter pub get
   ```
6. Lancer l'application (téléphone/émulateur Android connecté) :
   ```
   flutter run
   ```

## Structure du projet

```
lib/
  main.dart                          Point d'entrée
  app.dart                           MaterialApp, thème, injection des providers
  core/
    api/api_client.dart              Client HTTP générique vers l'API Khatam
    storage/local_storage.dart       Jeton de connexion + identifiant d'appareil
    theme/app_theme.dart             Thème Material 3 (palette bleu/vert)
  features/
    auth/
      models/auth_user.dart
      services/auth_service.dart     Appels réseau (login, etc.)
      state/auth_state.dart          État partagé (Provider/ChangeNotifier)
      screens/login_screen.dart      Écran de connexion (Phase 1)
```

Voir `ROADMAP.md` pour l'avancement complet, écran par écran.

## Dépôt Git

Cette session n'a pas d'accès `git push` vers GitHub — le code est livré en
fichiers/zip comme pour le reste du projet Khatam. Pour créer le nouveau
dépôt : crée un dépôt vide sur GitHub (ex. `khatam-mobile`), puis sur ton
ordinateur (une fois les étapes "Mise en route" ci-dessus terminées) :
```
git init
git add .
git commit -m "Écran de connexion (Phase 1)"
git remote add origin https://github.com/<ton-compte>/khatam-mobile.git
git push -u origin main
```
Le site web actuel (`khatam-site`, `khatam-backend`) reste inchangé et
continue de tourner normalement en parallèle — ce nouveau projet est
totalement indépendant, juste connecté au même backend.

# Khatam — Icône de l'application

## Ce qui a été ajouté

Le vrai logo Khatam comme icône de l'app (au lieu de l'icône Flutter par
défaut) — sur l'écran d'accueil du téléphone, dans les paramètres, partout où
Android affiche l'icône de l'app. Utilise le paquet `flutter_launcher_icons`,
qui génère automatiquement toutes les tailles nécessaires (et l'icône
"adaptative" moderne, qui s'adapte à la forme imposée par le launcher :
rond, carré arrondi, etc.) à partir des images déjà présentes dans la charte
graphique (lot 1).

## Ce zip contient un dossier `assets/` en plus de `lib/`

Comme pour l'écran d'accueil et les icônes de matière : ce zip ajoute des
fichiers dans `assets/branding/png/` (3 nouvelles images). Même méthode que
les fois précédentes — sélectionne tout le contenu du zip extrait et
colle-le dans ton dossier `khatam_app`, en choisissant "Remplacer" quand
Windows le demande.

## Étape supplémentaire, uniquement pour cette livraison

Contrairement aux livraisons précédentes, il y a une commande de plus à
lancer une seule fois pour que l'icône soit vraiment créée (Flutter ne le
fait pas tout seul, il faut le demander explicitement) :

1. Colle le contenu du zip dans ton projet (voir ci-dessus).
2. Dans le terminal du projet, lance dans l'ordre :
   ```
   flutter pub get
   dart run flutter_launcher_icons
   ```
   La deuxième commande affiche plusieurs lignes "Creating..." — c'est normal,
   c'est elle qui fabrique toutes les tailles d'icône nécessaires. Ça prend
   quelques secondes.
3. Lance `flutter analyze` et envoie-moi une capture du résultat.
4. Reconstruis l'app :
   ```
   flutter build apk --release
   ```
5. Renvoie `app-release.apk` (même chemin qu'avant :
   `build\app\outputs\flutter-apk\app-release.apk`) vers ta tablette et
   réinstalle par-dessus. La nouvelle icône doit apparaître sur l'écran
   d'accueil dès l'installation terminée.

## Rappel : le correctif de connexion internet (à faire si pas encore fait)

Si ce n'est pas déjà fait, ajoute aussi cette ligne dans
`android\app\src\main\AndroidManifest.xml`, juste après la ligne de la
permission caméra :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
Sans elle, l'app ne peut pas du tout contacter le serveur (message "Impossible
de contacter le serveur"). Ce correctif est indépendant de la livraison de
l'icône — les deux peuvent être faits en même temps avant de reconstruire
l'APK.

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran/terminal concerné, avec la trace
complète depuis le tout début en cas d'erreur.

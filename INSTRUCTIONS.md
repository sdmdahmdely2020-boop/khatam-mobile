# Khatam — Bandeau publicitaire (publicités locales) dans l'app mobile

## Ce qui a été ajouté

Le carrousel de publicités locales (annonceurs mauritaniens, celui que tu
gères déjà depuis `admin.html`) — jusqu'ici, il existait uniquement sur le
site web. Il s'affiche maintenant aussi dans l'application mobile, à deux
endroits, exactement comme sur le site :

- En haut du **catalogue** (élève), juste au-dessus de la liste des
  documents.
- En haut de **"Mes documents"** (professeur), juste en dessous de la barre
  du haut.

Il défile automatiquement toutes les 6 secondes s'il y a plusieurs annonces
actives, avec des petits points en dessous pour indiquer laquelle est
affichée. Toucher une annonce ouvre son lien dans le navigateur du
téléphone.

## Pourquoi tu ne le voyais pas jusqu'ici dans l'app

Ce n'était pas un bug : ce bandeau n'existait tout simplement pas encore
dans le code de l'application (seulement sur le site web). C'est corrigé
avec cette livraison.

**Une fois installé, le bandeau restera quand même invisible tant que tu
n'auras créé aucune annonce active** (via `admin.html`, comme pour le site)
— c'est le comportement normal, pas une erreur. Dès qu'une annonce existe
pour la zone `catalog` ou `dashboard`, elle apparaît automatiquement, sans
rien à changer côté app.

## Ce zip contient une nouvelle dépendance (`pubspec.yaml`)

Contrairement aux dernières livraisons (statistiques, icône), celle-ci
ajoute un nouveau paquet : `url_launcher` (pour ouvrir le lien d'une
annonce). Il faut donc bien relancer `flutter pub get` après avoir collé
le contenu du zip — aucun nouveau dossier `assets/` cette fois, juste
`lib/` et `pubspec.yaml`.

1. Colle le contenu du zip dans ton projet (méthode habituelle : tout
   sélectionner dans le zip extrait, coller dans ton dossier `khatam_app`,
   "Remplacer" quand Windows le demande).
2. Dans le terminal du projet :
   ```
   flutter pub get
   flutter analyze
   ```
3. Envoie-moi une capture du résultat de `flutter analyze`.
4. Reconstruis l'app (`flutter build apk --release` si tu testes sur ta
   tablette, ou redémarre complètement l'app si tu testes sur Chrome).
5. Vérifie que le bandeau apparaît bien en haut du catalogue ET en haut de
   "Mes documents" (professeur) — vide au départ tant qu'aucune annonce
   n'est créée, c'est normal (voir ci-dessus).

## Pour voir une vraie publicité s'afficher

Va dans `admin.html` (site web), section publicités, et crée une annonce
avec une zone `catalog` ou `dashboard` (les deux si tu veux qu'elle
apparaisse aux deux endroits). Elle doit apparaître dans l'app dans les
secondes qui suivent (rafraîchis l'écran si besoin).

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran/terminal concerné, avec la trace
complète depuis le tout début en cas d'erreur.

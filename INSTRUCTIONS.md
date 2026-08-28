# Khatam — Correctif n°2 : page blanche sur la fiche document (vraie cause trouvée)

## Ce qui s'est passé

Le premier correctif (remplacer `AspectRatio` par un `SizedBox`) n'a pas suffi — merci d'avoir renvoyé la capture du terminal avec la trace complète, ça a permis de trouver la vraie cause cette fois.

## La vraie cause

Dans le bloc "Prix / bouton" en bas de la fiche, le bouton **"Ouvrir"/"Débloquer"** était placé directement à côté du prix dans une ligne horizontale (`Row`), sans largeur définie. Sur Flutter Web, dans cette configuration précise, le calcul interne de la taille du bouton peut planter (bug connu du moteur Flutter Web en mode debug) — c'est exactement ce que montrait la trace que tu as envoyée : l'erreur se produit pile au moment de calculer la taille du bouton "Débloquer" (`document_detail_screen.dart:273`).

## Le correctif

Le bloc "Prix / bouton" est réorganisé : le prix reste en haut, et le bouton passe maintenant sur toute la largeur en dessous (au lieu d'être à côté du prix), avec une taille explicite. Ça règle le problème à la racine et ça donne même un bouton plus visible/plus facile à toucher sur téléphone.

**Un seul fichier a changé** (en plus du correctif n°1 déjà inclus) : `lib/features/catalog/screens/document_detail_screen.dart`.

## Comment installer ce correctif

1. Dans `khatam_app`, supprime le dossier `lib` actuel (ou renomme-le en `lib_old3`).
2. Copie le dossier `lib` de ce zip à la place.
3. `flutter pub get` puis `flutter analyze` — envoie-moi le résultat s'il y a des erreurs (normalement rien de nouveau).
4. **Important** : arrête complètement l'app (Ctrl+C ou le bouton stop rouge), puis relance avec `flutter run` — pas de hot reload.
5. Reconnecte-toi, va sur le catalogue, clique sur le document "math" → la fiche doit maintenant s'afficher complètement (aperçu, titre, infos, prix, et le bouton "Débloquer" en bas, sur toute la largeur).

## Si ça ne marche toujours pas

Renvoie-moi encore une fois : une capture du haut du bloc d'erreurs dans le terminal (comme la dernière fois, ça a été très utile), et une capture de l'écran du document. On continue jusqu'à ce que ça marche.

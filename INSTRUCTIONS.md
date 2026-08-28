# Khatam — Nouvelle livraison : icônes de matière

## Ce qui a été ajouté

Une petite icône ronde (colorée) apparaît maintenant à côté de chaque matière
partout où elle est affichée : le catalogue, tes favoris, "Mes documents"
(côté professeur), et la fiche détaillée d'un document. Ce sont les mêmes
icônes déjà livrées (lot 3) : Mathématiques, Physique, Chimie, SVT, Arabe,
Français, Anglais, Philosophie, Histoire-Géographie.

Comme le champ "matière" est écrit librement par le professeur au moment de
l'envoi du document (pas une liste figée), la bonne icône est retrouvée
automatiquement en reconnaissant des mots-clés dans le texte tapé (par
exemple "Maths", "Mathématiques" ou "math" affichent tous la même icône) —
insensible aux accents et aux majuscules/minuscules. Si aucune matière
connue n'est reconnue dans le texte, une icône neutre (petit livre) s'affiche
à la place, pour ne jamais rien casser.

## Ce zip contient aussi un dossier `assets/` (comme la livraison précédente)

Même remarque que pour l'écran d'accueil : en plus de `lib/` et
`pubspec.yaml`, il y a un dossier `assets/subjects/` à copier à la racine de
ton projet (à côté de `lib/`, pas dedans) — ou à fusionner s'il existe déjà
un dossier `assets/` chez toi. Tu peux faire comme la dernière fois : tout
sélectionner dans le zip extrait et coller directement dans ton dossier
`khatam_app`, en choisissant "Remplacer les fichiers/dossiers dans la
destination" quand Windows te le demande.

## Comment installer cette livraison

1. Extrais ce zip.
2. Sélectionne tout son contenu (`lib`, `pubspec.yaml`, `assets`,
   `INSTRUCTIONS.md`, `ROADMAP.md`) et colle-le dans ton dossier
   `khatam_app`, en remplaçant quand Windows le demande.
3. Ouvre un terminal dans le projet, lance :
   ```
   flutter pub get
   flutter analyze
   ```
4. Envoie-moi une capture du résultat de `flutter analyze`.
5. Si c'est propre, arrête complètement l'app et relance avec `flutter run`.
6. Va dans le catalogue (ou "Mes documents" si tu es connecté en professeur)
   : chaque document doit maintenant afficher une petite icône colorée à
   côté du nom de la matière.

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran concerné, et si le terminal
affiche une erreur, la trace complète depuis le tout début.

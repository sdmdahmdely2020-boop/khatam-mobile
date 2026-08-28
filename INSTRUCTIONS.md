# Khatam — Nouvelle livraison : écran d'accueil (onboarding)

## Ce qui a été ajouté

L'écran d'accueil en 3 pages, avec les illustrations déjà livrées (lot 2) :

1. **"Bienvenue sur Khatam"** — présentation générale de l'app.
2. **"Trouvez vos documents"** — filtrage par série, année, matière.
3. **"Débloquez et réussissez"** — paiement Bankily/Masrivi/Sedad.

Il s'affiche **une seule fois**, à la toute première ouverture de l'app sur un
téléphone donné — juste avant l'écran de connexion. Un bouton "Passer" en
haut à droite permet de le sauter à tout moment, et le bouton en bas devient
"Commencer" sur la dernière page. Une fois vu (ou passé), l'app se souvient
que cet appareil l'a déjà vu et va directement à l'écran de connexion à
chaque prochain lancement — pas besoin de le revoir à chaque fois.

## Important : ce zip contient un NOUVEAU dossier `assets/` (pas seulement `lib/`)

Contrairement aux livraisons précédentes (où il suffisait de remplacer
`lib/`), celle-ci ajoute aussi les 3 images de l'écran d'accueil. Il faut
donc, en plus de remplacer `lib/` comme d'habitude :

1. Ouvre ce zip et regarde s'il contient un dossier `assets/onboarding/` (avec
   3 images `.png` dedans, et un sous-dossier `2.0x/`).
2. Dans ton projet `khatam_app`, s'il existe déjà un dossier `assets/` à la
   racine (à côté de `lib/`, `android/`, etc.) : copie simplement le
   sous-dossier `onboarding/` de ce zip à l'intérieur (donc tu auras
   `assets/onboarding/` en plus de ce qui existe déjà, comme
   `assets/branding/`).
3. S'il n'existe pas encore de dossier `assets/` à la racine de ton projet :
   copie tout le dossier `assets/` de ce zip directement à la racine de ton
   projet (au même niveau que `lib/`, pas à l'intérieur de `lib/`).
4. Remplace aussi `pubspec.yaml` par celui de ce zip (une ligne a été ajoutée
   pour déclarer ce nouveau dossier d'images).

Si tu n'es pas sûr de ce que tu as déjà dans ton dossier `assets/`, envoie-moi
une capture de l'explorateur de fichiers (ou de l'arborescence dans Android
Studio) et je te dis exactement quoi faire.

## Comment installer cette livraison

1. Dans `khatam_app`, supprime le dossier `lib` actuel (ou renomme-le), puis
   copie le dossier `lib` de ce zip à la place.
2. Ajoute le dossier `assets/onboarding/` (voir ci-dessus, étape importante).
3. Remplace `pubspec.yaml` par celui de ce zip.
4. Lance `flutter pub get`.
5. Lance `flutter analyze` et envoie-moi une capture du résultat avant de
   tester (ça permet de repérer tout de suite un souci éventuel).
6. **Important** : arrête complètement l'app (pas de rechargement à chaud),
   puis relance avec `flutter run`.
7. Pour retester l'écran d'accueil plusieurs fois (puisqu'il ne s'affiche
   qu'une seule fois normalement) : désinstalle complètement l'app du
   téléphone/Chrome puis relance — ça efface la mémoire "déjà vu" et
   l'écran d'accueil réapparaît.

## Si quelque chose ne marche pas

Comme d'habitude : envoie-moi une capture de l'écran concerné, et si le
terminal affiche une erreur, la trace complète depuis le tout début (pas
seulement les dernières lignes) — c'est ce qui permet de trouver la vraie
cause rapidement.

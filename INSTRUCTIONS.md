# Khatam — Nouvelle livraison : envoi de document, portefeuille, correction IA

## Troisième correctif (`flutter analyze` a trouvé une nouvelle version du paquet `file_picker`)

Ton `flutter pub get` a installé une version encore plus récente du paquet
`file_picker` que celle utilisée pour préparer le correctif précédent — cette
nouvelle version a retiré `.bytes` (accès direct aux octets) et le paramètre
`withData`, et impose de lire le fichier avec `readAsBytes()` (une méthode
qui prend un court instant, comme un petit chargement). Corrigé dans les deux
mêmes fichiers (`upload_document_screen.dart`, `ai_grading_screen.dart`) —
**utilise bien ce zip-ci**, c'est la version à jour. Aucune autre étape
d'installation ne change, pas besoin de relancer `flutter pub get` (le
`pubspec.yaml` n'a pas changé).

## Deuxième correctif (le fichier ne se sélectionnait pas dans Chrome)

Sur Chrome (web), le navigateur ne donne jamais le "chemin" réel d'un
fichier choisi (`PlatformFile.path` restait toujours `null`), donc le
fichier semblait bien choisi (son nom s'affichait) mais l'envoi échouait
systématiquement. Corrigé en envoyant directement le contenu du fichier
(ses octets) plutôt que son chemin — fonctionne maintenant aussi bien sur
Chrome (test) que sur un vrai téléphone Android (usage final). **Utilise ce
zip-ci**, il contient ce correctif en plus du précédent.

## Correctif appliqué (`flutter analyze` a trouvé 2 vraies erreurs, corrigées)

Le paquet `file_picker` (version installée par `flutter pub get`) utilise une
API différente de celle utilisée dans la toute première version de ce zip —
`FilePicker.platform.pickFiles(...)` n'existe plus, remplacé par
`FilePicker.pickFile(...)` (méthode statique directe). Corrigé dans les deux
fichiers concernés (`upload_document_screen.dart`, `ai_grading_screen.dart`)
— **utilise bien ce zip-ci (pas une version précédente)**, il contient déjà
le correctif. Aucune autre étape d'installation ne change.

## Ce qui a été ajouté

Trois nouvelles fonctionnalités dans l'app, comme demandé :

1. **Envoi d'un document directement depuis l'app** (professeur) — avant, il fallait passer par le site web. Maintenant, sur l'écran "Mes documents", un bouton **"Nouveau document"** ouvre un formulaire complet (titre, matière, série, année, type, prix ou gratuit, déblocage par pub, correction IA activée ou non) avec le choix du fichier PDF depuis le téléphone.

2. **Portefeuille professeur** — une icône (portefeuille) en haut de l'écran "Mes documents" ouvre un nouvel écran avec le solde disponible, l'historique des ventes confirmées, et un bouton **"Demander un retrait"** (Bankily / Masrivi / Sedad — comme sur le site web, le virement réel reste fait à la main par un administrateur, ce n'est pas automatique).

3. **Correction IA côté élève** — sur la fiche d'un document où la correction IA est activée par le professeur, une fois le document débloqué, un bloc **"Correction IA disponible"** apparaît avec un bouton "Faire corriger ma copie". L'élève peut prendre une photo, choisir une photo/un PDF depuis son téléphone, ou taper directement sa réponse — l'IA compare avec le corrigé officiel du professeur et renvoie une note sur 20 avec un avis détaillé (points forts / points à travailler). Un historique complet ("Mes corrections IA") est accessible depuis cette même fiche ou depuis "Mon compte".

## Un point important : la permission caméra (à faire une seule fois)

Pour que "Prendre une photo" fonctionne sur Android, il faut ajouter une ligne dans un fichier qui n'est pas inclus dans ce zip (il est généré automatiquement par Flutter et propre à ton installation) :

1. Ouvre le fichier `android/app/src/main/AndroidManifest.xml` dans ton projet.
2. Juste avant la ligne `<application`, ajoute :
   ```xml
   <uses-permission android:name="android.permission.CAMERA"/>
   ```
3. Enregistre. Cette étape ne se fait qu'une seule fois — pas besoin de la refaire aux prochaines livraisons.

Si tu ne veux pas gérer cette étape tout de suite, ce n'est pas bloquant : "Choisir une photo" (galerie) et "Choisir un PDF" fonctionnent sans cette permission, seul "Prendre une photo" (appareil photo) en a besoin.

## Comment installer cette livraison

1. Dans `khatam_app`, supprime le dossier `lib` actuel (ou renomme-le en `lib_old4`).
2. Copie le dossier `lib` de ce zip à la place.
3. Remplace aussi `pubspec.yaml` par celui de ce zip (deux nouveaux paquets ont été ajoutés : `image_picker` pour les photos, et un petit ajustement pour l'envoi de fichiers).
4. Ajoute la permission caméra dans `AndroidManifest.xml` (voir ci-dessus).
5. Lance `flutter pub get`.
6. **Important** : arrête complètement l'app (pas de hot reload), puis relance avec `flutter run`.
7. Teste dans cet ordre :
   - Connecte-toi en professeur → "Mes documents" → "Nouveau document" → remplis le formulaire, choisis un PDF, envoie.
   - Sur "Mes documents", clique l'icône portefeuille en haut → vérifie que le solde et l'historique s'affichent, essaie "Demander un retrait".
   - Connecte-toi en élève, ouvre un document dont la correction IA est activée (coche-la lors de l'envoi ci-dessus si besoin) et débloque-le → le bloc "Correction IA disponible" doit apparaître → essaie d'envoyer une photo ou un texte tapé.

## Si quelque chose ne marche pas

Comme d'habitude : envoie-moi une capture de l'écran concerné, et si le terminal affiche une erreur, la trace complète depuis le tout début (pas seulement les dernières lignes) — c'est ce qui permet de trouver la vraie cause rapidement.

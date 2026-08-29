# Khatam — Application mobile : nouvel écran "Mon profil" (29/08)

## Contexte

Tu as demandé un écran de profil regroupant les informations de l'élève, son
abonnement et ses documents déjà débloqués, en cartes propres, accessible
depuis l'accueil. C'est fait — aucun changement côté serveur.

## Ce qui est nouveau

Un nouvel écran **"Mon profil"**, avec trois cartes qui s'enchaînent :

1. **Identité** : nom complet et numéro de téléphone de l'élève connecté.

2. **Abonnement** : le plan actuel (Free / Basic / Premium) avec un badge
   coloré — gris pour Free, bleu pour Basic, vert pour Premium — et, si un
   abonnement payant est actif, sa date d'expiration ("Expire le
   JJ/MM/AAAA"). Si l'élève n'est pas encore Premium, un bouton
   ("Devenir Premium" ou "Passer à Premium" pour un abonné Basic) mène
   directement vers les formules d'abonnement.

3. **Documents débloqués** : la liste des documents que l'élève a
   effectivement achetés ou débloqués par publicité, chacun dans sa propre
   carte (vignette, titre, matière, série, comment il a été débloqué et
   quand). Un message adapté s'affiche s'il n'y a encore rien.

## Comment y accéder

Une nouvelle icône (un badge) a été ajoutée en haut de l'écran d'accueil,
entre l'icône "Favoris" et l'icône "Mon compte". Elle ouvre directement
"Mon profil".

## Ce qui n'a PAS changé

- **Aucun changement côté serveur** — cet écran réutilise deux informations
  déjà disponibles (l'abonnement et les documents débloqués), simplement
  présentées ensemble différemment.
- L'écran "Mon compte" existant n'a pas été touché — il garde son rôle
  (déconnexion, accès aux corrections IA, etc.). Les deux écrans coexistent.
- Rien d'autre sur l'accueil n'a changé, à part la nouvelle icône.

## Installation

Comme d'habitude : seul le dossier `lib/` change, aucun nouveau paquet à
ajouter.

1. Colle le contenu de ce zip dans ton projet (remplace `lib/`).
2. `flutter pub get` par précaution.
3. `flutter analyze` — des lignes "info" (style) sont normales, seule une
   ligne "error" en rouge demanderait une correction.
4. Redémarre complètement l'application (ferme-la depuis les applications
   récentes puis rouvre-la, ou relance "Run").
5. Connecte-toi avec un compte élève, et sur l'accueil, appuie sur la
   nouvelle icône "badge" en haut : tu dois voir tes informations, ton
   abonnement, et tes documents débloqués.

## Et après ?

Dis-moi si tu veux ajuster un détail sur cet écran (par exemple ajouter une
photo de profil, ou permettre de modifier le numéro de téléphone), ou passer
à autre chose du plan plus large (profil public d'un professeur,
modification du prix d'un document depuis l'app, boost, messagerie avec
l'administrateur...).

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran/terminal concerné, avec la trace
complète depuis le tout début en cas d'erreur.

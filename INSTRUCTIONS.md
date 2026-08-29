# Khatam — Application mobile : accueil élève amélioré (29/08)

## Contexte

Tu as demandé quatre ajouts précis sur l'écran d'accueil de l'élève, sans
toucher au serveur et sans rien casser de l'existant. C'est fait — voici le
détail.

## Ce qui est nouveau sur l'écran d'accueil (élève)

1. **Badge de plan** : à côté de "Bonjour, [prénom]", un petit badge coloré
   indique le plan actuel — gris pour "Free", bleu pour "Basic", vert pour
   "Premium".

2. **Cadenas sur les documents verrouillés** : un document payant que
   l'élève n'a pas encore débloqué affiche maintenant une petite icône de
   cadenas sur sa vignette, et une étiquette verte "Inclus dans Premium" à
   côté du prix — pour bien montrer qu'un abonnement Premium donnerait
   accès à ce document sans payer à l'unité.

3. **Bouton "Devenir Premium"** : le bandeau qui invite à s'abonner (déjà
   présent) a maintenant un vrai bouton vert "Devenir Premium" bien visible,
   en plus du bandeau cliquable. Un élève déjà abonné Premium ne voit pas ce
   bouton (il n'en a pas besoin).

4. **Bloc "Ma progression"** : un nouveau bloc juste en dessous du bandeau
   d'abonnement montre, pour les matières les plus présentes dans le
   catalogue, une barre de progression avec le pourcentage de documents déjà
   accessibles à l'élève (gratuits, achetés, débloqués par pub, ou couverts
   par Premium). Par exemple "Mathématiques — 60 %".

## Ce qui n'a PAS changé

- **Aucun changement côté serveur** — cette livraison ne touche que
  l'application mobile, comme demandé.
- La disposition générale de l'écran, la recherche, les filtres par série,
  la "Sélection de la semaine" et le bandeau publicitaire fonctionnent
  exactement comme avant, rien n'a été retiré ni déplacé.
- Les couleurs utilisées sont les couleurs déjà existantes de l'application
  (bleu et vert Khatam) — aucune nouvelle couleur introduite.

## Installation

Comme d'habitude : seul le dossier `lib/` change, aucun nouveau paquet à
ajouter.

1. Colle le contenu de ce zip dans ton projet (remplace `lib/`).
2. `flutter pub get` par précaution.
3. `flutter analyze` — des lignes "info" (style) sont normales, seule une
   ligne "error" en rouge demanderait une correction.
4. Redémarre complètement l'application (ferme-la depuis les applications
   récentes puis rouvre-la, ou relance "Run").
5. Connecte-toi avec un compte élève et regarde l'écran d'accueil :
   - le badge de plan à côté de "Bonjour",
   - un cadenas sur un document payant non débloqué,
   - le bouton "Devenir Premium" dans le bandeau,
   - le bloc "Ma progression" avec les barres par matière.

## Et après ?

Cette étape clôt la demande précise que tu avais donnée pour l'accueil
élève. Dis-moi si tu veux ajuster un détail (couleurs, matières affichées,
etc.) ou passer à autre chose du plan plus large (profil public d'un
professeur, modification du prix d'un document depuis l'app, boost,
messagerie avec l'administrateur...).

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran/terminal concerné, avec la trace
complète depuis le tout début en cas d'erreur.

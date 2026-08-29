# Khatam — Application mobile branchée sur les abonnements (29/08)

## Contexte

Comme convenu après la livraison du panneau admin ("après ça, on continue
avec l'écran d'accueil de l'application mobile"), voici l'application
connectée au système d'abonnement Basic/Premium qui tourne déjà sur ton
serveur (Render) et que tu peux gérer depuis `admin.html`.

Rappel important : ce système **s'ajoute** à l'achat de document à l'unité,
il ne le remplace pas. Un élève peut toujours acheter un document tout seul
sans jamais s'abonner — rien ne change pour lui s'il ne le souhaite pas.

## Ce qui est nouveau dans l'application

1. **Écran "Mon abonnement"** — accessible depuis "Mon compte" (nouveau
   bouton vert, juste au-dessus de "Mes corrections IA"). Affiche :
   - le plan actuellement actif de l'élève (Gratuit / Basic / Premium) et sa
     date d'expiration si abonné ;
   - les deux formules Basic et Premium, avec le prix, la durée et la
     réduction — toujours les valeurs que TU as configurées dans
     `admin.html`, jamais des chiffres fixés dans l'application ;
   - un bouton pour souscrire (ou renouveler), qui ouvre le même circuit de
     paiement que pour un document : numéro Bankily/Masrivi/Sedad affiché,
     l'élève colle son numéro de reçu, puis attend TA confirmation manuelle
     dans `admin.html` (jamais automatique).
   - Si un élève est déjà Premium, le bouton Basic devient "Inclus dans
     Premium" (grisé) — Premium contient déjà tout ce que propose Basic.

2. **Accueil élève** — juste sous les filtres de série, un bandeau indique :
   - "Passez à Basic ou Premium" pour un élève non abonné (touche le bandeau
     pour ouvrir l'écran d'abonnement) ;
   - "Abonnement Basic actif" ou "Abonnement Premium actif" sinon.
   - Un abonné **Premium** ne voit plus jamais le bandeau publicitaire du
     catalogue — retiré automatiquement, pas juste caché.

3. **Prix réduit pour un abonné Basic** — partout où un prix de document
   s'affiche (carte du catalogue, fiche document, écran de déblocage), un
   élève Basic voit désormais le prix réduit à côté de l'ancien prix barré,
   avec la mention "Prix réduit — abonnement Basic". C'est aussi ce montant
   réduit qui est réellement débité au moment du paiement — jamais l'ancien
   prix affiché par erreur puis un montant différent demandé.

## Ce qui n'a PAS changé

- L'achat d'un document à l'unité, sans abonnement : identique à avant,
  aucune régression.
- La confirmation des paiements reste TOUJOURS manuelle, faite par toi dans
  `admin.html` — l'application ne débloque et n'active jamais rien toute
  seule.
- Rien côté serveur n'a besoin d'être retouché pour cette livraison : le
  backend et `admin.html` que tu as déjà déployés le 29/08 fonctionnent tels
  quels avec cette nouvelle version de l'application.

## Installation

Comme pour les dernières livraisons : seul le dossier `lib/` change, aucun
nouveau paquet à ajouter dans `pubspec.yaml`.

1. Colle le contenu de ce zip dans ton projet (remplace `lib/`).
2. `flutter pub get` par précaution.
3. `flutter analyze` — envoie-moi le résultat s'il signale quoi que ce soit.
4. Redémarre complètement l'application (pas de hot reload) et regarde :
   - "Mon compte" → "Mon abonnement" s'affiche bien et charge les prix ;
   - l'accueil élève affiche le bon bandeau ;
   - souscris un abonnement de test, confirme-le dans `admin.html`, puis
     vérifie que l'application affiche bien le nouveau plan et (pour
     Premium) que les publicités disparaissent de l'accueil, ou (pour
     Basic) que le prix réduit apparaît sur un document payant.

## Étapes suivantes (comme convenu, PAS encore construites)

D'après le plan initial que tu avais donné avant le pivot vers les
abonnements : le **profil élève** (documents déjà achetés, progression
simple), puis la présentation du catalogue professeur. On continue dans cet
ordre dès que tu as validé cette livraison, sauf si tu préfères changer de
priorité.

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran/terminal concerné, avec la trace
complète depuis le tout début en cas d'erreur.

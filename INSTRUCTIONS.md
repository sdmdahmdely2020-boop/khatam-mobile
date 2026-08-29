# Khatam — Application mobile : "Mes documents" (profil élève, 29/08)

## Contexte

Comme convenu après la validation des abonnements ("parfait tout fonctionne
normal" sur ta tablette) : voici le profil élève — la première des deux
étapes restantes (documents achetés + progression simple, puis le catalogue
professeur).

**Important : installe d'abord le zip backend séparé
(`khatam-backend-mes-documents-2908.zip`)** avant celui-ci — l'application a
besoin de la nouvelle route serveur pour fonctionner.

## Ce qui est nouveau dans l'application

**Nouvel écran "Mes documents"** — accessible depuis "Mon compte" (nouveau
bouton bleu, juste au-dessus de "Mon abonnement"). Il affiche :

1. **Un résumé en haut** : nombre de documents débloqués, total dépensé en
   MRU, un badge si tu es abonné Basic/Premium, et une répartition par
   matière (ex. "Mathématiques · 3", "Physique · 2").
2. **La liste des documents** que l'élève a réellement débloqués — achat
   confirmé ou publicité regardée, avec une étiquette qui indique comment
   ("Acheté · 300 MRU" ou "Débloqué par pub") et la date. Toucher un document
   ouvre sa fiche complète, comme partout ailleurs dans l'app.
3. **Si la liste est vide** : un message adapté — pour un élève qui n'a rien
   acheté, une invitation à aller voir le catalogue ; pour un abonné Premium
   qui n'a rien acheté individuellement, une explication que c'est normal
   (son abonnement lui donne déjà accès à tout le catalogue, donc cette
   liste-là peut rester vide même s'il utilise beaucoup l'application).

## Ce qui n'a PAS changé

- Rien dans le catalogue, les paiements, ou les abonnements n'a été touché.
- Aucune nouvelle donnée à saisir : cet écran ne fait qu'afficher ce qui
  existe déjà dans ton système (achats et déblocages publicité).

## Installation

Comme pour les dernières livraisons : seul le dossier `lib/` change, aucun
nouveau paquet à ajouter dans `pubspec.yaml`.

1. **D'abord**, installe et déploie le zip backend séparé (voir son propre
   `INSTRUCTIONS.md`).
2. Colle le contenu de ce zip dans ton projet (remplace `lib/`).
3. `flutter pub get` par précaution.
4. `flutter analyze` — comme la dernière fois, des lignes "info" (style,
   sans conséquence) sont normales ; seule une ligne "error" (en rouge)
   demanderait une correction. Envoie-moi le résultat si tu vois du rouge.
5. Redémarre complètement l'application (voir le rappel plus bas si besoin)
   et va dans "Mon compte" → "Mes documents". Achète ou débloque un document
   par pub si tu n'en as pas déjà, et vérifie qu'il apparaît bien dans la
   liste avec le bon montant/la bonne étiquette.

### Rappel : comment fermer complètement l'app sur ta tablette

Bouton "applications récentes" (ou glisser depuis le bas et maintenir) →
trouve la carte Khatam → glisse-la pour la fermer. Puis relance-la depuis
l'écran d'accueil, ou relance "Run" dans ton éditeur.

## Étapes suivantes (comme convenu, PAS encore construites)

Il ne reste plus que la présentation du catalogue professeur d'après le plan
initial. On s'y attaque dès que tu as validé cette livraison.

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran/terminal concerné, avec la trace
complète depuis le tout début en cas d'erreur.

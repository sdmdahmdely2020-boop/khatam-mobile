# Khatam — Nouvelle livraison : statistiques avancées (professeur)

## Ce qui a été ajouté

Un nouvel écran "Statistiques", accessible via une icône (📊) en haut de
l'écran "Mes documents" (à côté de l'icône portefeuille), pour un compte
professeur. Il affiche :

- Vues totales, ventes confirmées, revenu total, et un taux de conversion
  estimé (ventes ÷ vues).
- Le document le plus consulté, et celui qui a rapporté le plus.
- Un petit graphique en barres des revenus sur les 6 derniers mois.
- Les vues cumulées par matière (avec les icônes déjà en place).

Aucune nouvelle donnée n'est demandée au serveur : tout est calculé à partir
de ce que l'app récupère déjà (la liste de tes documents, et ton
portefeuille) — pas de changement côté backend nécessaire pour cette
livraison.

## Cette fois, pas de nouveau dossier `assets/`

Contrairement aux deux dernières livraisons, il n'y a que le dossier `lib/`
à remplacer ici (pas d'images à copier). Retour à la méthode simple.

## Comment installer cette livraison

1. Extrais ce zip.
2. Remplace le dossier `lib` de ton projet par celui de ce zip (renomme
   l'ancien en `lib_old6` si tu veux garder une sauvegarde, ou remplace
   directement comme les dernières fois).
3. `pubspec.yaml` n'a pas changé, pas besoin de le remplacer ni de relancer
   `flutter pub get`.
4. Ouvre un terminal dans le projet, lance :
   ```
   flutter analyze
   ```
5. Envoie-moi une capture du résultat.
6. Si c'est propre, arrête complètement l'app et relance avec `flutter run`.
7. Connecte-toi en professeur → "Mes documents" → clique l'icône
   graphique (📊) en haut → vérifie que les statistiques s'affichent.

Note : si tu n'as pas encore de vente confirmée, les chiffres de revenu
seront à 0 et le graphique affichera "Aucun revenu sur cette période" — c'est
normal, ce n'est pas une erreur.

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran concerné, et si le terminal
affiche une erreur, la trace complète depuis le tout début.

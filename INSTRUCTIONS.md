# Khatam — Accueil élève : conversion + motivation (Étape 1, 29/08)

## Contexte

Tu as envoyé un plan complet et ambitieux en 6 volets (élève, professeurs,
monétisation, admin, UI, stratégie de développement). C'est un très bon plan
de croissance — je l'ai organisé et documenté en entier (voir plus bas),
mais comme tu l'as toi-même demandé dans ta stratégie de développement,
**je n'ai construit que l'étape 1 : l'accueil élève**, et je m'arrête là en
attendant ta validation avant de continuer sur le reste.

**Aucun changement côté serveur** dans cette livraison — uniquement
l'application mobile, comme pour les livraisons précédentes.

## Ce qui est nouveau sur l'accueil élève

1. **Message qui parle au bénéfice, pas au produit** : le bandeau et le
   bouton d'abonnement ne disent plus "Devenir Premium" mais **"Réussir mon
   Bac 🚀"**, avec le sous-titre "Accès illimité aux TD et corrigés, sans
   publicité."

2. **Paywall plus clair** : en plus du cadenas déjà présent, l'étiquette sur
   un document verrouillé dit maintenant "🔒 Inclus dans Premium".

3. **Une fenêtre intelligente avant d'ouvrir un document verrouillé** :
   quand un élève touche un document qu'il n'a pas encore débloqué, une
   petite fenêtre s'ouvre d'abord avec le message "Ce document peut t'aider
   à réussir ton examen 🎯", le prix (ou "Inclus dans Premium"), et deux
   boutons — "Réussir mon Bac 🚀" (va vers les abonnements) ou "Voir le
   document" (continue normalement). Rien n'est jamais bloqué, c'est juste
   un rappel au bon moment.

4. **Économies réelles pour un abonné Basic** : un nouveau bloc affiche
   "Vous avez économisé X MRU" — calculé à partir de ce que l'élève a
   vraiment payé ce mois-ci, jamais un chiffre inventé. S'il n'y a encore
   rien économisé ce mois-ci, le bloc ne s'affiche simplement pas (pas de
   "0 MRU" décourageant). Pour un abonné Premium, comme il n'y a plus
   d'achat individuel à suivre une fois abonné, un message différent
   s'affiche à la place ("Accès illimité activé") — j'ai préféré être
   honnête plutôt que d'inventer un montant qu'on ne peut pas mesurer.

5. **Motivation** :
   - **Série de jours 🔥** : compte les jours d'affilée où l'élève ouvre
     l'app. Important à savoir : cette série est stockée uniquement sur son
     téléphone (pas sur le serveur) — si l'élève change de téléphone ou
     réinstalle l'app, elle repart à zéro. Un vrai suivi partagé entre
     appareils demanderait une nouvelle route côté serveur, que je n'ai pas
     construite pour rester à "zéro changement backend" sur cette étape.
   - **Objectif de la semaine 🎯** : "X/2 documents débloqués cette
     semaine", avec une barre de progression. Note : ta demande parlait de
     "chapitres", mais cette notion n'existe pas encore dans les données
     (un document a une matière/série/année, pas un découpage en chapitres)
     — j'ai donc utilisé "documents débloqués" comme équivalent le plus
     proche et mesurable dès maintenant. Dis-moi si tu préfères une autre
     unité.
   - **Progression par matière** : déjà présente depuis la dernière
     livraison, inchangée.

6. **Notifications — la structure seulement, comme demandé explicitement** :
   une nouvelle icône (cloche) sur l'accueil ouvre un écran "Notifications".
   Il est préparé pour recevoir de vraies notifications plus tard (nouveau
   document, rappel de progression, abonnement qui expire), mais pour
   l'instant il reste **volontairement vide** — je n'ai pas voulu créer de
   fausses notifications qui donneraient une impression trompeuse à
   l'élève. Le vrai système (déclenché automatiquement côté serveur) est
   une prochaine étape, si tu le souhaites.

## Ce qui n'a PAS changé

- Aucun changement côté serveur.
- La disposition générale de l'écran (recherche, chips de série, sélection
  de la semaine, publicités, couleurs bleu/vert) — rien retiré, seulement
  de nouveaux blocs ajoutés au bon endroit.

## Le plan complet, pour la suite

J'ai organisé ta demande en 6 volets dans un document séparé, disponible
dans l'espace de travail Claude de ce projet
(`khatam-strategie-croissance-29-08.md`) : professeurs (statut "actif",
classement, suivi des gains mensuels, répartition 70/30), monétisation
(urgence à l'abonnement, upsell), tableau de bord admin (utilisateurs actifs,
abonnements, revenus, top professeurs), et les finitions UI/UX (animations,
hiérarchie visuelle). Rien de tout ça n'est construit — c'est un plan
d'étapes, prêt à être lancé une par une quand tu valides.

## Installation

Comme d'habitude : seul le dossier `lib/` change.

1. Colle le contenu de ce zip dans ton projet (remplace `lib/`).
2. `flutter pub get` par précaution.
3. `flutter analyze` — des lignes "info" (style) sont normales.
4. Redémarre complètement l'application.
5. Connecte-toi avec un compte élève et regarde l'accueil : le nouveau
   texte "Réussir mon Bac 🚀", le bloc série/objectif, touche un document
   verrouillé pour voir la nouvelle fenêtre, et l'icône cloche en haut.

## Et après ?

Dis-moi ce que tu en penses, et si je peux continuer avec la suite du plan
(professeurs, monétisation, admin) — étape par étape, comme prévu.

## Si quelque chose ne marche pas

Comme d'habitude : une capture de l'écran/terminal concerné, avec la trace
complète depuis le tout début en cas d'erreur.

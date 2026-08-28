# Identité visuelle Khatam — Lot 1 : Logo, palette, typographie

Ce lot correspond à la première étape demandée ("logo d'abord") de l'identité
visuelle complète de Khatam. Les lots suivants (illustrations d'onboarding,
puis icônes de matières) arriveront séparément, une fois ce lot validé.

## Concept

**Khatam (ختم)** signifie « sceau » / « cachet » en arabe — l'objet qui
certifie qu'un document est complet, vérifié, officiel. C'est exactement le
rôle de la plateforme : transformer un examen ou une correction en document
**certifié par un professeur**, comme un sceau apposé sur une copie
d'examen. La marque part de cette idée : un sceau officiel (anneau denté à
la manière d'un tampon), avec en son centre une coche — le signe universel
du « vérifié ».

Le trait long de la coche s'incurve légèrement, comme le coin d'une page
qui se tourne : un clin d'œil discret au livre / au document, sans ajouter
un second symbole qui aurait nui à la lisibilité en petite taille (favicon,
icône d'app).

## Palette

| Rôle | Nom | Hex | Usage |
|---|---|---|---|
| Primaire | Bleu Khatam | `#1E5FA8` | Couleur d'action principale, déjà utilisée dans l'app Flutter et le site |
| Primaire (foncé) | Bleu profond | `#143F73` | Dégradés, fond du splash, texte sur fond clair à forte lisibilité |
| Secondaire | Vert Khatam | `#1E8A4C` | Validation, réussite, clin d'œil au vert du drapeau mauritanien |
| Secondaire (foncé) | Vert profond | `#146238` | Dégradés, fond du splash |
| Accent | Or du sceau | `#D3A039` | **Toujours en petite touche** — anneau du sceau, badges premium/professeur vérifié, jamais en fond ou en grande surface |
| Neutre — encre | Encre Khatam | `#132A45` | Texte principal (titres, wordmark) — un bleu-noir, pas un gris pur |
| Neutre — papier | Papier Khatam | `#F4F7FA` | Fond clair par défaut de l'app/site |
| — | Blanc | `#FFFFFF` | Fond, texte sur fond foncé |

Le bleu et le vert sont ceux déjà en place dans l'app Flutter et le thème
Material 3 (`#1E5FA8` / `#1E8A4C`) — cette identité les reprend tels quels
pour que le site, l'app et la nouvelle marque restent cohérents. L'or est la
seule couleur réellement nouvelle : c'est la couleur du sceau, à réserver
aux moments où quelque chose est *certifié* (anneau du logo, badge
"professeur vérifié", futur badge de réussite côté élève) — jamais comme
couleur de fond ou de bouton générique.

## Typographie

- **Cairo** (700/800, Google Fonts) — titres, logotype, gros chiffres. Police
  bilingue arabe/latin, dessinée pour que les deux écritures cohabitent avec
  le même poids visuel — essentiel pour une plateforme mauritanienne dont
  les utilisateurs lisent aussi bien le français que l'arabe. Son
  dessin géométrique aux terminaisons arrondies fait écho à la forme du
  sceau.
- **Manrope** (500/600, Google Fonts) — texte courant, étiquettes, boutons.
  Grotesque humaniste très lisible en petite taille, complémentaire de
  Cairo sans lui faire concurrence.

Balises à utiliser dans le site (`admin.html`, etc.) :
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@600;700;800&family=Manrope:wght@400;500;600;800&display=swap" rel="stylesheet">
```
Dans Flutter, les deux polices s'ajoutent via `google_fonts` (package déjà
listé comme option dans `pubspec.yaml`, voir plus bas) — pas besoin
d'embarquer les fichiers de police dans l'app.

## Contenu du dossier

```
assets/
  icon-mark.svg                 Le sceau seul — marque principale, toutes tailles ≥ 64px
  favicon.svg                   Version simplifiée (sans dents ni double anneau) pour 16–32px
  lockup-horizontal.svg         Sceau + "Khatam" + sous-titre — en-têtes, barre de nav
  lockup-stacked.svg            Sceau au-dessus de "Khatam" + "ختم" — usages carrés (réseaux sociaux, à propos)
  lockup-reversed.svg           Version blanche/inversée du lockup horizontal — fond foncé uniquement
  icon-adaptive-background.svg  Calque de fond — icône adaptative Android
  icon-adaptive-foreground.svg  Calque de premier plan — icône adaptative Android
  splash.svg                    Écran de démarrage complet (1080×1920)

png/
  icon-mark-192/512/1024.png    Icône d'app (Play Store demande 512, iOS 1024)
  app-icon-1024-square.png      Icône d'app sur fond blanc plein, 1024×1024 (App Store)
  favicon-16/32.png, favicon.ico, favicon-180-apple-touch.png
  adaptive-background/foreground-432.png
  lockup-horizontal.png, lockup-stacked.png, lockup-reversed-on-navy.png
  splash-1080x1920.png
```

## Comment l'intégrer dans l'app Flutter (`khatam_app`)

1. Copier le dossier `assets/` fourni ici dans `khatam_app/assets/branding/`.
2. Dans `pubspec.yaml`, ajouter :
   ```yaml
   flutter:
     assets:
       - assets/branding/
   ```
3. Icône d'application : le plus simple est d'utiliser le package
   `flutter_launcher_icons` — poser `png/icon-mark-1024.png` (fond inclus)
   comme `image_path`, et pour Android en variante adaptative,
   `adaptive_icon_background` (couleur unie `#2569B8` ou le PNG de fond
   fourni) + `adaptive_icon_foreground` (le PNG de premier plan fourni).
4. Écran de démarrage natif : `flutter_native_splash` avec
   `png/splash-1080x1920.png`, ou en reprenant juste les couleurs
   `#1E5FA8` → `#146238` en dégradé si le package choisi ne supporte que les
   fonds unis (dans ce cas, fond uni `#1B6F72`, la teinte médiane du
   dégradé, est le meilleur compromis).

## Comment l'intégrer dans le site web (`khatam-site`)

- Remplacer le favicon actuel par `png/favicon.ico` (+ `favicon-32.png` en
  `<link rel="icon" sizes="32x32">`, `favicon-180-apple-touch.png` en
  `<link rel="apple-touch-icon">`).
- `lockup-horizontal.svg` (ou son export PNG) dans l'en-tête du site,
  `icon-mark.svg` seul si l'espace est trop réduit pour le wordmark.

## Limite de rendu à connaître

Ce dossier a été produit dans un environnement sans accès direct à
`fonts.googleapis.com` — Cairo et Manrope ont donc été récupérés via les
paquets npm `@fontsource/cairo` / `@fontsource/manrope` (les mêmes fichiers
de police, juste distribués différemment) pour pouvoir vérifier visuellement
chaque export PNG avant livraison. Aucun impact sur les fichiers livrés :
les SVG référencent bien `Cairo` / `Manrope` par leur nom standard et
s'afficheront correctement partout où ces polices sont disponibles
(navigateur avec accès internet, `google_fonts` dans Flutter, etc.).

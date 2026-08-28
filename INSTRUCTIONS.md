# Khatam — Mot de passe oublié (Phase 1, écran 4/4 — dernier de la Phase 1 !)

## Ce qu'il y a dans ce zip

- **Le nouvel écran "Mot de passe oublié"** : d'abord un champ email (envoie un code de réinitialisation), puis un champ pour ce code à 6 chiffres + le nouveau mot de passe (deux fois, pour confirmer), avec bouton "Renvoyer le code" (délai de 60s, comme sur l'écran de vérification).
- Le lien "Mot de passe oublié ?" sur l'écran de connexion ouvre maintenant vraiment cet écran.
- Contrat serveur utilisé (déjà vérifié dans le code du backend, cette fois) : `POST /auth/forgot-password {email}` puis `POST /auth/reset-password {email, code, newPassword}`.
- **Point normal à savoir** : par sécurité, le serveur répond toujours "code envoyé" même si l'email ne correspond à aucun compte (pour ne jamais révéler quels emails sont inscrits) — donc si tu testes avec un email qui n'existe pas, l'app passera quand même à l'écran suivant, mais aucun email n'arrivera réellement. Normal, pas un bug.

## Comment l'installer

1. Dans `khatam_app`, supprime le dossier `lib` actuel (ou renomme-le en `lib_old`).
2. Copie le dossier `lib` de ce zip à la place.
3. `flutter pub get` puis `flutter analyze` — envoie-moi le résultat (devrait être 0 issue).
4. Teste : sur l'écran de connexion, clique "Mot de passe oublié ?", tape l'email d'un compte que tu as déjà vérifié, envoie, récupère le code par email, choisis un nouveau mot de passe, puis reconnecte-toi avec.

## 🎉 Avec cet écran, la Phase 1 (authentification complète) est terminée

Connexion, inscription (élève/professeur), vérification par email, mot de passe oublié — les 4 écrans sont construits et le parcours réel a déjà été testé avec succès jusqu'à la vérification. Prochaine étape (avec ta validation) : Phase 2, le catalogue de documents.

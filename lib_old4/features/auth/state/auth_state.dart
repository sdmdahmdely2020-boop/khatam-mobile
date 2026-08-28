import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, success, error }

/// État partagé de l'authentification (Provider/ChangeNotifier).
///
/// Volontairement simple : un seul état "en cours" à la fois, une erreur
/// (avec le code exact du backend pour un traitement fin dans l'UI si
/// besoin), un utilisateur connecté une fois le login réussi.
class AuthState extends ChangeNotifier {
  final AuthService authService;

  AuthState({required this.authService});

  /// Raccourci vers le client HTTP déjà configuré par [authService] — évite
  /// à tout écran hors du module "auth" (ex. le catalogue) de devoir
  /// reconstruire son propre [ApiClient] ou de dépendre de `main.dart`.
  ApiClient get apiClient => authService.apiClient;

  AuthStatus status = AuthStatus.idle;
  String? errorMessage;
  String? errorCode;
  AuthUser? currentUser;

  /// Rempli automatiquement quand une tentative de connexion échoue avec
  /// `EMAIL_NOT_VERIFIED` — permet à l'écran de connexion de rediriger
  /// directement vers l'écran de vérification sans redemander l'email.
  String? pendingVerifyEmail;

  Future<bool> login({required String phone, required String password}) async {
    status = AuthStatus.loading;
    errorMessage = null;
    errorCode = null;
    notifyListeners();

    try {
      currentUser = await authService.login(phone: phone, password: password);
      status = AuthStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      status = AuthStatus.error;
      errorCode = e.code;
      errorMessage = e.message;
      if (e.code == 'EMAIL_NOT_VERIFIED') {
        pendingVerifyEmail = (e.body?['email'] as String?) ?? phone;
      }
      notifyListeners();
      return false;
    } catch (e) {
      status = AuthStatus.error;
      errorCode = 'NETWORK_ERROR';
      errorMessage =
          "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      notifyListeners();
      return false;
    }
  }

  Future<RegisterResult?> registerStudent({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String serie,
  }) async {
    return _runRegister(() => authService.registerStudent(
          fullName: fullName,
          phone: phone,
          email: email,
          password: password,
          serie: serie,
        ));
  }

  Future<RegisterResult?> registerProfessor({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String etablissement,
    required String matieres,
    required int experienceYears,
  }) async {
    return _runRegister(() => authService.registerProfessor(
          fullName: fullName,
          phone: phone,
          email: email,
          password: password,
          etablissement: etablissement,
          matieres: matieres,
          experienceYears: experienceYears,
        ));
  }

  Future<RegisterResult?> _runRegister(
    Future<RegisterResult> Function() call,
  ) async {
    status = AuthStatus.loading;
    errorMessage = null;
    errorCode = null;
    notifyListeners();

    try {
      final result = await call();
      status = AuthStatus.success;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      status = AuthStatus.error;
      errorCode = e.code;
      errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      status = AuthStatus.error;
      errorCode = 'NETWORK_ERROR';
      errorMessage =
          "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      notifyListeners();
      return null;
    }
  }

  /// Vérifie le code à 6 chiffres reçu par email. En cas de succès,
  /// [currentUser] est rempli (le backend renvoie un jeton avec la
  /// vérification, donc le compte est immédiatement connecté).
  Future<bool> verifyEmail({required String email, required String code}) async {
    status = AuthStatus.loading;
    errorMessage = null;
    errorCode = null;
    notifyListeners();

    try {
      currentUser = await authService.verifyEmail(email: email, code: code);
      status = AuthStatus.success;
      pendingVerifyEmail = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      status = AuthStatus.error;
      errorCode = e.code;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      status = AuthStatus.error;
      errorCode = 'NETWORK_ERROR';
      errorMessage =
          "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      notifyListeners();
      return false;
    }
  }

  /// Redemande l'envoi du code par email (inscription). Erreur éventuelle
  /// affichée sans changer [status] en `loading` (évite de désactiver tout
  /// le formulaire pour un simple renvoi de code).
  Future<bool> resendCode({required String email}) async {
    errorMessage = null;
    errorCode = null;
    try {
      await authService.resendCode(email: email);
      return true;
    } on ApiException catch (e) {
      errorCode = e.code;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      errorCode = 'NETWORK_ERROR';
      errorMessage =
          "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      notifyListeners();
      return false;
    }
  }

  /// Demande un code de réinitialisation de mot de passe par email.
  Future<bool> requestPasswordReset({required String email}) async {
    status = AuthStatus.loading;
    errorMessage = null;
    errorCode = null;
    notifyListeners();

    try {
      await authService.forgotPassword(email: email);
      status = AuthStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      status = AuthStatus.error;
      errorCode = e.code;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      status = AuthStatus.error;
      errorCode = 'NETWORK_ERROR';
      errorMessage =
          "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      notifyListeners();
      return false;
    }
  }

  /// Vérifie le code de réinitialisation et applique le nouveau mot de
  /// passe. Ne connecte pas automatiquement.
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    status = AuthStatus.loading;
    errorMessage = null;
    errorCode = null;
    notifyListeners();

    try {
      await authService.resetPassword(email: email, code: code, newPassword: newPassword);
      status = AuthStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      status = AuthStatus.error;
      errorCode = e.code;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      status = AuthStatus.error;
      errorCode = 'NETWORK_ERROR';
      errorMessage =
          "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      notifyListeners();
      return false;
    }
  }

  void resetError() {
    errorMessage = null;
    errorCode = null;
    if (status == AuthStatus.error) status = AuthStatus.idle;
    notifyListeners();
  }

  /// Efface le jeton stocké localement et réinitialise l'état — l'écran
  /// appelant doit ensuite naviguer vers l'écran de connexion en retirant
  /// tout l'historique de navigation (voir [AccountScreen]).
  Future<void> logout() async {
    await authService.logout();
    currentUser = null;
    pendingVerifyEmail = null;
    status = AuthStatus.idle;
    errorMessage = null;
    errorCode = null;
    notifyListeners();
  }
}

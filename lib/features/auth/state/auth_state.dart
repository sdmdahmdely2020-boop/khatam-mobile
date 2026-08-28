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

  AuthStatus status = AuthStatus.idle;
  String? errorMessage;
  String? errorCode;
  AuthUser? currentUser;

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

  void resetError() {
    errorMessage = null;
    errorCode = null;
    if (status == AuthStatus.error) status = AuthStatus.idle;
    notifyListeners();
  }
}

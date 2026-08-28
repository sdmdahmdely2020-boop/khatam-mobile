import '../../../core/api/api_client.dart';
import '../../../core/storage/local_storage.dart';
import '../models/auth_user.dart';

/// Résultat d'une inscription réussie — pas de connexion automatique tant
/// que l'email n'est pas vérifié (même règle que le site web).
class RegisterResult {
  final String message;
  final String email;

  RegisterResult({required this.message, required this.email});
}

class AuthService {
  final ApiClient apiClient;
  final LocalStorage storage;

  AuthService({required this.apiClient, required this.storage});

  /// Connexion. Le serveur exige `deviceId` DANS LE CORPS de la requête (pas
  /// seulement l'en-tête `X-Device-Id` déjà ajouté par [ApiClient]) — c'est
  /// ce champ qui lie l'appareil au compte la toute première fois.
  ///
  /// Erreurs backend possibles (propagées telles quelles à l'appelant via
  /// [ApiException.code]) : `INVALID_CREDENTIALS`, `EMAIL_NOT_VERIFIED`
  /// (avec l'email dans `body['email']`), `DEVICE_MISMATCH`.
  Future<AuthUser> login({required String phone, required String password}) async {
    final deviceId = await storage.getOrCreateDeviceId();

    final data = await apiClient.post(
      '/auth/login',
      {'phone': phone, 'password': password, 'deviceId': deviceId},
      withAuth: false,
    );

    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await storage.setToken(token);
    }

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  /// Inscription élève. `role` doit être la valeur exacte attendue par le
  /// serveur : `STUDENT` (majuscules).
  Future<RegisterResult> registerStudent({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String serie,
  }) {
    return _register({
      'role': 'STUDENT',
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'serie': serie,
    }, email);
  }

  /// Inscription professeur. `role` doit être la valeur exacte attendue par
  /// le serveur : `PROFESSOR` (majuscules).
  Future<RegisterResult> registerProfessor({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String etablissement,
    required String matieres,
    required int experienceYears,
  }) {
    return _register({
      'role': 'PROFESSOR',
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'etablissement': etablissement,
      'matieres': matieres,
      'experienceYears': experienceYears,
    }, email);
  }

  Future<RegisterResult> _register(Map<String, dynamic> body, String email) async {
    final data = await apiClient.post('/auth/signup', body, withAuth: false);
    return RegisterResult(
      message: (data['message'] as String?) ??
          "Compte créé ! Vérifiez votre email pour l'activer.",
      email: email,
    );
  }

  /// Vérifie le code à 6 chiffres reçu par email. Le serveur exige aussi
  /// `deviceId` dans le corps ici (même raison que pour /login : c'est ce
  /// qui lie l'appareil au compte). En cas de succès, active le compte,
  /// lie l'appareil, et renvoie un jeton de connexion.
  Future<AuthUser> verifyEmail({required String email, required String code}) async {
    final deviceId = await storage.getOrCreateDeviceId();

    final data = await apiClient.post(
      '/auth/verify-email',
      {'email': email, 'code': code, 'deviceId': deviceId},
      withAuth: false,
    );

    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await storage.setToken(token);
    }

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  /// Redemande l'envoi du code de vérification par email (inscription).
  Future<void> resendCode({required String email}) async {
    await apiClient.post('/auth/resend-code', {'email': email}, withAuth: false);
  }

  /// Demande l'envoi d'un code de réinitialisation par email. Répond
  /// toujours `{sent: true}` côté serveur, que le compte existe ou non
  /// (anti-énumération) — l'app ne peut donc jamais savoir si l'email
  /// existe vraiment, ce qui est volontaire.
  Future<void> forgotPassword({required String email}) async {
    await apiClient.post('/auth/forgot-password', {'email': email}, withAuth: false);
  }

  /// Vérifie le code de réinitialisation et applique le nouveau mot de
  /// passe. Ne connecte pas automatiquement — l'utilisateur se reconnecte
  /// ensuite avec son nouveau mot de passe (même comportement que le site).
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await apiClient.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    }, withAuth: false);
  }

  Future<void> logout() async {
    await storage.clearToken();
  }
}

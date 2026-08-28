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

  /// Connexion. Les erreurs backend possibles (propagées telles quelles à
  /// l'appelant via [ApiException.code]) : `INVALID_CREDENTIALS`,
  /// `EMAIL_NOT_VERIFIED` (avec l'email dans `body['email']`),
  /// `DEVICE_MISMATCH`.
  Future<AuthUser> login({required String phone, required String password}) async {
    final data = await apiClient.post(
      '/auth/login',
      {'phone': phone, 'password': password},
      withAuth: false,
    );

    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await storage.setToken(token);
    }

    return AuthUser.fromJson(data['user'] as Map<String, dynamic>? ?? data);
  }

  /// Inscription élève.
  Future<RegisterResult> registerStudent({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String serie,
  }) {
    return _register({
      'role': 'student',
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'serie': serie,
    }, email);
  }

  /// Inscription professeur.
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
      'role': 'professor',
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

  Future<void> logout() async {
    await storage.clearToken();
  }
}

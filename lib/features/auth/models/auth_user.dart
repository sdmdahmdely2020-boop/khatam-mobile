/// Modèle utilisateur minimal — étendu au fil des écrans suivants
/// (profil, série, matières, etc.) quand ces informations seront affichées.
class AuthUser {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String role; // 'student' | 'professor'

  AuthUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'student').toString(),
    );
  }

  bool get isProfessor => role == 'professor';
}

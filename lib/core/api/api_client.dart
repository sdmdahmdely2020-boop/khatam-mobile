import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/local_storage.dart';

/// Erreur renvoyée par l'API Khatam, avec le code d'erreur exact du backend
/// (ex. `INVALID_CREDENTIALS`, `EMAIL_NOT_VERIFIED`, `PHONE_TAKEN`...) et le
/// message déjà rédigé en français par le serveur, prêt à afficher tel quel.
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final Map<String, dynamic>? body;

  ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.body,
  });

  @override
  String toString() => 'ApiException($code): $message';
}

/// Client HTTP générique vers l'API Khatam — même backend que le site web
/// (`khatam-backend` sur Render). Attache automatiquement le jeton de
/// connexion (si présent) et l'identifiant d'appareil à chaque requête.
class ApiClient {
  final String baseUrl;
  final LocalStorage _storage = LocalStorage();

  ApiClient({required this.baseUrl});

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-Device-Id': await _storage.getOrCreateDeviceId(),
    };
    if (withAuth) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String path, {bool withAuth = true}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(withAuth: withAuth),
    );
    return _handle(response);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    Map<String, dynamic> decoded = {};
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Réponse non-JSON (ex. erreur réseau/proxy) — on garde un corps vide.
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      code: (decoded['error'] as String?) ?? 'UNKNOWN_ERROR',
      message: (decoded['message'] as String?) ??
          "Une erreur est survenue. Réessayez dans un instant.",
      statusCode: response.statusCode,
      body: decoded,
    );
  }
}

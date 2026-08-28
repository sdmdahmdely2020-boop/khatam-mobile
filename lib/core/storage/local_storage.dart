import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stockage local : jeton de connexion (JWT) + identifiant d'appareil unique.
///
/// Le backend Khatam autorise un seul appareil actif par compte (en-tête
/// `X-Device-Id`) — cet identifiant est généré une seule fois, à la
/// première utilisation de l'app, puis conservé pour toujours sur cet
/// appareil.
class LocalStorage {
  static const _tokenKey = 'khatam_auth_token';
  static const _deviceIdKey = 'khatam_device_id';
  static const _onboardingSeenKey = 'khatam_onboarding_seen';

  /// Vrai une fois que l'utilisateur a déjà vu (ou passé) l'écran d'accueil
  /// (3 pages de présentation) — permet de ne l'afficher qu'une seule fois
  /// par appareil, avant le premier écran de connexion.
  Future<bool> getOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _generateDeviceId();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

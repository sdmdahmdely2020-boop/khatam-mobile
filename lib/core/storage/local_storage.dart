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
  static const _streakLastActiveKey = 'khatam_streak_last_active';
  static const _streakCountKey = 'khatam_streak_count';

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

  /// "Série de jours" (motivation, 29/08) — calculée et stockée UNIQUEMENT
  /// sur cet appareil (pas de backend, pas de synchronisation entre
  /// appareils). Appelée une fois à chaque ouverture de l'accueil élève :
  /// - même jour que la dernière visite -> la série ne change pas ;
  /// - jour suivant consécutif -> +1 ;
  /// - un jour (ou plus) sauté, ou toute première visite -> repart à 1.
  ///
  /// Limite assumée et documentée pour sidi : réinstaller l'app ou se
  /// connecter sur un autre appareil réinitialise la série, puisqu'elle
  /// n'est pas suivie côté serveur. Un vrai suivi multi-appareils
  /// nécessiterait une route backend dédiée (piste pour plus tard).
  Future<int> recordActivityAndGetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final lastActive = prefs.getString(_streakLastActiveKey);
    final previousCount = prefs.getInt(_streakCountKey) ?? 0;

    int nextCount;
    if (lastActive == todayKey) {
      nextCount = previousCount == 0 ? 1 : previousCount;
    } else if (lastActive != null && _dateKey(now.subtract(const Duration(days: 1))) == lastActive) {
      nextCount = previousCount + 1;
    } else {
      nextCount = 1;
    }

    await prefs.setString(_streakLastActiveKey, todayKey);
    await prefs.setInt(_streakCountKey, nextCount);
    return nextCount;
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

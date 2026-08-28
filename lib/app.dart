import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/state/auth_state.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

/// Adresse du backend Khatam déjà en production (voir khatam-backend sur
/// Render — même API que le site web actuel). Aucune configuration
/// supplémentaire n'est nécessaire pour développer contre les vraies
/// données ; garder en tête qu'il s'agit du serveur réel (pas d'environnement
/// de test séparé pour l'instant), donc éviter les actions destructrices
/// pendant les tests manuels sur l'appareil/émulateur.
const String kApiBaseUrl = 'https://khatam-backend-i6zn.onrender.com/api';

class KhatamApp extends StatelessWidget {
  const KhatamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(baseUrl: kApiBaseUrl);
    final storage = LocalStorage();
    final authService = AuthService(apiClient: apiClient, storage: storage);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState(authService: authService)),
      ],
      child: MaterialApp(
        title: 'Khatam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _StartupGate(),
      ),
    );
  }
}

/// Décide, au tout premier lancement de l'app sur cet appareil, s'il faut
/// montrer l'écran d'accueil (3 pages, [OnboardingScreen]) avant l'écran de
/// connexion, ou directement l'écran de connexion (déjà vu une fois — voir
/// [LocalStorage.getOnboardingSeen]). Un court écran de chargement s'affiche
/// pendant la lecture du stockage local (quasi instantané en pratique).
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LocalStorage().getOnboardingSeen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final alreadySeen = snapshot.data!;
        return alreadySeen ? const LoginScreen() : const OnboardingScreen();
      },
    );
  }
}

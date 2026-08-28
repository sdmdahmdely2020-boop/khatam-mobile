import 'package:flutter/material.dart';

import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';

/// Écran d'accueil (3 pages) affiché une seule fois, à la toute première
/// ouverture de l'app, avant l'écran de connexion — voir [LocalStorage.
/// getOnboardingSeen]/[setOnboardingSeen] pour la mémorisation par appareil,
/// et [_StartupGate] dans `app.dart` pour la décision de l'afficher ou non.
///
/// Illustrations : lot 2 de l'identité visuelle Khatam
/// (`assets/onboarding/onboarding-*.png`, avec variante haute résolution
/// dans `2.0x/` incluse automatiquement par Flutter).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  final String asset;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.asset,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPage(
      asset: 'assets/onboarding/onboarding-1-bienvenue.png',
      title: 'Bienvenue sur Khatam',
      subtitle:
          'La plateforme des sujets et corrigés du Baccalauréat mauritanien, publiés par de vrais professeurs.',
    ),
    _OnboardingPage(
      asset: 'assets/onboarding/onboarding-2-recherche.png',
      title: 'Trouvez vos documents',
      subtitle:
          'Filtrez par série, année et matière : Mathématiques, Physique, Arabe, Philosophie, et bien d\'autres.',
    ),
    _OnboardingPage(
      asset: 'assets/onboarding/onboarding-3-reussite.png',
      title: 'Débloquez et réussissez',
      subtitle:
          'Payez en toute simplicité par Bankily, Masrivi ou Sedad, et accédez immédiatement au document.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await LocalStorage().setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, top: 4),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Passer', style: TextStyle(color: Colors.black54)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(page.asset, width: 240, height: 240),
                        const SizedBox(height: 36),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandBlue,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppTheme.brandBlue : const Color(0xFFD9E1EA),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

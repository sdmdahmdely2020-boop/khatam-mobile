import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/state/auth_state.dart';
import '../catalog/screens/catalog_screen.dart';
import '../professor/screens/professor_home_screen.dart';

/// Aiguille vers l'accueil professeur ou élève selon le rôle du compte
/// tout juste connecté/vérifié — évite de dupliquer ce choix dans chaque
/// écran d'authentification qui doit décider où naviguer ensuite.
class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthState>().currentUser;
    if (user != null && user.isProfessor) {
      return const ProfessorHomeScreen();
    }
    return const CatalogHome();
  }
}

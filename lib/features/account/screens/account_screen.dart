import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../ai_grading/screens/ai_history_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/state/auth_state.dart';
import '../../subscriptions/screens/subscription_plans_screen.dart';

/// Écran "Mon compte" minimal, commun élève/professeur : informations du
/// profil (lecture seule pour l'instant) + déconnexion. La modification du
/// profil (photo, série, matières...) est prévue pour une prochaine
/// livraison.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez vous reconnecter pour accéder à votre compte.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<AuthState>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE7EFF8),
                ),
                child: const Icon(Icons.person_outline, color: AppTheme.brandBlue, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? '—',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user?.isProfessor == true ? 'Professeur' : 'Élève',
                  style: const TextStyle(
                    color: AppTheme.brandBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _InfoRow(icon: Icons.phone_android_outlined, label: 'Téléphone', value: user?.phone ?? '—'),
            const Divider(height: 28),
            _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '—'),
            if (user != null && !user.isProfessor) ...[
              const Divider(height: 28),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                ),
                icon: const Icon(Icons.workspace_premium_outlined, color: AppTheme.brandGreen),
                label: const Text('Mon abonnement', style: TextStyle(color: AppTheme.brandGreen)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.brandGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiHistoryScreen()),
                ),
                icon: const Icon(Icons.auto_awesome_outlined, color: AppTheme.brandBlue),
                label: const Text('Mes corrections IA', style: TextStyle(color: AppTheme.brandBlue)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.brandBlue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.black45, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

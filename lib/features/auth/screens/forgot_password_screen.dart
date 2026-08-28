import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../state/auth_state.dart';

enum _Step { email, reset, done }

/// Écran mot de passe oublié (Phase 1, écran 4/4 — dernier de la phase
/// Auth) : demande l'email, puis code à 6 chiffres + nouveau mot de passe.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  _Step _step = _Step.email;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  late final AnimationController _animController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) timer.cancel();
      });
    });
  }

  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authState = context.read<AuthState>();
    final ok = await authState.requestPasswordReset(email: _emailController.text.trim());

    if (!mounted || !ok) return;
    _startCooldown();
    setState(() => _step = _Step.reset);
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0) return;
    final authState = context.read<AuthState>();
    final ok = await authState.requestPasswordReset(email: _emailController.text.trim());
    if (!mounted) return;

    if (ok) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau code envoyé par email (si un compte existe).')),
      );
    }
  }

  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authState = context.read<AuthState>();
    final ok = await authState.resetPassword(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    if (!mounted || !ok) return;
    setState(() => _step = _Step.done);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: switch (_step) {
                    _Step.email => _buildEmailStep(authState),
                    _Step.reset => _buildResetStep(authState),
                    _Step.done => const _DoneView(),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(AuthState authState) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE7EFF8),
              ),
              child: const Icon(Icons.lock_reset_outlined, color: AppTheme.brandBlue, size: 38),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mot de passe oublié ?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandBlue,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Indique l'email de ton compte, on t'envoie un code pour choisir un nouveau mot de passe.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 24),

          if (authState.status == AuthStatus.error && authState.errorMessage != null) ...[
            _ErrorBanner(message: authState.errorMessage!),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (!value.contains('@') || !value.contains('.')) {
                return 'Adresse email invalide.';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submitEmail(),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: authState.status == AuthStatus.loading ? null : _submitEmail,
            child: authState.status == AuthStatus.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Envoyer le code'),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour à la connexion'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(AuthState authState) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE7EFF8),
              ),
              child: const Icon(Icons.mark_email_unread_outlined,
                  color: AppTheme.brandBlue, size: 38),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Vérifie ton email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandBlue,
                ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: "Si un compte existe pour\n",
              style: const TextStyle(color: Colors.black54, height: 1.4),
              children: [
                TextSpan(
                  text: _emailController.text.trim(),
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const TextSpan(text: ", un code à 6 chiffres vient de lui être envoyé."),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (authState.status == AuthStatus.error && authState.errorMessage != null) ...[
            _ErrorBanner(message: authState.errorMessage!),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'Code reçu par email',
              hintText: '– – – – – –',
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.length != 6 || int.tryParse(value) == null) {
                return 'Entre les 6 chiffres reçus par email.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Nouveau mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? '6 caractères minimum.' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirmer le nouveau mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) => (v != _newPasswordController.text)
                ? 'Les mots de passe ne correspondent pas.'
                : null,
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: authState.status == AuthStatus.loading ? null : _submitReset,
            child: authState.status == AuthStatus.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Réinitialiser le mot de passe'),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _cooldownSeconds > 0 ? null : _resend,
              child: Text(
                _cooldownSeconds > 0
                    ? 'Renvoyer le code (${_cooldownSeconds}s)'
                    : 'Renvoyer le code',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE7F5EC),
          ),
          child: const Icon(Icons.check_circle_outline, color: AppTheme.brandGreen, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Mot de passe réinitialisé !',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brandGreen,
              ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Tu peux maintenant te connecter avec ton nouveau mot de passe.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Aller à la connexion'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

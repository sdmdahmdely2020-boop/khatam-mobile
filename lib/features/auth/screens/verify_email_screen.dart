import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/home_router.dart';
import '../state/auth_state.dart';

/// Écran de vérification par email (Phase 1, écran 3/4) : code à 6 chiffres
/// envoyé par email à l'inscription, avec renvoi possible (délai de 60s
/// entre deux renvois, côté app — le backend a lui aussi sa propre limite).
class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _verified = false;
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
    _startCooldown();
  }

  @override
  void dispose() {
    _animController.dispose();
    _codeController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authState = context.read<AuthState>();
    final ok = await authState.verifyEmail(
      email: widget.email,
      code: _codeController.text.trim(),
    );

    if (!mounted || !ok) return;
    setState(() => _verified = true);
  }

  Future<void> _resend() async {
    if (_cooldownSeconds > 0) return;
    final authState = context.read<AuthState>();
    final ok = await authState.resendCode(email: widget.email);
    if (!mounted) return;

    if (ok) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau code envoyé par email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
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
                  child: _verified ? const _SuccessView() : _buildForm(authState),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(AuthState authState) {
    return Form(
      key: _formKey,
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
              text: 'Un code à 6 chiffres a été envoyé à\n',
              style: const TextStyle(color: Colors.black54, height: 1.4),
              children: [
                TextSpan(
                  text: widget.email,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
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
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 10,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '– – – – – –',
              hintStyle: TextStyle(letterSpacing: 10, fontSize: 22, color: Colors.black26),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.length != 6 || int.tryParse(value) == null) {
                return 'Entre les 6 chiffres reçus par email.';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: authState.status == AuthStatus.loading ? null : _submit,
            child: authState.status == AuthStatus.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Vérifier'),
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

class _SuccessView extends StatelessWidget {
  const _SuccessView();

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
          child: const Icon(Icons.verified_outlined, color: AppTheme.brandGreen, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Email vérifié !',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brandGreen,
              ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Ton compte Khatam est maintenant actif. Tu peux te connecter.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeRouter()),
            (route) => false,
          ),
          child: const Text('Continuer'),
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

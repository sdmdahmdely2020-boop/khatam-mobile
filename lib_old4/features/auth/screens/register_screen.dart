import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../state/auth_state.dart';
import 'verify_email_screen.dart';

enum _Role { student, professor }

const _series = ['Série C', 'Série D', 'Série A', 'Série Lettres modernes'];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  _Role _role = _Role.student;

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Élève
  String _serie = _series.first;

  // Professeur
  final _etablissementController = TextEditingController();
  final _matieresController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  RegisterResult? _successResult;

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
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _etablissementController.dispose();
    _matieresController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authState = context.read<AuthState>();
    RegisterResult? result;

    if (_role == _Role.student) {
      result = await authState.registerStudent(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        serie: _serie,
      );
    } else {
      result = await authState.registerProfessor(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        etablissement: _etablissementController.text.trim(),
        matieres: _matieresController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()) ?? 0,
      );
    }

    if (!mounted || result == null) return;
    setState(() => _successResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: _successResult != null
                      ? _SuccessView(result: _successResult!)
                      : _buildForm(authState),
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
          Text(
            'Rejoins Khatam',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandBlue,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Choisis ton profil pour commencer.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),

          SegmentedButton<_Role>(
            segments: const [
              ButtonSegment(
                value: _Role.student,
                label: Text('Élève'),
                icon: Icon(Icons.menu_book_outlined),
              ),
              ButtonSegment(
                value: _Role.professor,
                label: Text('Professeur'),
                icon: Icon(Icons.workspace_premium_outlined),
              ),
            ],
            selected: {_role},
            onSelectionChanged: (selection) {
              setState(() => _role = selection.first);
            },
          ),
          const SizedBox(height: 20),

          if (authState.status == AuthStatus.error && authState.errorMessage != null) ...[
            _ErrorBanner(message: authState.errorMessage!),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Entre ton nom complet.' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              prefixIcon: Icon(Icons.phone_android_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 8) ? 'Numéro de téléphone invalide.' : null,
          ),
          const SizedBox(height: 14),
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
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
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
              labelText: 'Confirmer le mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) => (v != _passwordController.text)
                ? 'Les mots de passe ne correspondent pas.'
                : null,
          ),
          const SizedBox(height: 18),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _role == _Role.student
                ? _StudentFields(
                    key: const ValueKey('student'),
                    serie: _serie,
                    onSerieChanged: (v) => setState(() => _serie = v),
                  )
                : _ProfessorFields(
                    key: const ValueKey('professor'),
                    etablissementController: _etablissementController,
                    matieresController: _matieresController,
                    experienceController: _experienceController,
                  ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: authState.status == AuthStatus.loading ? null : _submit,
            child: authState.status == AuthStatus.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Créer mon compte'),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Déjà un compte ? Se connecter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentFields extends StatelessWidget {
  final String serie;
  final ValueChanged<String> onSerieChanged;

  const _StudentFields({super.key, required this.serie, required this.onSerieChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: serie,
      decoration: const InputDecoration(
        labelText: 'Série',
        prefixIcon: Icon(Icons.school_outlined),
      ),
      items: _series
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) {
        if (v != null) onSerieChanged(v);
      },
    );
  }
}

class _ProfessorFields extends StatelessWidget {
  final TextEditingController etablissementController;
  final TextEditingController matieresController;
  final TextEditingController experienceController;

  const _ProfessorFields({
    super.key,
    required this.etablissementController,
    required this.matieresController,
    required this.experienceController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: etablissementController,
          decoration: const InputDecoration(
            labelText: 'Établissement',
            prefixIcon: Icon(Icons.apartment_outlined),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? "Nom de l'établissement requis." : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: matieresController,
          decoration: const InputDecoration(
            labelText: 'Matières enseignées (ex. Mathématiques, Physique)',
            prefixIcon: Icon(Icons.auto_stories_outlined),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Indique au moins une matière.' : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: experienceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Années d'expérience",
            prefixIcon: Icon(Icons.timeline_outlined),
          ),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            if (n == null || n < 0) return 'Nombre invalide.';
            return null;
          },
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final RegisterResult result;

  const _SuccessView({required this.result});

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
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppTheme.brandGreen, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Compte créé !',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.brandGreen,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          result.message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 4),
        Text(
          result.email,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => VerifyEmailScreen(email: result.email),
              ),
            );
          },
          child: const Text('Vérifier mon email'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Retour à la connexion'),
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

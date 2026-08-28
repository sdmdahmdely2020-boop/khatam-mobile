import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../services/professor_service.dart';

/// Formulaire d'envoi d'un nouveau document par un professeur, directement
/// depuis l'app (jusqu'ici, seul le site web le permettait — l'app pouvait
/// seulement publier/dépublier des documents déjà créés). Contrat exact
/// vérifié dans `khatam-backend/src/routes/documents.js` (POST /documents) :
/// PDF uniquement (25 Mo max), champs title/matiere/serie/annee/type requis.
class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  static const _types = [
    ('sujet', 'Sujet'),
    ('corrige', 'Corrigé'),
    ('cours', 'Cours'),
    ('exercices', 'Exercices'),
    ('video', 'Vidéo'),
    ('blanc', 'Examen blanc'),
  ];
  static const _series = ['C', 'D', 'A'];

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _matiereCtrl = TextEditingController();
  final _anneeCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _prixCtrl = TextEditingController(text: '0');

  String _serie = 'C';
  String _type = 'sujet';
  bool _free = false;
  bool _adUnlock = false;
  bool _aiGrading = false;

  PlatformFile? _pickedFile;
  List<int>? _pickedBytes;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _matiereCtrl.dispose();
    _anneeCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    // FilePicker.pickFile(...) renvoie directement un PlatformFile? (API
    // actuelle du paquet — .bytes n'existe plus, il faut lire le contenu via
    // readAsBytes(), un Future<Uint8List>) — indispensable sur le web, où le
    // navigateur ne donne JAMAIS de vrai chemin disque (PlatformFile.path
    // reste toujours null sur Flutter Web). Fonctionne aussi normalement sur
    // Android/iOS/desktop.
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() {
      _pickedFile = f;
      _pickedBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null || _pickedBytes == null) {
      setState(() => _errorMessage = 'Choisissez un fichier PDF avant d\'envoyer.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final apiClient = context.read<AuthState>().apiClient;
      final service = ProfessorService(apiClient: apiClient);
      final result = await service.createDocument(
        title: _titleCtrl.text.trim(),
        matiere: _matiereCtrl.text.trim(),
        serie: _serie,
        annee: int.parse(_anneeCtrl.text.trim()),
        type: _type,
        prix: _free ? 0 : (num.tryParse(_prixCtrl.text.trim()) ?? 0),
        free: _free,
        adUnlock: _adUnlock,
        aiGrading: _aiGrading,
        fileBytes: _pickedBytes!,
        fileName: _pickedFile!.name,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.professorPending
                ? 'Document enregistré en brouillon — il sera visible aux élèves une fois votre compte approuvé.'
                : 'Document publié — il est déjà visible dans le catalogue.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Impossible de contacter le serveur. Réessayez.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau document'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre', hintText: 'Ex: Bac Maths Série C 2026'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matiereCtrl,
                decoration: const InputDecoration(labelText: 'Matière', hintText: 'Ex: Mathématiques'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Matière requise' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _serie,
                      decoration: const InputDecoration(labelText: 'Série'),
                      items: _series
                          .map((s) => DropdownMenuItem(value: s, child: Text('Série $s')))
                          .toList(),
                      onChanged: (v) => setState(() => _serie = v ?? _serie),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _anneeCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Année'),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 2000 || n > 2100) return 'Année invalide';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type de document'),
                items: _types
                    .map((t) => DropdownMenuItem(value: t.$1, child: Text(t.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Document gratuit'),
                value: _free,
                onChanged: (v) => setState(() => _free = v),
              ),
              if (!_free)
                TextFormField(
                  controller: _prixCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix (MRU)'),
                  validator: (v) {
                    if (_free) return null;
                    final n = num.tryParse(v?.trim() ?? '');
                    if (n == null || n < 0) return 'Prix invalide';
                    return null;
                  },
                ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Déblocage possible par publicité'),
                subtitle: const Text('L\'élève peut aussi le débloquer gratuitement en regardant une pub', style: TextStyle(fontSize: 12.5)),
                value: _adUnlock,
                onChanged: (v) => setState(() => _adUnlock = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Correction IA activée'),
                subtitle: const Text('Un élève ayant débloqué ce document pourra faire corriger sa copie par l\'IA', style: TextStyle(fontSize: 12.5)),
                value: _aiGrading,
                onChanged: (v) => setState(() => _aiGrading = v),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_pickedFile == null ? 'Choisir le fichier PDF' : _pickedFile!.name),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text('Envoyer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

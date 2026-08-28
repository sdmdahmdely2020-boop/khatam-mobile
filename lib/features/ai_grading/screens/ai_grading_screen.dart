import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../models/ai_submission.dart';
import '../services/ai_grading_service.dart';
import 'ai_history_screen.dart';

/// Écran de correction IA pour un document précis (accessible uniquement
/// quand `doc.aiGrading` est activé et que l'élève a débloqué le document —
/// voir la condition d'accès dans `DocumentDetailScreen`). L'élève envoie sa
/// copie (photo, PDF, ou texte tapé) ; le serveur la compare au corrigé
/// officiel du professeur et renvoie une note sur 20 + un retour détaillé.
class AiGradingScreen extends StatefulWidget {
  final String documentId;
  final String documentTitle;

  const AiGradingScreen({
    super.key,
    required this.documentId,
    required this.documentTitle,
  });

  @override
  State<AiGradingScreen> createState() => _AiGradingScreenState();
}

class _AiGradingScreenState extends State<AiGradingScreen> {
  late final AiGradingService _service;
  final _textCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool? _configured; // null = pas encore su
  List<int>? _pickedBytes;
  String? _pickedName;
  String? _pickedMimeType; // image/jpeg ou application/pdf

  bool _submitting = false;
  String? _errorMessage;
  AiSubmission? _result;

  @override
  void initState() {
    super.initState();
    _service = AiGradingService(apiClient: context.read<AuthState>().apiClient);
    _service.fetchStatus().then((v) {
      if (mounted) setState(() => _configured = v);
    }).catchError((_) {
      // Pas grave si ça échoue — on laisse juste l'élève essayer directement,
      // l'erreur AI_NOT_CONFIGURED éventuelle sera de toute façon claire au
      // moment de l'envoi.
      if (mounted) setState(() => _configured = true);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _setPicked(List<int> bytes, String name, String mimeType) {
    setState(() {
      _pickedBytes = bytes;
      _pickedName = name;
      _pickedMimeType = mimeType;
      _textCtrl.clear();
      _errorMessage = null;
    });
  }

  void _clearPicked() {
    setState(() {
      _pickedBytes = null;
      _pickedName = null;
      _pickedMimeType = null;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      // imageQuality force une recompression en JPEG (et, sur iPhone, évite
      // le format HEIC que le serveur refuse — voir
      // khatam-backend/src/lib/submissionUpload.js). readAsBytes() (plutôt
      // que XFile.path) fonctionne sur toutes les plateformes, y compris le
      // web où un chemin de fichier réel n'existe jamais.
      final file = await _picker.pickImage(source: source, imageQuality: 82);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      _setPicked(bytes, file.name, 'image/jpeg');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'accéder à l'appareil photo/galerie.")),
      );
    }
  }

  Future<void> _pickPdf() async {
    // FilePicker.pickFile(...) renvoie directement un PlatformFile? (API
    // actuelle du paquet, voir upload_document_screen.dart pour le même
    // changement) — il n'expose plus de champ .bytes synchrone, il faut lire
    // le contenu via readAsBytes() (Future<Uint8List>), qui fonctionne aussi
    // bien sur le web (où .path reste toujours null) que sur mobile/desktop.
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (f == null) return;
    final bytes = await f.readAsBytes();
    _setPicked(bytes, f.name, 'application/pdf');
  }

  Future<void> _submit() async {
    final hasFile = _pickedBytes != null;
    final text = _textCtrl.text.trim();
    if (!hasFile && text.length < 10) {
      setState(() => _errorMessage =
          "Ajoutez une photo ou un PDF de votre copie, ou tapez une réponse d'au moins 10 caractères.");
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final submission = hasFile
          ? await _service.submitFile(
              documentId: widget.documentId,
              fileBytes: _pickedBytes!,
              fileName: _pickedName!,
              mimeType: _pickedMimeType!,
            )
          : await _service.submitText(
              documentId: widget.documentId,
              answerText: text,
            );
      if (!mounted) return;
      setState(() => _result = submission);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Impossible de contacter le serveur. Réessayez.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      _result = null;
      _errorMessage = null;
      _pickedBytes = null;
      _pickedName = null;
      _pickedMimeType = null;
      _textCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correction IA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
        actions: [
          IconButton(
            tooltip: 'Historique',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiHistoryScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _result != null ? _buildResult(_result!) : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.documentTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          "Envoyez une photo ou un PDF de votre copie : l'IA la compare au corrigé officiel du professeur et vous donne une note sur 20 avec un retour détaillé.",
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        if (_configured == false) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "La correction IA n'est pas encore activée sur ce serveur. Vous pouvez quand même préparer votre envoi.",
              style: TextStyle(color: Colors.orange, fontSize: 12.5),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PickButton(
              icon: Icons.camera_alt_outlined,
              label: 'Prendre une photo',
              onTap: () => _pickPhoto(ImageSource.camera),
            ),
            _PickButton(
              icon: Icons.photo_library_outlined,
              label: 'Choisir une photo',
              onTap: () => _pickPhoto(ImageSource.gallery),
            ),
            _PickButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Choisir un PDF',
              onTap: _pickPdf,
            ),
          ],
        ),
        if (_pickedName != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _pickedMimeType == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  color: AppTheme.brandBlue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_pickedName!, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _clearPicked,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('ou', style: TextStyle(color: Colors.black38)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _textCtrl,
          maxLines: 5,
          enabled: _pickedBytes == null,
          decoration: const InputDecoration(
            labelText: 'Tapez votre réponse (au moins 10 caractères)',
            border: OutlineInputBorder(),
          ),
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
                : const Text('Envoyer pour correction'),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(AiSubmission result) {
    final color = _noteColor(result.note);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              result.noteLabel,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (result.feedback != null && result.feedback!.isNotEmpty) ...[
          const Text('Avis général', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(result.feedback!, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 24),
        ],
        if (result.strengths.isNotEmpty) ...[
          const Text('Points forts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...result.strengths.map((s) => _BulletLine(
                icon: Icons.check_circle_outline,
                color: AppTheme.brandGreen,
                text: s,
              )),
          const SizedBox(height: 20),
        ],
        if (result.weaknesses.isNotEmpty) ...[
          const Text('Points à travailler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...result.weaknesses.map((s) => _BulletLine(
                icon: Icons.error_outline,
                color: Colors.orange,
                text: s,
              )),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: _resetForm,
            child: const Text('Envoyer une nouvelle copie'),
          ),
        ),
      ],
    );
  }

  Color _noteColor(num? note) {
    if (note == null) return Colors.black54;
    if (note >= 14) return AppTheme.brandGreen;
    if (note >= 10) return Colors.orange;
    return Colors.red;
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _BulletLine({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.3))),
        ],
      ),
    );
  }
}

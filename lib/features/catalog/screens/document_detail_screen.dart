import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_state.dart';
import '../models/document_item.dart';
import '../services/catalog_service.dart';
import '../services/favorites_service.dart';
import 'document_viewer_screen.dart';
import 'unlock_screen.dart';

/// Fiche détaillée d'un document : aperçu + métadonnées complètes.
///
/// "Ouvrir" mène à la visionneuse sécurisée (document déjà débloqué).
/// "Débloquer" mène au choix entre publicité gratuite et paiement
/// Bankily/Masrivi/Sedad (voir [UnlockScreen]) — au retour, si le document a
/// été débloqué, la fiche est rechargée pour refléter le nouvel état.
class DocumentDetailScreen extends StatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late final CatalogService _catalogService;
  late final FavoritesService _favoritesService;
  late Future<DocumentItem> _future;

  bool _isStudent = false;
  bool? _isFavorited; // null = pas encore su (chargement, ou invité/professeur)
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _catalogService = CatalogService(apiClient: apiClient);
    _favoritesService = FavoritesService(apiClient: apiClient);
    _future = _catalogService.fetchDocument(widget.documentId);

    final user = context.read<AuthState>().currentUser;
    _isStudent = user != null && !user.isProfessor;
    if (_isStudent) {
      _loadFavoriteState();
    }
  }

  Future<void> _loadFavoriteState() async {
    try {
      final ids = await _favoritesService.fetchFavoriteIds();
      if (!mounted) return;
      setState(() => _isFavorited = ids.contains(widget.documentId));
    } catch (_) {
      // Pas grave si ça échoue — le cœur reste juste à l'état "inconnu"
      // (non rempli) plutôt que de bloquer l'affichage de la fiche.
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;
    setState(() => _favoriteBusy = true);
    try {
      final favorited = await _favoritesService.toggle(widget.documentId);
      if (!mounted) return;
      setState(() => _isFavorited = favorited);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de contacter le serveur. Réessayez.")),
      );
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  void _openViewer(DocumentItem doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentViewerScreen(documentId: doc.id, title: doc.title),
      ),
    );
  }

  Future<void> _openUnlock(DocumentItem doc) async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UnlockScreen(document: doc)),
    );
    if (unlocked == true && mounted) {
      setState(() {
        _future = _catalogService.fetchDocument(widget.documentId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
        actions: [
          if (_isStudent)
            IconButton(
              tooltip: 'Ajouter aux favoris',
              icon: _favoriteBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isFavorited == true ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorited == true ? Colors.red : null,
                    ),
              onPressed: _favoriteBusy ? null : _toggleFavorite,
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<DocumentItem>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: Colors.black38),
                      const SizedBox(height: 12),
                      const Text(
                        "Impossible de charger ce document.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _future = _catalogService.fetchDocument(widget.documentId);
                        }),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final doc = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: double.infinity,
                      height: 260,
                      child: doc.previewUrl.isEmpty
                          ? Container(color: const Color(0xFFEFF3F8))
                          : Image.network(
                              doc.previewUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: const Color(0xFFEFF3F8)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    doc.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(icon: Icons.menu_book_outlined, label: doc.matiere),
                      _InfoChip(icon: Icons.workspace_premium_outlined, label: 'Série ${doc.serie}'),
                      _InfoChip(icon: Icons.calendar_today_outlined, label: '${doc.annee}'),
                      _InfoChip(icon: Icons.description_outlined, label: doc.typeLabel),
                      _InfoChip(icon: Icons.visibility_outlined, label: '${doc.views} vues'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFE7EFF8),
                        backgroundImage: doc.professorPhotoUrl != null
                            ? NetworkImage(doc.professorPhotoUrl!)
                            : null,
                        child: doc.professorPhotoUrl == null
                            ? const Icon(Icons.person_outline, color: AppTheme.brandBlue)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.professorFullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (doc.professorMatieres != null &&
                                doc.professorMatieres!.isNotEmpty)
                              Text(
                                doc.professorMatieres!,
                                style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                              ),
                          ],
                        ),
                      ),
                      if (doc.professorBoosted)
                        const _InfoChip(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Populaire',
                          color: Colors.orange,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prix', style: TextStyle(color: Colors.black54, fontSize: 12.5)),
                        Text(
                          doc.priceLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: doc.free ? AppTheme.brandGreen : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: doc.unlocked
                              ? ElevatedButton.icon(
                                  onPressed: () => _openViewer(doc),
                                  icon: const Icon(Icons.menu_book_outlined),
                                  label: const Text('Ouvrir'),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _openUnlock(doc),
                                  icon: const Icon(Icons.lock_open_outlined),
                                  label: const Text('Débloquer'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, this.color = AppTheme.brandBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

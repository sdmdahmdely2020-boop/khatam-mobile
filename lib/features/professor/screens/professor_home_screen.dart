import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/subject_icons.dart';
import '../../account/screens/account_screen.dart';
import '../../auth/state/auth_state.dart';
import '../../catalog/models/document_item.dart';
import '../services/professor_service.dart';
import 'upload_document_screen.dart';
import 'wallet_screen.dart';

/// Écran d'accueil professeur : "Mes documents", avec un bouton pour
/// publier/dépublier chacun, un bouton flottant pour en envoyer un nouveau
/// directement depuis l'app, et un accès au portefeuille (icône dans
/// l'AppBar).
class ProfessorHomeScreen extends StatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  State<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends State<ProfessorHomeScreen> {
  late final ProfessorService _service;
  late Future<List<DocumentItem>> _future;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _service = ProfessorService(apiClient: apiClient);
    _future = _load();
  }

  Future<List<DocumentItem>> _load() {
    final userId = context.read<AuthState>().currentUser?.id ?? '';
    return _service.fetchMyDocuments(professorId: userId);
  }

  Future<void> _togglePublish(DocumentItem doc) async {
    setState(() => _busyIds.add(doc.id));
    try {
      await _service.setPublished(doc.id, !doc.isPublished);
      if (!mounted) return;
      setState(() {
        _future = _load();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de contacter le serveur. Réessayez.")),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(doc.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes documents'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Portefeuille',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mon compte',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const UploadDocumentScreen()),
          );
          if (created == true && mounted) {
            setState(() => _future = _load());
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau document'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<DocumentItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black38),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger vos documents.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _future = _load()),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final docs = snapshot.data ?? [];
            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Vous n'avez pas encore de document. Appuyez sur \"Nouveau document\" en bas pour en envoyer un.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                final next = _load();
                setState(() => _future = next);
                // Erreur ignorée ici volontairement : le FutureBuilder ci-dessus
                // affiche déjà l'état d'erreur à partir de ce même _future.
                await next.catchError((_) => <DocumentItem>[]);
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final busy = _busyIds.contains(doc.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doc.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                              _StatusBadge(published: doc.isPublished),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SubjectIcon(matiere: doc.matiere, size: 16),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${doc.matiere} · Série ${doc.serie} · ${doc.annee} · ${doc.typeLabel}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${doc.priceLabel} · ${doc.views} vues',
                            style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.2),
                                  )
                                : OutlinedButton.icon(
                                    onPressed: () => _togglePublish(doc),
                                    icon: Icon(
                                      doc.isPublished
                                          ? Icons.visibility_off_outlined
                                          : Icons.publish_outlined,
                                      size: 18,
                                    ),
                                    label: Text(doc.isPublished ? 'Dépublier' : 'Publier'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool published;

  const _StatusBadge({required this.published});

  @override
  Widget build(BuildContext context) {
    final color = published ? AppTheme.brandGreen : Colors.black45;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        published ? 'Publié' : 'Brouillon',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

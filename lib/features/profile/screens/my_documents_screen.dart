import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/subject_icons.dart';
import '../../auth/state/auth_state.dart';
import '../../catalog/screens/document_detail_screen.dart';
import '../models/my_document_entry.dart';
import '../services/profile_service.dart';

/// "Mes documents" — profil élève (29/08) : tout ce que l'élève a
/// concrètement débloqué (achat confirmé ou publicité vue), avec un résumé
/// "progression simple" en haut de l'écran. Accessible depuis "Mon compte".
class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  late final ProfileService _service;
  late Future<MyDocumentsResult> _future;

  @override
  void initState() {
    super.initState();
    _service = ProfileService(apiClient: context.read<AuthState>().apiClient);
    _future = _service.fetchMine();
  }

  void _reload() {
    setState(() => _future = _service.fetchMine());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes documents'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: FutureBuilder<MyDocumentsResult>(
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
                      const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black38),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger vos documents.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _reload, child: const Text('Réessayer')),
                    ],
                  ),
                ),
              );
            }

            final result = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                final next = _service.fetchMine();
                setState(() => _future = next);
                await next.catchError((_) => MyDocumentsResult(entries: [], progress: StudentProgress.empty()));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _ProgressCard(progress: result.progress),
                  const SizedBox(height: 16),
                  if (result.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 40, color: Colors.black26),
                          const SizedBox(height: 12),
                          Text(
                            result.progress.isPremium
                                ? "Aucun achat individuel pour l'instant — normal, votre abonnement Premium vous donne déjà accès à tout le catalogue."
                                : "Aucun document débloqué pour l'instant. Achetez un document ou débloquez-en un par publicité pour le retrouver ici.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  else
                    ...result.entries.map((entry) => _DocumentEntryCard(entry: entry, onReturn: _reload)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final StudentProgress progress;

  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final matieres = progress.byMatiere.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.menu_book_outlined,
                  value: '${progress.totalUnlocked}',
                  label: progress.totalUnlocked > 1 ? 'documents débloqués' : 'document débloqué',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.black12),
              Expanded(
                child: _StatTile(
                  icon: Icons.account_balance_wallet_outlined,
                  value: '${progress.totalSpentMru.toStringAsFixed(0)} MRU',
                  label: 'dépensés',
                ),
              ),
            ],
          ),
          if (progress.isPremium || progress.isBasic) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (progress.isPremium ? AppTheme.brandGreen : AppTheme.brandBlue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 15,
                    color: progress.isPremium ? AppTheme.brandGreen : AppTheme.brandBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    progress.isPremium ? 'Abonné Premium' : 'Abonné Basic',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: progress.isPremium ? AppTheme.brandGreen : AppTheme.brandBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (matieres.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text('Par matière', style: TextStyle(color: Colors.black54, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matieres.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SubjectIcon(matiere: entry.key, size: 14),
                      const SizedBox(width: 6),
                      Text('${entry.key} · ${entry.value}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.brandBlue, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
      ],
    );
  }
}

class _DocumentEntryCard extends StatelessWidget {
  final MyDocumentEntry entry;
  final VoidCallback onReturn;

  const _DocumentEntryCard({required this.entry, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final doc = entry.document;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: doc.id)),
          );
          onReturn();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 74,
                  child: doc.previewUrl.isEmpty
                      ? Container(color: const Color(0xFFEFF3F8))
                      : Image.network(
                          doc.previewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEFF3F8)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SubjectIcon(matiere: doc.matiere, size: 15),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${doc.matiere} · Série ${doc.serie} · ${doc.annee}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniTag(
                          label: entry.isPurchase ? 'Acheté · ${entry.amountPaid.toStringAsFixed(0)} MRU' : 'Débloqué par pub',
                          color: entry.isPurchase ? AppTheme.brandBlue : AppTheme.brandGreen,
                        ),
                        if (entry.acquiredAt != null)
                          _MiniTag(
                            label: _formatDate(entry.acquiredAt!),
                            color: Colors.black45,
                            plain: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  /// true = juste du texte gris, sans fond (utilisé pour la date) — évite
  /// d'avoir plusieurs puces colorées côte à côte, une seule suffit.
  final bool plain;

  const _MiniTag({
    required this.label,
    required this.color,
    this.plain = false,
  });

  @override
  Widget build(BuildContext context) {
    if (plain) {
      return Text(label, style: TextStyle(fontSize: 11, color: color));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

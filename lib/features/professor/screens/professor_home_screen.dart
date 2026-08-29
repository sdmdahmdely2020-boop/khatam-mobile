import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/subject_icons.dart';
import '../../account/screens/account_screen.dart';
import '../../ads/widgets/ad_carousel.dart';
import '../../auth/state/auth_state.dart';
import '../../catalog/models/document_item.dart';
import '../services/professor_service.dart';
import 'stats_screen.dart';
import 'upload_document_screen.dart';
import 'wallet_screen.dart';

enum _StatusFilter { all, published, draft }

/// Écran d'accueil professeur : "Mes documents" (29/08 — présentation
/// retravaillée, dernière étape du plan initial de sidi).
///
/// Reprend, pour un professeur, le même esprit que l'accueil élève repensé
/// (salutation personnalisée, recherche, filtres) : contrairement à l'accueil
/// élève, la recherche/le filtre par statut sont appliqués CÔTÉ APP sur la
/// liste déjà chargée (voir [_visibleDocs]) — un professeur a en général
/// quelques dizaines de documents au plus, pas besoin d'un aller-retour
/// serveur à chaque frappe. Un mini-résumé (documents/publiés/vues) donne un
/// aperçu immédiat sans quitter l'écran ; les statistiques complètes restent
/// sur [ProfessorStatsScreen] (icône dans l'AppBar), pas dupliquées ici.
class ProfessorHomeScreen extends StatefulWidget {
  const ProfessorHomeScreen({super.key});

  @override
  State<ProfessorHomeScreen> createState() => _ProfessorHomeScreenState();
}

class _ProfessorHomeScreenState extends State<ProfessorHomeScreen> {
  late final ProfessorService _service;
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<DocumentItem> _allDocs = [];
  _StatusFilter _statusFilter = _StatusFilter.all;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _service = ProfessorService(apiClient: context.read<AuthState>().apiClient);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = context.read<AuthState>().currentUser?.id ?? '';
      final docs = await _service.fetchMyDocuments(professorId: userId);
      if (!mounted) return;
      setState(() {
        _allDocs = docs;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Impossible de contacter le serveur. Vérifie ta connexion internet et réessaie.";
      });
    }
  }

  Future<void> _togglePublish(DocumentItem doc) async {
    setState(() => _busyIds.add(doc.id));
    try {
      await _service.setPublished(doc.id, !doc.isPublished);
      if (!mounted) return;
      await _load();
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

  List<DocumentItem> get _visibleDocs {
    final query = _searchController.text.trim().toLowerCase();
    return _allDocs.where((doc) {
      if (_statusFilter == _StatusFilter.published && !doc.isPublished) return false;
      if (_statusFilter == _StatusFilter.draft && doc.isPublished) return false;
      if (query.isNotEmpty && !doc.title.toLowerCase().contains(query)) return false;
      return true;
    }).toList();
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
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Statistiques',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfessorStatsScreen()),
            ),
          ),
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
            _load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau document'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              _buildListSliver(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = context.watch<AuthState>().currentUser;
    final firstName = (user?.fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
          child: Text(
            firstName.isEmpty ? 'Bonjour' : 'Bonjour, $firstName',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            'Voici un aperçu de vos documents.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        if (!_loading && _error == null) Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _StatsTeaser(docs: _allDocs),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher parmi vos documents...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              _StatusChip(
                label: 'Tous',
                selected: _statusFilter == _StatusFilter.all,
                onTap: () => setState(() => _statusFilter = _StatusFilter.all),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'Publiés',
                selected: _statusFilter == _StatusFilter.published,
                onTap: () => setState(() => _statusFilter = _StatusFilter.published),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: 'Brouillons',
                selected: _statusFilter == _StatusFilter.draft,
                onTap: () => setState(() => _statusFilter = _StatusFilter.draft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const AdCarousel(zone: 'dashboard'),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildListSliver() {
    if (_loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black38),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }

    if (_allDocs.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Vous n'avez pas encore de document. Appuyez sur \"Nouveau document\" en bas pour en envoyer un.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    final visible = _visibleDocs;
    if (visible.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aucun document ne correspond à cette recherche/ce filtre.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _DocumentRow(
            document: visible[index],
            busy: _busyIds.contains(visible[index].id),
            onTogglePublish: () => _togglePublish(visible[index]),
          ),
          childCount: visible.length,
        ),
      ),
    );
  }
}

class _StatsTeaser extends StatelessWidget {
  final List<DocumentItem> docs;

  const _StatsTeaser({required this.docs});

  @override
  Widget build(BuildContext context) {
    final published = docs.where((d) => d.isPublished).length;
    final totalViews = docs.fold<int>(0, (sum, d) => sum + d.views);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _StatTile(value: '${docs.length}', label: 'documents')),
          Container(width: 1, height: 32, color: Colors.black12),
          Expanded(child: _StatTile(value: '$published', label: 'publiés')),
          Container(width: 1, height: 32, color: Colors.black12),
          Expanded(child: _StatTile(value: '$totalViews', label: 'vues')),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppTheme.brandBlue.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppTheme.brandBlue : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final DocumentItem document;
  final bool busy;
  final VoidCallback onTogglePublish;

  const _DocumentRow({required this.document, required this.busy, required this.onTogglePublish});

  @override
  Widget build(BuildContext context) {
    final doc = document;
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
                      onPressed: onTogglePublish,
                      icon: Icon(
                        doc.isPublished ? Icons.visibility_off_outlined : Icons.publish_outlined,
                        size: 18,
                      ),
                      label: Text(doc.isPublished ? 'Dépublier' : 'Publier'),
                    ),
            ),
          ],
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

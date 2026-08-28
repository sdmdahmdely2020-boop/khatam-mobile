import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../account/screens/account_screen.dart';
import '../../auth/state/auth_state.dart';
import '../models/document_item.dart';
import '../services/catalog_service.dart';
import '../state/catalog_state.dart';
import 'document_detail_screen.dart';
import 'favorites_screen.dart';

/// Point d'entrée du catalogue : construit [CatalogState] à partir du
/// client HTTP déjà configuré par [AuthState] (voir `AuthState.apiClient`),
/// sans avoir besoin de toucher `main.dart`. C'est cet écran qu'il faut
/// pousser après une connexion ou une vérification d'email réussie.
class CatalogHome extends StatelessWidget {
  const CatalogHome({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<AuthState>().apiClient;
    return ChangeNotifierProvider<CatalogState>(
      create: (_) => CatalogState(catalogService: CatalogService(apiClient: apiClient))..load(),
      child: const CatalogScreen(),
    );
  }
}

const List<_SerieOption> _series = [
  _SerieOption(label: 'Toutes', value: null),
  _SerieOption(label: 'Série C', value: 'C'),
  _SerieOption(label: 'Série D', value: 'D'),
  _SerieOption(label: 'Série A', value: 'A'),
];

class _SerieOption {
  final String label;
  final String? value;
  const _SerieOption({required this.label, required this.value});
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = context.watch<CatalogState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khatam'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Mes favoris',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Rechercher un sujet, un corrigé...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            context.read<CatalogState>().search('');
                          },
                        ),
                ),
                onSubmitted: (value) => context.read<CatalogState>().search(value),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: _series.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = _series[index];
                  final selected = catalogState.serieFilter == option.value;
                  return ChoiceChip(
                    label: Text(option.label),
                    selected: selected,
                    selectedColor: AppTheme.brandBlue.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.brandBlue : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (_) => context.read<CatalogState>().setSerie(option.value),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildBody(catalogState)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CatalogState state) {
    if (state.status == CatalogStatus.loading && state.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CatalogStatus.error && state.documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40, color: Colors.black38),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ?? 'Une erreur est survenue.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<CatalogState>().load(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.documents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun document trouvé pour ces critères.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CatalogState>().load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: state.documents.length,
        itemBuilder: (context, index) => _DocumentCard(document: state.documents[index]),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentItem document;

  const _DocumentCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: document.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 84,
                  child: document.previewUrl.isEmpty
                      ? Container(color: const Color(0xFFEFF3F8))
                      : Image.network(
                          document.previewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEFF3F8)),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(color: const Color(0xFFEFF3F8));
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${document.matiere} · Série ${document.serie} · ${document.annee}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.professorFullName,
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(label: document.typeLabel, color: AppTheme.brandBlue),
                        _Tag(
                          label: document.priceLabel,
                          color: document.free ? AppTheme.brandGreen : Colors.orange.shade800,
                        ),
                        if (document.unlocked)
                          const _Tag(label: 'Débloqué', color: AppTheme.brandGreen, filled: true),
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
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _Tag({required this.label, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

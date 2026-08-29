import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/subject_icons.dart';
import '../../account/screens/account_screen.dart';
import '../../ads/widgets/ad_carousel.dart';
import '../../auth/state/auth_state.dart';
import '../../subscriptions/screens/subscription_plans_screen.dart';
import '../../subscriptions/services/subscription_service.dart';
import '../../subscriptions/state/subscription_state.dart';
import '../models/document_item.dart';
import '../services/catalog_service.dart';
import '../state/catalog_state.dart';
import '../widgets/subject_quick_filter.dart';
import '../widgets/weekly_pick_carousel.dart';
import 'document_detail_screen.dart';
import 'favorites_screen.dart';

/// Point d'entrée du catalogue : construit [CatalogState] à partir du
/// client HTTP déjà configuré par [AuthState] (voir `AuthState.apiClient`),
/// sans avoir besoin de toucher `main.dart`. C'est cet écran qu'il faut
/// pousser après une connexion ou une vérification d'email réussie.
///
/// [SubscriptionState] est fourni ici de la même façon, localement plutôt
/// que dans `app.dart` (voir `subscription_state.dart`) — nécessaire dès
/// l'accueil pour savoir s'il faut afficher les publicités et le bandeau
/// d'abonnement.
class CatalogHome extends StatelessWidget {
  const CatalogHome({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = context.read<AuthState>().apiClient;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CatalogState>(
          create: (_) => CatalogState(catalogService: CatalogService(apiClient: apiClient))..load(),
        ),
        ChangeNotifierProvider<SubscriptionState>(
          create: (_) => SubscriptionState(subscriptionService: SubscriptionService(apiClient: apiClient))..load(),
        ),
      ],
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

/// Écran d'accueil élève : salutation personnalisée, recherche + filtres
/// (série, matière), "Sélection de la semaine" (mise en avant éditoriale,
/// pas une nouvelle offre payante — chaque document garde son prix habituel,
/// voir `WeeklyPickCarousel`), bandeau publicitaire, puis le catalogue.
/// L'ensemble défile comme une seule page (`CustomScrollView`) pour rester
/// fluide même avec beaucoup de documents.
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
        child: RefreshIndicator(
          onRefresh: () => context.read<CatalogState>().load(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, catalogState)),
              _buildListSliver(catalogState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CatalogState catalogState) {
    final user = context.watch<AuthState>().currentUser;
    final subscriptionState = context.watch<SubscriptionState>();
    final firstName = (user?.fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    final isBrowsingFreely =
        catalogState.searchQuery.trim().isEmpty && catalogState.matiereKeywordFilter == null;

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
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Que veux-tu réviser aujourd\'hui ?',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
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
        _SubscriptionBanner(subscriptionState: subscriptionState),
        const SubjectQuickFilter(),
        // La sélection de la semaine ne s'affiche que sur l'accueil "libre"
        // (pas de recherche/filtre matière en cours) pour ne pas distraire
        // un élève qui cherche déjà quelque chose de précis.
        if (isBrowsingFreely) const WeeklyPickCarousel(),
        // Un abonné Premium ne voit plus jamais de publicité — on omet le
        // widget entièrement (pas juste masqué) pour ne pas gaspiller un
        // appel réseau inutile vers le service de pubs.
        if (!subscriptionState.isPremium) const AdCarousel(zone: 'catalog'),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildListSliver(CatalogState state) {
    if (state.status == CatalogStatus.loading && state.documents.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == CatalogStatus.error && state.documents.isEmpty) {
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
        ),
      );
    }

    final visible = state.visibleDocuments;
    if (visible.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aucun document trouvé pour ces critères.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      // SliverChildBuilderDelegate plutôt que le raccourci SliverList.builder
      // (ajouté dans une version récente de Flutter, pas garanti disponible
      // ici puisque cette session ne peut jamais compiler/tester le code
      // avant livraison) — cette forme existe depuis les tout premiers
      // slivers, aucun risque de version.
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _DocumentCard(document: visible[index]),
          childCount: visible.length,
        ),
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
                    Row(
                      children: [
                        SubjectIcon(matiere: document.matiere, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${document.matiere} · Série ${document.serie} · ${document.annee}',
                            style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Tag(label: document.typeLabel, color: AppTheme.brandBlue),
                        // Prix réduit (abonné Basic) : le prix de base barré à
                        // côté du prix réellement payé — jamais l'inverse, pour
                        // que l'élève voie clairement l'économie.
                        if (document.subscriptionDiscountApplied && !document.free) ...[
                          Text(
                            document.priceLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          _Tag(label: document.effectivePriceLabel, color: AppTheme.brandBlue),
                        ] else
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

/// Bandeau d'accueil affichant le plan actif, ou une invitation à souscrire
/// pour un élève "Gratuit". Auto-suffisant : ne fait rien tant que
/// [SubscriptionState.load] (lancé par [CatalogHome]) n'a pas répondu, pour
/// ne jamais afficher un état intermédiaire trompeur.
class _SubscriptionBanner extends StatelessWidget {
  final SubscriptionState subscriptionState;

  const _SubscriptionBanner({required this.subscriptionState});

  @override
  Widget build(BuildContext context) {
    if (subscriptionState.status != SubscriptionLoadStatus.loaded) {
      return const SizedBox.shrink();
    }

    final isPremium = subscriptionState.isPremium;
    final isBasic = subscriptionState.isBasic;
    final color = isPremium ? AppTheme.brandGreen : AppTheme.brandBlue;

    final String title;
    final String subtitle;
    if (isPremium) {
      title = 'Abonnement Premium actif';
      subtitle = 'Sans publicité, accès prioritaire aux nouveaux documents.';
    } else if (isBasic) {
      title = 'Abonnement Basic actif';
      subtitle = 'Réduction appliquée sur tous les documents payants.';
    } else {
      title = 'Passez à Basic ou Premium';
      subtitle = 'Réductions sur les documents et suppression des publicités.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
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

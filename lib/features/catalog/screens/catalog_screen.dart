import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/subject_icons.dart';
import '../../account/screens/account_screen.dart';
import '../../ads/widgets/ad_carousel.dart';
import '../../auth/state/auth_state.dart';
import '../../motivation/state/motivation_state.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/services/profile_service.dart';
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
        // Motivation (série de jours + objectif hebdomadaire + économies du
        // mois, 29/08) — voir `motivation_state.dart`. Un seul appel réseau
        // vers une route déjà existante (`GET /api/documents/mine`).
        ChangeNotifierProvider<MotivationState>(
          create: (_) => MotivationState(profileService: ProfileService(apiClient: apiClient))..load(),
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

  /// Série de jours d'affilée (motivation, 29/08) — `null` tant qu'elle n'a
  /// pas encore été calculée (évite d'afficher brièvement "0 jour" au tout
  /// premier affichage). Voir `LocalStorage.recordActivityAndGetStreak()` :
  /// purement local à cet appareil, aucun changement backend.
  int? _streakDays;

  @override
  void initState() {
    super.initState();
    LocalStorage().recordActivityAndGetStreak().then((days) {
      if (mounted) setState(() => _streakDays = days);
    });
  }

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
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Mes favoris',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Mon profil',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
    final motivationState = context.watch<MotivationState>();
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
          child: Row(
            children: [
              Expanded(
                child: Text(
                  firstName.isEmpty ? 'Bonjour' : 'Bonjour, $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _PlanBadge(subscriptionState: subscriptionState),
            ],
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
        _MotivationStrip(streakDays: _streakDays, motivationState: motivationState),
        _SubscriptionBanner(subscriptionState: subscriptionState),
        _SavingsCard(subscriptionState: subscriptionState, motivationState: motivationState),
        _ProgressBySubject(documents: catalogState.documents),
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
    // Un document payant jamais débloqué (ni acheté, ni pub, ni couvert par
    // un abonnement Premium — auquel cas le serveur renverrait déjà
    // `unlocked: true`, voir `hasAccess()` côté backend) : cadenas sur la
    // vignette + indication qu'un abonnement Premium le débloquerait.
    final locked = !document.free && !document.unlocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Ouverture directe pour tout ce qui est gratuit ou déjà débloqué
        // (comportement inchangé). Pour un document verrouillé, une étape
        // intermédiaire ("upsell intelligent", demandé le 29/08) explique
        // d'abord le prix/l'inclusion Premium avant de continuer — jamais
        // bloquant, l'élève peut toujours choisir "Voir le document".
        onTap: locked ? () => _showUpsellSheet(context, document) : () => _openDocument(context, document),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      document.previewUrl.isEmpty
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
                      if (locked)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_outline, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
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
                        if (locked)
                          const _Tag(label: '🔒 Inclus dans Premium', color: AppTheme.brandGreen),
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

void _openDocument(BuildContext context, DocumentItem document) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: document.id)),
  );
}

/// "Upsell intelligent" (29/08) : avant d'ouvrir un document verrouillé,
/// une feuille explique clairement le prix (ou l'inclusion Premium) et
/// pourquoi ce document est utile, avec deux choix — continuer normalement,
/// ou aller directement vers les abonnements. Jamais bloquant : l'élève
/// choisit toujours ce qu'il veut, cette étape ne fait qu'ajouter du
/// contexte au bon moment.
void _showUpsellSheet(BuildContext context, DocumentItem document) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline, color: AppTheme.brandGreen, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ce document peut t\'aider à réussir ton examen 🎯',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined, size: 16, color: AppTheme.brandGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Inclus dans Premium — ou ${document.priceLabel} à l\'unité',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Réussir mon Bac 🚀',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _openDocument(context, document);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Voir le document', style: TextStyle(fontSize: 13.5)),
              ),
            ),
          ],
        ),
      );
    },
  );
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
      // Message de valeur (29/08) : on parle du bénéfice pour l'élève
      // (réussir le Bac), pas du produit ("abonnement").
      title = 'Réussir mon Bac 🚀';
      subtitle = 'Accès illimité aux TD et corrigés, sans publicité.';
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
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13.5),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              if (!isPremium) ...[
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Réussir mon Bac 🚀',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ] else
                Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Motivation" (29/08) : série de jours d'affilée (locale à l'appareil,
/// voir `LocalStorage.recordActivityAndGetStreak`) + objectif hebdomadaire
/// (nombre de documents débloqués cette semaine, voir `MotivationState`).
/// La série s'affiche dès qu'elle est calculée (quasi instantané, purement
/// local) ; le bloc "objectif" n'apparaît qu'une fois [MotivationState]
/// chargé, pour ne jamais afficher "0/2" de façon trompeuse le temps du
/// chargement réseau.
class _MotivationStrip extends StatelessWidget {
  final int? streakDays;
  final MotivationState motivationState;

  const _MotivationStrip({required this.streakDays, required this.motivationState});

  @override
  Widget build(BuildContext context) {
    if (streakDays == null) return const SizedBox.shrink();

    final loaded = motivationState.status == MotivationLoadStatus.loaded;
    final weeklyCount = motivationState.summary.weeklyUnlockedCount;
    const weeklyGoal = MotivationState.weeklyGoal;
    final weeklyRatio = (weeklyCount / weeklyGoal).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$streakDays',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        streakDays == 1 ? 'jour d\'affilée' : 'jours d\'affilée',
                        style: const TextStyle(color: Colors.black54, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (loaded) ...[
              Container(width: 1, height: 36, color: Colors.black12),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Objectif de la semaine',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '$weeklyCount/$weeklyGoal',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: weeklyRatio,
                        minHeight: 6,
                        backgroundColor: Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandGreen),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Économies" (29/08) — voir `MotivationSummary` pour la limite honnête
/// concernant les abonnés Premium (aucune donnée d'achat individuel à partir
/// du moment où l'abonnement est actif, donc aucun montant inventé : message
/// de valeur à la place d'un chiffre). Rien tant que l'abonnement ET la
/// motivation ne sont pas tous deux chargés, et rien du tout pour un élève
/// "Free" (le bandeau au-dessus invite déjà à s'abonner).
class _SavingsCard extends StatelessWidget {
  final SubscriptionState subscriptionState;
  final MotivationState motivationState;

  const _SavingsCard({required this.subscriptionState, required this.motivationState});

  @override
  Widget build(BuildContext context) {
    if (subscriptionState.status != SubscriptionLoadStatus.loaded) return const SizedBox.shrink();
    if (subscriptionState.isFree) return const SizedBox.shrink();

    final String title;
    final String subtitle;

    if (subscriptionState.isPremium) {
      title = 'Accès illimité activé';
      subtitle = 'Aucune limite ce mois-ci sur les documents payants du catalogue.';
    } else {
      if (motivationState.status != MotivationLoadStatus.loaded) return const SizedBox.shrink();
      final saved = motivationState.summary.monthlySavingsMru;
      // Rien à afficher tant qu'aucune économie réelle n'a encore eu lieu ce
      // mois-ci — jamais de "0 MRU économisé", peu motivant et peu honnête
      // comme accroche.
      if (saved <= 0) return const SizedBox.shrink();
      title = 'Vous avez économisé ${saved.toStringAsFixed(0)} MRU';
      subtitle = 'Grâce à votre réduction Basic, ce mois-ci.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.brandGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Text('💰', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brandGreen,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit badge de plan (Free/Basic/Premium) affiché à côté de la salutation.
/// Même règle que [_SubscriptionBanner] : rien tant que
/// [SubscriptionState.load] n'a pas répondu, pour ne jamais afficher un état
/// intermédiaire trompeur (ex. "Free" pendant une fraction de seconde pour
/// un élève en fait déjà Premium).
class _PlanBadge extends StatelessWidget {
  final SubscriptionState subscriptionState;

  const _PlanBadge({required this.subscriptionState});

  @override
  Widget build(BuildContext context) {
    if (subscriptionState.status != SubscriptionLoadStatus.loaded) {
      return const SizedBox.shrink();
    }

    final isPremium = subscriptionState.isPremium;
    final isBasic = subscriptionState.isBasic;
    final label = isPremium ? 'Premium' : (isBasic ? 'Basic' : 'Free');
    final color = isPremium ? AppTheme.brandGreen : (isBasic ? AppTheme.brandBlue : Colors.black45);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// "Ma progression" — pourcentage de documents accessibles par matière,
/// calculé côté app à partir du catalogue déjà chargé (aucun appel réseau
/// supplémentaire, aucun champ serveur dédié). "Accessible" inclut les
/// documents gratuits, achetés, débloqués par pub, ou couverts par un
/// abonnement Premium — voir [DocumentItem.unlocked]. Limité aux 5 matières
/// les plus représentées dans le catalogue actuel pour rester "simple",
/// comme demandé — pas une liste exhaustive de toutes les matières libres
/// saisies par les professeurs.
class _ProgressBySubject extends StatelessWidget {
  final List<DocumentItem> documents;

  const _ProgressBySubject({required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();

    final totals = <String, int>{};
    final unlockedCounts = <String, int>{};
    for (final doc in documents) {
      totals[doc.matiere] = (totals[doc.matiere] ?? 0) + 1;
      if (doc.unlocked) unlockedCounts[doc.matiere] = (unlockedCounts[doc.matiere] ?? 0) + 1;
    }

    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ma progression', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            const SizedBox(height: 10),
            ...top.map((entry) {
              final total = entry.value;
              final done = unlockedCounts[entry.key] ?? 0;
              final ratio = total == 0 ? 0.0 : done / total;
              final percent = (ratio * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SubjectIcon(matiere: entry.key, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            entry.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.brandBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandBlue),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
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

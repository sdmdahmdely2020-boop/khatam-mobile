import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/subject_icons.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/state/auth_state.dart';
import '../../catalog/screens/document_detail_screen.dart';
import '../../subscriptions/models/subscription_models.dart';
import '../../subscriptions/screens/subscription_plans_screen.dart';
import '../../subscriptions/services/subscription_service.dart';
import '../models/my_document_entry.dart';
import '../services/profile_service.dart';

/// "Mon profil" — écran demandé le 29/08 pour regrouper en un seul endroit,
/// en cartes Material : identité (nom, téléphone), abonnement (plan +
/// date d'expiration si actif) et documents précédemment débloqués. Aucun
/// changement backend : réutilise `GET /api/subscriptions/me` (déjà utilisé
/// par [SubscriptionPlansScreen]) et `GET /api/documents/mine` (déjà
/// utilisé par [MyDocumentsScreen]), simplement présentés ensemble ici.
///
/// Écran séparé de "Mon compte" (qui garde son rôle : déconnexion, accès
/// aux corrections IA, etc.) — les deux restent accessibles.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileData {
  final SubscriptionStatusInfo subscription;
  final MyDocumentsResult documents;

  _ProfileData({required this.subscription, required this.documents});
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final SubscriptionService _subscriptionService;
  late final ProfileService _profileService;
  late Future<_ProfileData> _future;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _subscriptionService = SubscriptionService(apiClient: apiClient);
    _profileService = ProfileService(apiClient: apiClient);
    _future = _load();
  }

  Future<_ProfileData> _load() async {
    final results = await Future.wait([
      _subscriptionService.fetchMe(),
      _profileService.fetchMine(),
    ]);
    return _ProfileData(
      subscription: results[0] as SubscriptionStatusInfo,
      documents: results[1] as MyDocumentsResult,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
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
                        'Impossible de charger votre profil.',
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

            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                final next = _load();
                setState(() => _future = next);
                await next.catchError(
                  (_) => _ProfileData(
                    subscription: SubscriptionStatusInfo.free(),
                    documents: MyDocumentsResult(entries: [], progress: StudentProgress.empty()),
                  ),
                );
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _UserInfoCard(user: user),
                  const SizedBox(height: 14),
                  _SubscriptionCard(subscription: data.subscription),
                  const SizedBox(height: 20),
                  const Text(
                    'Documents débloqués',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  if (data.documents.entries.isEmpty)
                    _EmptyDocumentsCard(isPremium: data.documents.progress.isPremium)
                  else
                    ...data.documents.entries.map(
                      (entry) => _PurchasedDocCard(entry: entry, onReturn: _reload),
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

/// Carte "identité" : nom + téléphone, comme demandé. L'email et la
/// déconnexion restent sur "Mon compte" pour ne pas dupliquer ce qui existe
/// déjà ailleurs.
class _UserInfoCard extends StatelessWidget {
  final AuthUser? user;

  const _UserInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7EBF1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE7EFF8),
              ),
              child: const Icon(Icons.person_outline, color: AppTheme.brandBlue, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_android_outlined, size: 14, color: Colors.black45),
                      const SizedBox(width: 5),
                      Text(
                        user?.phone ?? '—',
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte "abonnement" : badge de plan (mêmes couleurs que sur l'accueil —
/// gris/bleu/vert) + date d'expiration si un plan payant est actif. Pour un
/// élève "Free", un bouton "Devenir Premium" mène vers les formules, comme
/// sur le bandeau de l'accueil.
class _SubscriptionCard extends StatelessWidget {
  final SubscriptionStatusInfo subscription;

  const _SubscriptionCard({required this.subscription});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isPremium = subscription.isPremium;
    final isBasic = subscription.isBasic;
    final label = isPremium ? 'Premium' : (isBasic ? 'Basic' : 'Free');
    final color = isPremium ? AppTheme.brandGreen : (isBasic ? AppTheme.brandBlue : Colors.black45);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7EBF1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Abonnement',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Spacer(),
                Container(
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
                ),
              ],
            ),
            if ((isPremium || isBasic) && subscription.expiresAt != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 15, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text(
                    'Expire le ${_formatDate(subscription.expiresAt!)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                  ),
                ],
              ),
            ],
            if (!isPremium) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isBasic ? 'Passer à Premium' : 'Devenir Premium',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyDocumentsCard extends StatelessWidget {
  final bool isPremium;

  const _EmptyDocumentsCard({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE7EBF1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.menu_book_outlined, size: 36, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              isPremium
                  ? "Aucun achat individuel — normal, votre abonnement Premium vous donne déjà accès à tout le catalogue."
                  : "Aucun document débloqué pour l'instant.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une carte compacte par document débloqué — mêmes informations que sur
/// "Mes documents" (voir `my_documents_screen.dart`) mais présentées comme
/// une carte Material classique pour rester cohérent avec le reste de cet
/// écran.
class _PurchasedDocCard extends StatelessWidget {
  final MyDocumentEntry entry;
  final VoidCallback onReturn;

  const _PurchasedDocCard({required this.entry, required this.onReturn});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final doc = entry.document;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE7EBF1)),
      ),
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
                  width: 52,
                  height: 68,
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SubjectIcon(matiere: doc.matiere, size: 14),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${doc.matiere} · Série ${doc.serie}',
                            style: const TextStyle(color: Colors.black54, fontSize: 11.5),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (entry.isPurchase ? AppTheme.brandBlue : AppTheme.brandGreen)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.isPurchase
                                ? 'Acheté · ${entry.amountPaid.toStringAsFixed(0)} MRU'
                                : 'Débloqué par pub',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: entry.isPurchase ? AppTheme.brandBlue : AppTheme.brandGreen,
                            ),
                          ),
                        ),
                        if (entry.acquiredAt != null)
                          Text(
                            _formatDate(entry.acquiredAt!),
                            style: const TextStyle(fontSize: 10.5, color: Colors.black45),
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
}

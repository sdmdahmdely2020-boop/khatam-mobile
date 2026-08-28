import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/subject_icons.dart';
import '../../auth/state/auth_state.dart';
import '../../catalog/models/document_item.dart';
import '../models/wallet.dart';
import '../services/professor_service.dart';
import '../services/wallet_service.dart';

const _monthAbbrev = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// Statistiques avancées d'un professeur : combine deux appels déjà
/// existants (`GET /api/documents`, filtré côté client sur ses propres
/// documents — voir `ProfessorService.fetchMyDocuments` — et
/// `GET /api/wallet`, voir `WalletService.fetchWallet`) plutôt que
/// d'ajouter une route serveur dédiée : tout ce qu'il faut (vues par
/// document, ventes confirmées avec montant/date/document) est déjà
/// disponible dans ces deux réponses.
class ProfessorStatsScreen extends StatefulWidget {
  const ProfessorStatsScreen({super.key});

  @override
  State<ProfessorStatsScreen> createState() => _ProfessorStatsScreenState();
}

class _ProfessorStatsScreenState extends State<ProfessorStatsScreen> {
  late final ProfessorService _professorService;
  late final WalletService _walletService;
  late Future<_StatsData> _future;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _professorService = ProfessorService(apiClient: apiClient);
    _walletService = WalletService(apiClient: apiClient);
    _future = _load();
  }

  Future<_StatsData> _load() async {
    final userId = context.read<AuthState>().currentUser?.id ?? '';
    final results = await Future.wait([
      _professorService.fetchMyDocuments(professorId: userId),
      _walletService.fetchWallet(),
    ]);
    return _StatsData.compute(
      documents: results[0] as List<DocumentItem>,
      wallet: results[1] as Wallet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.brandBlue,
      ),
      body: SafeArea(
        child: FutureBuilder<_StatsData>(
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
                        'Impossible de charger les statistiques.',
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

            final data = snapshot.data!;
            if (data.totalDocuments == 0) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Envoyez au moins un document pour voir vos statistiques apparaître ici.',
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
                await next.catchError((_) => data);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.visibility_outlined,
                          label: 'Vues totales',
                          value: '${data.totalViews}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Ventes confirmées',
                          value: '${data.salesCount}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.payments_outlined,
                          label: 'Revenu total',
                          value: '${data.totalRevenue.toStringAsFixed(0)} MRU',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.percent,
                          label: 'Taux de conversion',
                          value: data.totalViews > 0
                              ? '${data.conversionRate.toStringAsFixed(1)}%'
                              : '—',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Taux de conversion = ventes confirmées ÷ vues — une estimation, pas un chiffre exact.',
                      style: TextStyle(color: Colors.black38, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (data.topByViews != null)
                    _HighlightCard(
                      icon: Icons.trending_up,
                      color: AppTheme.brandBlue,
                      label: 'Document le plus consulté',
                      title: data.topByViews!.title,
                      detail: '${data.topByViews!.views} vue${data.topByViews!.views > 1 ? 's' : ''}',
                    ),
                  if (data.topBySales != null) ...[
                    const SizedBox(height: 12),
                    _HighlightCard(
                      icon: Icons.emoji_events_outlined,
                      color: AppTheme.brandGreen,
                      label: 'Meilleure vente',
                      title: data.topBySales!.title,
                      detail:
                          '${data.topBySales!.revenue.toStringAsFixed(0)} MRU · ${data.topBySales!.count} vente${data.topBySales!.count > 1 ? 's' : ''}',
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Text('Revenus des 6 derniers mois', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  _RevenueBarChart(entries: data.revenueByMonth),
                  if (data.viewsByMatiere.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text('Vues par matière', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 14),
                    ...data.viewsByMatiere.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MatiereBar(
                          matiere: e.key,
                          views: e.value,
                          maxViews: data.viewsByMatiere.first.value,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Statistiques dérivées de [documents] (vues, répartition par matière) et
/// de [Wallet.sales] (revenu, meilleure vente, tendance mensuelle) — calcul
/// entièrement côté app, aucune route serveur supplémentaire nécessaire.
class _StatsData {
  final int totalDocuments;
  final int totalViews;
  final int salesCount;
  final num totalRevenue;
  final double conversionRate;
  final DocumentItem? topByViews;
  final _TopSalesInfo? topBySales;
  final List<_MonthRevenue> revenueByMonth;
  final List<MapEntry<String, int>> viewsByMatiere;

  _StatsData({
    required this.totalDocuments,
    required this.totalViews,
    required this.salesCount,
    required this.totalRevenue,
    required this.conversionRate,
    required this.topByViews,
    required this.topBySales,
    required this.revenueByMonth,
    required this.viewsByMatiere,
  });

  factory _StatsData.compute({
    required List<DocumentItem> documents,
    required Wallet wallet,
  }) {
    final totalViews = documents.fold<int>(0, (sum, d) => sum + d.views);
    final totalRevenue = wallet.sales.fold<num>(0, (sum, s) => sum + s.amount);
    final conversionRate =
        totalViews > 0 ? (wallet.sales.length / totalViews) * 100 : 0.0;

    DocumentItem? topByViews;
    for (final d in documents) {
      if (topByViews == null || d.views > topByViews.views) topByViews = d;
    }
    if (topByViews != null && topByViews.views == 0) topByViews = null;

    // Regroupe les ventes par document pour trouver celui qui a rapporté le
    // plus (pas forcément le même que le plus consulté).
    final revenueByDoc = <String, _TopSalesInfo>{};
    for (final s in wallet.sales) {
      final existing = revenueByDoc[s.documentTitle];
      if (existing == null) {
        revenueByDoc[s.documentTitle] = _TopSalesInfo(title: s.documentTitle, revenue: s.amount, count: 1);
      } else {
        revenueByDoc[s.documentTitle] = _TopSalesInfo(
          title: s.documentTitle,
          revenue: existing.revenue + s.amount,
          count: existing.count + 1,
        );
      }
    }
    _TopSalesInfo? topBySales;
    for (final info in revenueByDoc.values) {
      if (topBySales == null || info.revenue > topBySales.revenue) topBySales = info;
    }

    // 6 derniers mois calendaires (y compris ceux sans vente, à 0 MRU) pour
    // une vraie tendance plutôt que seulement les mois où il y a eu une vente.
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final ref = DateTime(now.year, now.month - (5 - i), 1);
      return ref;
    });
    final revenueByMonth = months.map((m) {
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      num total = 0;
      for (final s in wallet.sales) {
        final date = s.confirmedAt != null ? DateTime.tryParse(s.confirmedAt!) : null;
        if (date == null) continue;
        final saleKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (saleKey == key) total += s.amount;
      }
      return _MonthRevenue(label: _monthAbbrev[m.month - 1], amount: total);
    }).toList();

    // Vues cumulées par matière (texte brut du professeur, tel quel — même
    // logique de regroupement "simple" que le reste de l'app, l'icône
    // affichée à côté utilise elle SubjectIcon pour la reconnaissance par
    // mot-clé).
    final viewsByMatiereMap = <String, int>{};
    for (final d in documents) {
      if (d.matiere.trim().isEmpty) continue;
      viewsByMatiereMap[d.matiere] = (viewsByMatiereMap[d.matiere] ?? 0) + d.views;
    }
    final viewsByMatiere = viewsByMatiereMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _StatsData(
      totalDocuments: documents.length,
      totalViews: totalViews,
      salesCount: wallet.sales.length,
      totalRevenue: totalRevenue,
      conversionRate: conversionRate,
      topByViews: topByViews,
      topBySales: topBySales,
      revenueByMonth: revenueByMonth,
      viewsByMatiere: viewsByMatiere.take(6).toList(),
    );
  }
}

class _TopSalesInfo {
  final String title;
  final num revenue;
  final int count;

  const _TopSalesInfo({required this.title, required this.revenue, required this.count});
}

class _MonthRevenue {
  final String label;
  final num amount;

  const _MonthRevenue({required this.label, required this.amount});
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.brandBlue, size: 20),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String title;
  final String detail;

  const _HighlightCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final List<_MonthRevenue> entries;
  static const double _chartHeight = 120;

  const _RevenueBarChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final maxAmount = entries.fold<num>(0, (m, e) => e.amount > m ? e.amount : m);
    final total = entries.fold<num>(0, (sum, e) => sum + e.amount);

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Aucun revenu sur cette période.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: _chartHeight + 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((e) {
          final barHeight = maxAmount > 0
              ? (e.amount / maxAmount * _chartHeight).clamp(e.amount > 0 ? 4.0 : 0.0, _chartHeight)
              : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    e.amount > 0 ? e.amount.toStringAsFixed(0) : '',
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: barHeight.toDouble(),
                    decoration: BoxDecoration(
                      color: e.amount > 0 ? AppTheme.brandGreen : const Color(0xFFE7EFF8),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(e.label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MatiereBar extends StatelessWidget {
  final String matiere;
  final int views;
  final int maxViews;

  const _MatiereBar({required this.matiere, required this.views, required this.maxViews});

  @override
  Widget build(BuildContext context) {
    final ratio = maxViews > 0 ? views / maxViews : 0.0;
    return Row(
      children: [
        SubjectIcon(matiere: matiere, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      matiere,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('$views', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE7EFF8),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.brandBlue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

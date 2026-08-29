import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/subject_icons.dart';
import '../../auth/state/auth_state.dart';
import '../models/document_item.dart';
import '../services/catalog_service.dart';
import '../screens/document_detail_screen.dart';

/// "Sélection de la semaine" — un petit groupe de documents mis en avant sur
/// l'accueil, qui change automatiquement chaque semaine. Volontairement
/// simple (pas d'IA, pas de nouvelle route serveur, pas de nouveau prix
/// "bundle") : c'est une mise en avant éditoriale de documents qui existent
/// déjà, chacun gardant son propre prix/déblocage habituel — appuyer dessus
/// ouvre la fiche document normale, exactement comme depuis le catalogue.
/// Se recharge indépendamment du reste de l'écran (son propre appel réseau,
/// non affecté par la recherche/le filtre en cours) pour rester stable même
/// si l'élève est en train de chercher autre chose.
class WeeklyPickCarousel extends StatefulWidget {
  const WeeklyPickCarousel({super.key});

  @override
  State<WeeklyPickCarousel> createState() => _WeeklyPickCarouselState();
}

class _WeeklyPickCarouselState extends State<WeeklyPickCarousel> {
  late final CatalogService _service;
  late Future<List<DocumentItem>> _future;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthState>().apiClient;
    _service = CatalogService(apiClient: apiClient);
    _future = _service.fetchDocuments();
  }

  /// Choisit jusqu'à 6 documents parmi les plus populaires/mis en avant, puis
  /// les mélange avec une graine dérivée de l'année + du numéro de semaine
  /// (approximatif, pas un vrai calcul ISO 8601 — inutile ici, il suffit que
  /// la sélection reste stable ~7 jours puis change) — donne l'impression
  /// d'une "sélection de la semaine" qui tourne, sans réel calcul côté
  /// serveur ni IA.
  List<DocumentItem> _weeklyPicks(List<DocumentItem> all) {
    final pool = List<DocumentItem>.from(all)
      ..sort((a, b) {
        if (a.professorBoosted != b.professorBoosted) {
          return a.professorBoosted ? -1 : 1;
        }
        return b.views.compareTo(a.views);
      });
    final topPool = pool.take(20).toList();
    topPool.shuffle(Random(_weekSeed(DateTime.now())));
    return topPool.take(6).toList();
  }

  int _weekSeed(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceYearStart = date.difference(firstDayOfYear).inDays;
    final week = daysSinceYearStart ~/ 7;
    return date.year * 100 + week;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentItem>>(
      future: _future,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <DocumentItem>[];
        if (snapshot.connectionState != ConnectionState.done || all.isEmpty) {
          // En chargement, en erreur, ou catalogue vide : rien à mettre en
          // avant, on n'affiche pas de section vide ou d'erreur ici — le
          // catalogue normal juste en dessous s'en charge déjà.
          return const SizedBox.shrink();
        }
        final picks = _weeklyPicks(all);
        if (picks.isEmpty) return const SizedBox.shrink();
        return _WeeklyPickSection(documents: picks);
      },
    );
  }
}

class _WeeklyPickSection extends StatelessWidget {
  final List<DocumentItem> documents;

  const _WeeklyPickSection({required this.documents});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18, color: AppTheme.brandBlue),
                SizedBox(width: 6),
                Text(
                  'Sélection de la semaine',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: documents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _WeeklyPickCard(document: documents[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyPickCard extends StatelessWidget {
  final DocumentItem document;

  const _WeeklyPickCard({required this.document});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: document.id)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 78,
                width: double.infinity,
                child: document.previewUrl.isEmpty
                    ? Container(color: const Color(0xFFEFF3F8))
                    : Image.network(
                        document.previewUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEFF3F8)),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SubjectIcon(matiere: document.matiere, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            document.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      document.priceLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: document.free ? AppTheme.brandGreen : Colors.orange.shade800,
                      ),
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

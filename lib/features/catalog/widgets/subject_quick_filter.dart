import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../state/catalog_state.dart';

/// Une matière du filtre rapide : [label] affiché, [keyword] transmis à
/// [CatalogState.setMatiereKeyword] (comparé au texte libre `matiere` de
/// chaque document via `SubjectIcons.matches`), [asset] l'icône du lot 3 de
/// l'identité visuelle (même fichier que celui utilisé par [SubjectIcon]
/// sur les cartes de documents, pour que le filtre et les icônes restent
/// visuellement cohérents).
class _Subject {
  final String label;
  final String keyword;
  final String asset;

  const _Subject({required this.label, required this.keyword, required this.asset});
}

const List<_Subject> _subjects = [
  _Subject(label: 'Maths', keyword: 'math', asset: 'assets/subjects/subject-mathematiques.png'),
  _Subject(label: 'Physique', keyword: 'physique', asset: 'assets/subjects/subject-physique.png'),
  _Subject(label: 'Chimie', keyword: 'chimie', asset: 'assets/subjects/subject-chimie.png'),
  _Subject(label: 'SVT', keyword: 'svt', asset: 'assets/subjects/subject-svt.png'),
  _Subject(label: 'Arabe', keyword: 'arabe', asset: 'assets/subjects/subject-arabe.png'),
  _Subject(label: 'Français', keyword: 'francais', asset: 'assets/subjects/subject-francais.png'),
  _Subject(label: 'Anglais', keyword: 'anglais', asset: 'assets/subjects/subject-anglais.png'),
  _Subject(
    label: 'Philosophie',
    keyword: 'philosophie',
    asset: 'assets/subjects/subject-philosophie.png',
  ),
  _Subject(
    label: 'Histoire-Géo',
    keyword: 'histoire',
    asset: 'assets/subjects/subject-histoire-geo.png',
  ),
];

/// Rangée horizontale d'icônes de matière (lot 3) permettant de filtrer le
/// catalogue d'un coup d'œil, sans passer par la recherche texte. Touche à
/// nouveau la matière déjà sélectionnée pour revenir à "Toutes".
class SubjectQuickFilter extends StatelessWidget {
  const SubjectQuickFilter({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogState = context.watch<CatalogState>();

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _subjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final selected = catalogState.matiereKeywordFilter == subject.keyword;
          return GestureDetector(
            onTap: () => context.read<CatalogState>().setMatiereKeyword(subject.keyword),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: AppTheme.brandBlue, width: 2) : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.asset(subject.asset, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppTheme.brandBlue : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

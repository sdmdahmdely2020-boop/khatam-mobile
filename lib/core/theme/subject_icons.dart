import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Fait correspondre le champ libre "matière" (texte tapé par le professeur
/// au moment de l'envoi d'un document, ex. "Mathématiques", "maths", "SVT",
/// "Sciences Naturelles"... — voir [DocumentItem.matiere], ce n'est PAS une
/// liste fermée côté serveur) à l'une des 9 icônes du lot 3 de l'identité
/// visuelle Khatam. La correspondance se fait par mots-clés (insensible aux
/// accents et à la casse) plutôt que par égalité stricte, pour couvrir les
/// variantes d'écriture les plus courantes.
class SubjectIcons {
  SubjectIcons._();

  /// Ordre important : les clés les plus spécifiques d'abord (ex. "svt"
  /// avant "sciences", pour éviter qu'un futur mot-clé générique n'écrase un
  /// cas précis). Chaque valeur est le chemin de l'asset correspondant.
  static const _keywordToAsset = <String, String>{
    'mathematique': 'assets/subjects/subject-mathematiques.png',
    'maths': 'assets/subjects/subject-mathematiques.png',
    'math': 'assets/subjects/subject-mathematiques.png',
    'physique': 'assets/subjects/subject-physique.png',
    'chimie': 'assets/subjects/subject-chimie.png',
    'svt': 'assets/subjects/subject-svt.png',
    'sciences naturelles': 'assets/subjects/subject-svt.png',
    'sciences de la vie': 'assets/subjects/subject-svt.png',
    'biologie': 'assets/subjects/subject-svt.png',
    'arabe': 'assets/subjects/subject-arabe.png',
    'francais': 'assets/subjects/subject-francais.png',
    'anglais': 'assets/subjects/subject-anglais.png',
    'english': 'assets/subjects/subject-anglais.png',
    'philosophie': 'assets/subjects/subject-philosophie.png',
    'philo': 'assets/subjects/subject-philosophie.png',
    'histoire': 'assets/subjects/subject-histoire-geo.png',
    'geographie': 'assets/subjects/subject-histoire-geo.png',
    'geo': 'assets/subjects/subject-histoire-geo.png',
  };

  /// Retire les accents et met en minuscules pour une comparaison robuste
  /// (ex. "Mathématiques" -> "mathematiques", "Sciences Naturelles" ->
  /// "sciences naturelles").
  static String _normalize(String input) {
    const withAccents = 'àâäéèêëïîôöùûüçÀÂÄÉÈÊËÏÎÔÖÙÛÜÇ';
    const withoutAccents = 'aaaeeeeiioouuucAAAEEEEIIOOUUUC';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final index = withAccents.indexOf(char);
      buffer.write(index == -1 ? char : withoutAccents[index]);
    }
    return buffer.toString().toLowerCase();
  }

  /// Retourne le chemin de l'asset correspondant, ou `null` si aucun mot-clé
  /// connu n'a été trouvé dans le texte (dans ce cas, [SubjectIcon] affiche
  /// un pictogramme générique plutôt que rien).
  static String? assetFor(String matiere) {
    final normalized = _normalize(matiere);
    for (final entry in _keywordToAsset.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Vrai si le texte libre [matiere] contient le mot-clé [keyword]
  /// (comparaison insensible aux accents et à la casse, même normalisation
  /// que [assetFor]). Utilisé par le filtre rapide par matière du catalogue
  /// (voir `SubjectQuickFilter`) — filtrage fait côté app plutôt que via le
  /// paramètre `matiere` de `GET /api/documents` côté serveur, qui exige une
  /// égalité EXACTE (voir `documents.js`) et raterait donc la plupart des
  /// documents puisque `matiere` est un texte libre tapé par chaque
  /// professeur (ex. "Maths" vs "Mathématiques").
  static bool matches(String matiere, String keyword) {
    return _normalize(matiere).contains(_normalize(keyword));
  }
}

/// Petit badge circulaire affichant l'icône de la matière correspondante
/// (ou un pictogramme générique si le texte tapé par le professeur n'est
/// reconnu par aucun mot-clé). [size] est le diamètre total du badge.
class SubjectIcon extends StatelessWidget {
  final String matiere;
  final double size;

  const SubjectIcon({super.key, required this.matiere, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final asset = SubjectIcons.assetFor(matiere);
    if (asset == null) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFE7EFF8),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.menu_book_outlined, size: size * 0.6, color: AppTheme.brandBlue),
      );
    }
    return ClipOval(
      child: Image.asset(asset, width: size, height: size, fit: BoxFit.cover),
    );
  }
}

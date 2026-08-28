import 'package:flutter/material.dart';

/// Thème Material 3 de Khatam — bleu/vert, dérivé de la palette de marque
/// (voir la charte graphique : #1E5FA8 / #1E8A4C).
class AppTheme {
  static const Color brandBlue = Color(0xFF1E5FA8);
  static const Color brandGreen = Color(0xFF1E8A4C);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandBlue,
      secondary: brandGreen,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF4F7FA),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEDF1F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: brandBlue,
          selectedForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(46),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Palette Bleu Nuit (Midnight Navy)
  static const Color navy950 = Color(0xFF050A14); // Fond principal sombre
  static const Color navy900 = Color(0xFF0A1222); // Cartes / surfaces élevées
  static const Color navy850 = Color(0xFF0F1A30); // Champs / barres secondaires
  static const Color navy800 = Color(0xFF172642); // Bordures subtiles sombres
  static const Color navy700 = Color(0xFF23375E); // Bordures actives sombres

  static const Color slate100 = Color(0xFFF1F5F9); // Fond clair
  static const Color slate200 = Color(0xFFE2E8F0); // Bordure claire
  static const Color slate400 = Color(0xFF94A3B8); // Texte secondaire sombre
  static const Color slate500 = Color(0xFF64748B); // Texte secondaire clair
  static const Color slate900 = Color(0xFF0F172A); // Texte principal clair

  static const Color accentBlue = Color(0xFF38BDF8);
  static const Color accentBlueDeep = Color(0xFF0F294A);
  static const Color emerald600 = Color(0xFF059669);
  static const Color red600 = Color(0xFFDC2626);

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: accentBlue,
      onPrimary: navy950,
      secondary: Color(0xFF60A5FA),
      onSecondary: navy950,
      surface: navy900,
      onSurface: Color(0xFFF8FAFC),
      error: red600,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: navy950,
      appBarTheme: const AppBarTheme(
        backgroundColor: navy950,
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: navy900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: navy800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navy850,
        hintStyle: const TextStyle(color: slate400, fontSize: 13),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navy800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: navy800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: red600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: navy950,
          disabledBackgroundColor: navy800,
          disabledForegroundColor: slate400,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: navy700),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: navy800,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF0A192F),
      onPrimary: Colors.white,
      secondary: Color(0xFF0284C7),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: slate900,
      error: red600,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: slate100,
      appBarTheme: const AppBarTheme(
        backgroundColor: slate100,
        foregroundColor: slate900,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: slate500, fontSize: 13),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0A192F), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A192F),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: slate200,
        thickness: 1,
      ),
    );
  }
}
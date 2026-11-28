import 'package:flutter/material.dart';

/// Palette MaliTrans (bleu nuit + bleu ciel).
class AppTheme {
  AppTheme._();

  static const Color navy950 = Color(0xFF050A14);
  static const Color navy900 = Color(0xFF0B1424);
  static const Color navy850 = Color(0xFF111D33);
  static const Color navy800 = Color(0xFF1A2944);
  static const Color navy700 = Color(0xFF23375E);
  static const Color navyBrand = Color(0xFF0A192F);

  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate900 = Color(0xFF0F172A);

  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky600 = Color(0xFF0284C7);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color amber500 = Color(0xFFF59E0B);

  static ThemeData get lightTheme => _theme(MtColors.light, Brightness.light);

  static ThemeData get darkTheme => _theme(MtColors.dark, Brightness.dark);

  static ThemeData _theme(MtColors c, Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final text = _textTheme(base.textTheme, c);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: c.tint,
        onPrimary: c.onPrimaryFill,
        surface: c.surface,
        onSurface: c.label,
        error: c.danger,
      ),
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: text,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: c.separator,
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.tint),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.tint),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.label,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.background),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      extensions: [c],
    );
  }

  /// Hiérarchie typographique : poids + taille + interligne ensemble.
  /// Approche serrée sur les grands textes, neutre sur le corps.
  static TextTheme _textTheme(TextTheme base, MtColors c) {
    return base.copyWith(
      // Montants mis en avant
      displaySmall: TextStyle(
        fontSize: 44, fontWeight: FontWeight.w700, height: 1.0, letterSpacing: -1.4,
        color: c.label, fontFeatures: const [FontFeature.tabularFigures()],
      ),
      // Grand titre de page
      headlineMedium: TextStyle(
        fontSize: 32, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.9, color: c.label,
      ),
      // Verdicts, titres de section importants
      headlineSmall: TextStyle(
        fontSize: 26, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.6, color: c.label,
      ),
      titleLarge: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.4, color: c.label,
      ),
      titleMedium: TextStyle(
        fontSize: 17, fontWeight: FontWeight.w600, height: 1.3, letterSpacing: -0.2, color: c.label,
      ),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.4, color: c.label),
      bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.4, color: c.label),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.35, color: c.labelSecondary),
      labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: c.label),
      // En-têtes de section (petites capitales)
      labelSmall: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: c.labelSecondary,
      ),
    );
  }
}

/// Couleurs sémantiques, résolues selon le thème clair / sombre.
@immutable
class MtColors extends ThemeExtension<MtColors> {
  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color label;
  final Color labelSecondary;
  final Color labelTertiary;
  final Color separator;
  final Color tint;
  final Color primaryFill;
  final Color onPrimaryFill;
  final Color success;
  final Color danger;
  final Color warning;

  /// Fond des barres translucides (au-dessus d'un flou).
  final Color glass;

  const MtColors({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.label,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.separator,
    required this.tint,
    required this.primaryFill,
    required this.onPrimaryFill,
    required this.success,
    required this.danger,
    required this.warning,
    required this.glass,
  });

  static const light = MtColors(
    background: Color(0xFFF2F4F8),
    surface: Colors.white,
    surfaceSecondary: Color(0xFFE9EDF3),
    label: AppTheme.slate900,
    labelSecondary: AppTheme.slate500,
    labelTertiary: AppTheme.slate400,
    separator: Color(0xFFDDE3EB),
    tint: AppTheme.sky600,
    primaryFill: AppTheme.navyBrand,
    onPrimaryFill: Colors.white,
    success: AppTheme.emerald600,
    danger: AppTheme.red600,
    warning: AppTheme.amber500,
    glass: Color(0xB8F2F4F8),
  );

  static const dark = MtColors(
    background: AppTheme.navy950,
    surface: AppTheme.navy900,
    surfaceSecondary: AppTheme.navy850,
    label: AppTheme.slate50,
    labelSecondary: AppTheme.slate400,
    labelTertiary: AppTheme.slate500,
    separator: AppTheme.navy800,
    tint: AppTheme.sky400,
    primaryFill: AppTheme.sky400,
    onPrimaryFill: AppTheme.navy950,
    success: AppTheme.emerald500,
    danger: AppTheme.red500,
    warning: AppTheme.amber500,
    glass: Color(0xB8050A14),
  );

  @override
  MtColors copyWith() => this;

  @override
  MtColors lerp(ThemeExtension<MtColors>? other, double t) {
    if (other is! MtColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return MtColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceSecondary: l(surfaceSecondary, other.surfaceSecondary),
      label: l(label, other.label),
      labelSecondary: l(labelSecondary, other.labelSecondary),
      labelTertiary: l(labelTertiary, other.labelTertiary),
      separator: l(separator, other.separator),
      tint: l(tint, other.tint),
      primaryFill: l(primaryFill, other.primaryFill),
      onPrimaryFill: l(onPrimaryFill, other.onPrimaryFill),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      warning: l(warning, other.warning),
      glass: l(glass, other.glass),
    );
  }
}

extension MtThemeContext on BuildContext {
  MtColors get c => Theme.of(this).extension<MtColors>()!;
  TextTheme get t => Theme.of(this).textTheme;

  /// L'utilisateur a demandé de réduire les animations.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// Contraste élevé : surfaces pleines au lieu de translucides.
  bool get highContrast => MediaQuery.highContrastOf(this);
}

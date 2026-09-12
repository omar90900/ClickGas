import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  /// Brand light green - used for fills (buttons, chips, indicators).
  static const brand = Color(0xFF53ED74);

  /// Deeper green for text/icons on light surfaces, where #53ED74 lacks contrast.
  static const brandDeep = Color(0xFF0E7A35);

  /// Text/icons drawn on top of [brand].
  static const onBrand = Color(0xFF00391A);

  static const warning = Color(0xFFF5A524);
  static const danger = Color(0xFFE5484D);
  static const info = Color(0xFF3B82F6);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    );
    final surface = isDark ? const Color(0xFF0E1411) : const Color(0xFFF6FAF7);
    final card = isDark ? const Color(0xFF17201B) : Colors.white;
    final accent = isDark ? AppColors.brand : AppColors.brandDeep;
    final scheme = base.copyWith(
      primary: AppColors.brand,
      onPrimary: AppColors.onBrand,
      primaryContainer:
          isDark ? const Color(0xFF114D27) : const Color(0xFFD9FBE2),
      onPrimaryContainer: isDark ? const Color(0xFFBDF8CC) : AppColors.onBrand,
      secondary: accent,
      onSecondary: isDark ? AppColors.onBrand : Colors.white,
      surface: surface,
      surfaceContainerLowest: card,
      error: AppColors.danger,
    );

    final text = GoogleFonts.cairoTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final radius = BorderRadius.circular(16);
    final outline = BorderSide(color: scheme.outlineVariant);

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.onBrand,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: accent),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: radius, borderSide: outline),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: outline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: accent, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: accent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: AppColors.brand.withValues(alpha: 0.4),
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: AppColors.brand.withValues(alpha: 0.4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

extension ThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Readable brand-green for text and icons on the current surface.
  Color get accent => isDark ? AppColors.brand : AppColors.brandDeep;
}

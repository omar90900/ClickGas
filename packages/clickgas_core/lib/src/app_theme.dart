import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ClickGas design tokens (docs/decisions/0013-design-system.md).
///
/// One brand green, #2CE881, for fills: buttons, switches, active states.
/// Text and icons use [brandDeep] on light surfaces (the bright green lacks
/// contrast there) and the brand green itself on dark surfaces.
class AppColors {
  static const brand = Color(0xFF2CE881);

  /// Brand-coloured text and icons on light surfaces (WCAG AA on white).
  static const brandDeep = Color(0xFF0A7A3D);

  /// Text and icons drawn on top of [brand].
  static const onBrand = Color(0xFF04301A);

  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Light theme.
  static const lightBackground = Color(0xFFF4F7F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardAlt = Color(0xFFECF1EE);
  static const lightOutline = Color(0xFFDFE6E2);
  static const lightText = Color(0xFF0E1511);
  static const lightTextMuted = Color(0xFF5D6B64);

  // Dark theme: a soft black, never pure black.
  static const darkBackground = Color(0xFF141517);
  static const darkCard = Color(0xFF1C1E21);
  static const darkCardAlt = Color(0xFF25282C);
  static const darkOutline = Color(0xFF30343A);
  static const darkText = Color(0xFFF3F5F4);
  static const darkTextMuted = Color(0xFFA0A8A4);
}

/// Corner radii used across the apps.
class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? AppColors.darkBackground : AppColors.lightBackground;
    final card = dark ? AppColors.darkCard : AppColors.lightCard;
    final cardAlt = dark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final outline = dark ? AppColors.darkOutline : AppColors.lightOutline;
    final textColor = dark ? AppColors.darkText : AppColors.lightText;
    final muted = dark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final accent = dark ? AppColors.brand : AppColors.brandDeep;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.brand,
      onPrimary: AppColors.onBrand,
      primaryContainer: dark ? const Color(0xFF0F3B25) : const Color(0xFFD3F9E3),
      onPrimaryContainer: dark ? const Color(0xFFB9F6D3) : AppColors.onBrand,
      secondary: accent,
      onSecondary: dark ? AppColors.onBrand : Colors.white,
      secondaryContainer: dark ? const Color(0xFF16432B) : const Color(0xFFDDF7E8),
      onSecondaryContainer: dark ? const Color(0xFFB9F6D3) : AppColors.onBrand,
      tertiary: AppColors.info,
      onTertiary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: background,
      onSurface: textColor,
      onSurfaceVariant: muted,
      surfaceContainerLowest: card,
      surfaceContainerLow: card,
      surfaceContainer: cardAlt,
      surfaceContainerHigh: cardAlt,
      surfaceContainerHighest: dark ? const Color(0xFF2D3035) : const Color(0xFFE4EAE6),
      outline: dark ? const Color(0xFF4A5057) : const Color(0xFFB9C3BE),
      outlineVariant: outline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? AppColors.lightCard : AppColors.darkCard,
      onInverseSurface: dark ? AppColors.lightText : AppColors.darkText,
      inversePrimary: AppColors.brandDeep,
    );

    final text = GoogleFonts.cairoTextTheme(ThemeData(brightness: brightness).textTheme)
        .apply(bodyColor: textColor, displayColor: textColor);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final fieldRadius = BorderRadius.circular(AppRadius.md);
    final selectedTint = AppColors.brand.withValues(alpha: dark ? 0.20 : 0.24);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: outline.withValues(alpha: dark ? 0.9 : 0.7)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.onBrand,
          disabledBackgroundColor: textColor.withValues(alpha: 0.10),
          disabledForegroundColor: textColor.withValues(alpha: 0.38),
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: buttonShape,
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: accent.withValues(alpha: 0.7), width: 1.2),
          shape: buttonShape,
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: textColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? cardAlt : card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: outline)),
        disabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide(color: accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        floatingLabelStyle: TextStyle(color: accent),
        prefixIconColor: muted,
        suffixIconColor: muted,
        hintStyle: TextStyle(color: muted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : (dark ? muted : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.brand : (dark ? cardAlt : outline),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : outline,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.brand : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.onBrand),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : muted,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? selectedTint : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? accent : textColor,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: outline)),
          textStyle: WidgetStatePropertyAll(text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardAlt,
        selectedColor: selectedTint,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        checkmarkColor: accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent, linearTrackColor: cardAlt),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: selectedTint,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? accent : muted),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? accent : muted,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: selectedTint,
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: text.labelLarge?.copyWith(color: accent, fontWeight: FontWeight.w800),
        unselectedLabelTextStyle: text.labelLarge?.copyWith(color: muted),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
        elevation: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? AppColors.darkCardAlt : AppColors.lightText,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        actionTextColor: AppColors.brand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCardAlt : AppColors.lightText,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.bodySmall?.copyWith(color: Colors.white),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
    );
  }
}

extension ThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Readable brand-green for text and icons on the current surface.
  Color get accent => isDark ? AppColors.brand : AppColors.brandDeep;

  /// Card / tile background.
  Color get card => colors.surfaceContainerLowest;

  /// Secondary text.
  Color get muted => colors.onSurfaceVariant;
}

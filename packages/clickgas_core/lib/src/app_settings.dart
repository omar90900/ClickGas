import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-device preferences: language and light/dark mode.
class AppSettings extends ChangeNotifier {
  static const _localeKey = 'locale';
  static const _themeKey = 'themeMode';
  static const supportedLocales = [Locale('ar'), Locale('en')];

  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  /// Null means "follow the device language" (falls back to Arabic).
  Locale? get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      _locale = code == null ? null : Locale(code);
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_themeKey),
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      // Preferences are a convenience; defaults are fine if they fail.
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  static Locale resolve(Locale? deviceLocale, Iterable<Locale> supported) {
    if (deviceLocale?.languageCode == 'en') return const Locale('en');
    return const Locale('ar');
  }
}

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/admin_repository.dart';
import 'features/auth/auth_gate.dart';
import 'l10n/gen/app_localizations.dart';
import 'state/staff_session.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.settings});

  final AppSettings settings;

  /// The shared theme, with desktop-sized buttons (the phone apps use
  /// full-width 54 px buttons, which don't fit in dashboard rows).
  static ThemeData _dashboard(ThemeData base) {
    const size = WidgetStatePropertyAll(Size(64, 44));
    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(minimumSize: size),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(minimumSize: size),
      ),
      appBarTheme: base.appBarTheme.copyWith(centerTitle: false),
      visualDensity: VisualDensity.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider(create: (_) => AuthRepository(client)),
        Provider(create: (_) => AdminRepository(client)),
        Provider(create: (_) => DriverDocumentsRepository(client)),
        Provider(create: (_) => DiagnosticsRepository(client)),
        ChangeNotifierProvider(
          lazy: false,
          create: (c) => StaffSession(
            c.read<AuthRepository>(),
            c.read<AdminRepository>(),
          ),
        ),
      ],
      child: Consumer<AppSettings>(
        builder: (context, s, _) => MaterialApp(
          onGenerateTitle: (c) => AppLocalizations.of(c).appName,
          debugShowCheckedModeBanner: false,
          theme: _dashboard(AppTheme.light()),
          darkTheme: _dashboard(AppTheme.dark()),
          themeMode: s.themeMode,
          locale: s.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: AppSettings.resolve,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/driver_repository.dart';
import 'data/tracking_service.dart';
import 'features/auth/auth_gate.dart';
import 'l10n/gen/app_localizations.dart';
import 'state/active_orders_controller.dart';
import 'state/driver_session.dart';

class DriverApp extends StatelessWidget {
  const DriverApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;
    // Everything lives above MaterialApp so pushed routes can reach it.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider(create: (_) => AuthRepository(client)),
        Provider(create: (_) => ProfileRepository(client)),
        Provider(create: (_) => CatalogRepository(client)),
        Provider(create: (_) => DriverRepository(client)),
        Provider(create: (_) => AvatarRepository(client)),
        Provider(create: (_) => DiagnosticsRepository(client)),
        Provider(create: (_) => DriverDocumentsRepository(client)),
        Provider(create: (_) => NotificationsRepository(client)),
        Provider(create: (_) => LocationService()),
        FutureProvider<AppConfig>(
          create: (c) => c.read<CatalogRepository>().config(),
          initialData: AppConfig.defaults,
          catchError: (_, _) => AppConfig.defaults,
        ),
        ChangeNotifierProvider(
          create: (c) => TrackingService(
            c.read<LocationService>(),
            c.read<DriverRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => ActiveOrdersController(c.read<DriverRepository>()),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (c) => DriverSession(
            c.read<AuthRepository>(),
            c.read<ProfileRepository>(),
            c.read<DriverRepository>(),
            c.read<ActiveOrdersController>(),
            settings,
            c.read<NotificationsRepository>(),
          ),
        ),
      ],
      child: Consumer<AppSettings>(
        builder: (context, s, _) => MaterialApp(
          onGenerateTitle: (c) => AppLocalizations.of(c).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
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

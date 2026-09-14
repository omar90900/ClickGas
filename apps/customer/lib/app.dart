import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'data/location_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/driver_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'features/auth/auth_gate.dart';
import 'l10n/gen/app_localizations.dart';
import 'state/my_orders_controller.dart';
import 'state/session_controller.dart';

class ClickGasApp extends StatelessWidget {
  const ClickGasApp({super.key, required this.settings});

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
        Provider(create: (_) => OrderRepository(client)),
        Provider(create: (_) => DriverRepository(client)),
        Provider(create: (_) => AvatarRepository(client)),
        Provider(create: (_) => DiagnosticsRepository(client)),
        Provider(create: (_) => NotificationsRepository(client)),
        Provider(create: (_) => WalletRepository(client)),
        Provider(create: (_) => LocationService()),
        FutureProvider<AppConfig>(
          create: (c) => c.read<CatalogRepository>().config(),
          initialData: AppConfig.defaults,
          catchError: (_, _) => AppConfig.defaults,
        ),
        ChangeNotifierProvider(
          create: (c) => MyOrdersController(c.read<OrderRepository>()),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (c) => SessionController(
            c.read<AuthRepository>(),
            c.read<ProfileRepository>(),
            c.read<MyOrdersController>(),
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

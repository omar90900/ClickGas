import 'dart:async';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() => runGuardedApp(
      app: 'distributor',
      start: () async {
        final settings = AppSettings();
        await (
          settings.load(),
          NotificationService.instance.init(),
          Supabase.initialize(
            url: SupabaseConfig.url,
            publishableKey: SupabaseConfig.publishableKey,
          ),
        ).wait;
        // Keeps the login token fresh while tracking runs in the background.
        SessionKeeper.install(Supabase.instance.client.auth);
        Log.i('supabase_ready', {'env': SupabaseConfig.environment});
        // Pushes when the app is closed; a no-op without google-services.json.
        // Not needed for the first screen: registering the phone waits for it.
        unawaited(PushService.instance.init(app: 'distributor'));

        return DriverApp(settings: settings);
      },
    );

import 'package:clickgas_core/clickgas_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() => runGuardedApp(
      app: 'admin',
      start: () async {
        final settings = AppSettings();
        await settings.load();

        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.publishableKey,
        );
        // Keeps the login token fresh while a hidden tab keeps polling.
        SessionKeeper.install(Supabase.instance.client.auth);
        Log.i('supabase_ready', {'env': SupabaseConfig.environment});

        return AdminApp(settings: settings);
      },
    );

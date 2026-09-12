import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/settings/app_settings.dart';

Future<void> main() => runGuardedApp(
      app: 'customer',
      start: () async {
        final settings = AppSettings();
        await settings.load();
        await NotificationService.instance.init();

        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.publishableKey,
        );
        SessionKeeper.install(Supabase.instance.client.auth);
        Log.i('supabase_ready', {'env': SupabaseConfig.environment});
        // Pushes when the app is closed; a no-op without google-services.json.
        await PushService.instance.init(app: 'customer');

        return ClickGasApp(settings: settings);
      },
    );

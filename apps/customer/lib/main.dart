import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Log.install(app: 'customer');

  final settings = AppSettings();
  await settings.load();
  await NotificationService.instance.init();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  Log.i('supabase_ready', {'env': SupabaseConfig.environment});

  runApp(ClickGasApp(settings: settings));
}

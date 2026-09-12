import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Log.install(app: 'distributor');

  final settings = AppSettings();
  await settings.load();
  await NotificationService.instance.init();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  Log.i('supabase_ready', {'env': SupabaseConfig.environment});

  runApp(DriverApp(settings: settings));
}

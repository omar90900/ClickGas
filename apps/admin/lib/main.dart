import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Log.install(app: 'admin');

  final settings = AppSettings();
  await settings.load();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  // Keeps the login token fresh while a hidden tab keeps polling.
  SessionKeeper.install(Supabase.instance.client.auth);
  Log.i('supabase_ready', {'env': SupabaseConfig.environment});

  runApp(AdminApp(settings: settings));
}

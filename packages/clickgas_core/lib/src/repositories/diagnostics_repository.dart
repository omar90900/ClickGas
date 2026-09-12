import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../logger.dart';
import '../supabase_config.dart';

/// "Send diagnostics": uploads the recent log with app and device context to
/// the `diagnostics` table, so support can see what happened on a phone.
/// See docs/runbooks/diagnostics.md.
class DiagnosticsRepository {
  DiagnosticsRepository(this._client);

  /// Set at build time with `--dart-define=APP_VERSION=1.2.0`.
  static const appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  final SupabaseClient _client;

  /// Returns the diagnostics id to quote to support.
  Future<int> send({String? note}) => guard('diagnostics.send', () async {
        final row = await _client
            .from('diagnostics')
            .insert({
              'app': Log.app,
              'app_version': appVersion,
              'environment': SupabaseConfig.environment,
              'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
              'locale': PlatformDispatcher.instance.locale.toLanguageTag(),
              'logs': Log.snapshot(),
              'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
            })
            .select('id')
            .single();
        final id = (row['id'] as num).toInt();
        Log.i('diagnostics_sent', {'id': id});
        return id;
      });
}

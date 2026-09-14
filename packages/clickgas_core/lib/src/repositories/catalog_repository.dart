import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../logger.dart';
import '../models.dart';

/// Reference data (cities, services, settings, fees). Cities are cached for
/// the session; a failed load is retried on the next call.
class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient _client;
  List<City>? _cities;
  List<GasService>? _services;

  Future<List<City>> cities() async {
    if (_cities != null) return _cities!;
    return guard('catalog.cities', () async {
      final rows = await _client
          .from('cities')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return _cities = rows.map(City.fromMap).toList();
    });
  }

  Future<List<GasService>> services({bool refresh = false}) async {
    if (_services != null && !refresh) return _services!;
    return guard('catalog.services', () async {
      final rows = await _client
          .from('services')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      return _services = rows.map(GasService.fromMap).toList();
    });
  }

  /// Settings with the service fees in force now merged in.
  ///
  /// Fees are optional here: if they can't be read (for example before the
  /// foundation migration is applied) ordering still works with zero fees -
  /// the database decides the real amount anyway - and a warning is logged.
  Future<AppConfig> config() => guard('catalog.config', () async {
        final configRow =
            await _client.from('app_config').select().maybeSingle();
        final config =
            configRow == null ? AppConfig.defaults : AppConfig.fromMap(configRow);
        Fees fees;
        try {
          final feesRow =
              await _client.from('current_fees').select().maybeSingle();
          fees = feesRow == null ? Fees.zero : Fees.fromMap(feesRow);
        } catch (e) {
          Log.w('fees_unavailable', {'error': e.toString()});
          fees = Fees.zero;
        }
        return config.withFees(fees);
      });

  /// The service fee pair in force now (customer 0.100, distributor 0.050).
  Future<Fees> currentFees() => guard('catalog.fees', () async {
        final row = await _client.from('current_fees').select().maybeSingle();
        return row == null ? Fees.zero : Fees.fromMap(row);
      });
}

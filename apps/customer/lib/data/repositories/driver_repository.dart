import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Driver data as seen by customers. RLS only returns online, verified
/// distributors plus the driver assigned to the customer's open order.
/// The driver app will add its own write methods (go online, location,
/// accept_order / start_delivery / complete_order RPCs).
class DriverRepository {
  DriverRepository(this._client);

  final SupabaseClient _client;

  Stream<List<DriverLocation>> watchOnlineDrivers() => _client
      .from('drivers')
      .stream(primaryKey: ['id'])
      .eq('is_online', true)
      .map((rows) => rows
          .map(DriverLocation.fromMap)
          .whereType<DriverLocation>()
          .toList());

  Stream<DriverLocation?> watchDriver(String driverId) => _client
      .from('drivers')
      .stream(primaryKey: ['id'])
      .eq('id', driverId)
      .map((rows) => rows.isEmpty ? null : DriverLocation.fromMap(rows.first));
}

import 'package:clickgas_core/clickgas_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Distributor side: own profile and location, dispatch RPCs, sales and
/// charges. Throws only [AppFailure]; dispatch refusals arrive as codes such
/// as [FailureCode.maxActiveOrders] (docs/errors.md).
class DriverRepository {
  DriverRepository(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------- own profile

  Future<DriverProfile?> fetchMe(String driverId) =>
      guard('driver.fetch_me', () async {
        final row = await _client
            .from('drivers')
            .select()
            .eq('id', driverId)
            .maybeSingle();
        return row == null ? null : DriverProfile.fromMap(row);
      });

  /// Only columns the database lets drivers change (see column grants).
  Future<DriverProfile> update(String driverId, Map<String, Object?> fields) =>
      guard('driver.update', () async {
        final row = await _client
            .from('drivers')
            .update(fields)
            .eq('id', driverId)
            .select()
            .single();
        return DriverProfile.fromMap(row);
      }, context: {'fields': fields.keys.join(',')});

  Future<void> setOnline(String driverId, bool online) => guard(
        'driver.set_online',
        () async {
          await _client
              .from('drivers')
              .update({'is_online': online}).eq('id', driverId);
          Log.i(online ? 'went_online' : 'went_offline');
        },
      );

  /// [online] re-confirms is_online with the position: the server switches
  /// off distributors silent for 15 minutes (expire_stale_orders), and this
  /// switches an active one straight back on after a gap in signal.
  Future<void> updateLocation(
    String driverId,
    double lat,
    double lng,
    double? heading, {
    bool online = false,
  }) =>
      guard('driver.update_location', () async {
        await _client.from('drivers').update({
          'lat': lat,
          'lng': lng,
          'heading': heading,
          'location_updated_at': DateTime.now().toUtc().toIso8601String(),
          if (online) 'is_online': true,
        }).eq('id', driverId);
      });

  // ---------------------------------------------------------- dispatch

  Future<List<NearbyOrder>> nearby(double lat, double lng) =>
      guard('dispatch.nearby', () async {
        final rows = await _client.rpc(
          'nearby_orders',
          params: {'p_lat': lat, 'p_lng': lng},
        );
        return (rows as List)
            .map((r) => NearbyOrder.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList();
      });

  Future<List<DriverOrder>> active() => guard('dispatch.active', () async {
        final rows = await _client.rpc('driver_active_orders');
        return (rows as List)
            .map((r) => DriverOrder.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList();
      });

  /// Live rows of this driver's orders (e.g. the customer confirms receipt);
  /// used to refresh [active] and to detect confirmations.
  Stream<List<GasOrder>> watchMyOrders(String driverId) => _client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('driver_id', driverId)
      .map((rows) => rows.map(GasOrder.fromMap).toList());

  Future<void> accept(String orderId) => guard(
        'dispatch.accept',
        () async {
          await _client.rpc('accept_order', params: {'p_order_id': orderId});
          Log.i('order_accepted', {'order_id': orderId});
        },
        context: {'order_id': orderId},
      );

  Future<void> startDelivery(String orderId) => guard(
        'dispatch.start_delivery',
        () => _client.rpc('start_delivery', params: {'p_order_id': orderId}),
        context: {'order_id': orderId},
      );

  Future<void> complete(String orderId) => guard(
        'dispatch.complete',
        () async {
          await _client.rpc('complete_order', params: {'p_order_id': orderId});
          Log.i('order_delivered', {'order_id': orderId});
        },
        context: {'order_id': orderId},
      );

  Future<void> release(String orderId) => guard(
        'dispatch.release',
        () async {
          await _client.rpc('release_order', params: {'p_order_id': orderId});
          Log.i('order_released', {'order_id': orderId});
        },
        context: {'order_id': orderId},
      );

  // ---------------------------------------------------------- sales & fees

  Future<List<GasOrder>> deliveredSince(String driverId, DateTime from) =>
      guard('sales.delivered', () async {
        final rows = await _client
            .from('orders')
            .select()
            .eq('driver_id', driverId)
            .eq('status', OrderStatus.delivered.value)
            .gte('delivered_at', from.toUtc().toIso8601String())
            .order('delivered_at', ascending: false)
            .limit(500);
        return rows.map(GasOrder.fromMap).toList();
      });

  Future<List<OrderRelease>> releasesSince(String driverId, DateTime from) =>
      guard('sales.releases', () async {
        final rows = await _client
            .from('order_releases')
            .select()
            .eq('driver_id', driverId)
            .gte('created_at', from.toUtc().toIso8601String())
            .order('created_at', ascending: false)
            .limit(200);
        return rows.map(OrderRelease.fromMap).toList();
      });

  /// Fines or item fees staff raised against this distributor, newest first
  /// (docs/business-rules.md#charges).
  Future<List<DriverCharge>> charges(String driverId) =>
      guard('sales.charges', () async {
        final rows = await _client
            .from('driver_charges')
            .select('*, orders(order_number)')
            .eq('driver_id', driverId)
            .order('created_at', ascending: false)
            .limit(50);
        return rows.map((r) {
          final order = r['orders'];
          return DriverCharge.fromMap({
            ...r,
            if (order is Map) 'order_number': order['order_number'],
          });
        }).toList();
      });
}

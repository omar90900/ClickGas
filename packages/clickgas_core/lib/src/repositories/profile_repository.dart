import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../models.dart';

class OrderCounts {
  const OrderCounts({this.total = 0, this.delivered = 0});
  final int total;
  final int delivered;
}

/// What the customer received and paid (`my_order_stats`). Money excludes the
/// delivery fee: these totals answer "what did the gas cost me".
class CustomerOrderStats {
  const CustomerOrderStats({
    this.monthCylinders = 0,
    this.monthPaid = 0,
    this.yearCylinders = 0,
    this.yearPaid = 0,
    this.totalOrders = 0,
    this.totalCylinders = 0,
    this.totalPaid = 0,
  });

  final int monthCylinders;
  final double monthPaid;
  final int yearCylinders;
  final double yearPaid;
  final int totalOrders;
  final int totalCylinders;
  final double totalPaid;

  factory CustomerOrderStats.fromMap(Map<String, dynamic> m) =>
      CustomerOrderStats(
        monthCylinders: _int(m['month_cylinders']),
        monthPaid: _double(m['month_paid']),
        yearCylinders: _int(m['year_cylinders']),
        yearPaid: _double(m['year_paid']),
        totalOrders: _int(m['total_orders']),
        totalCylinders: _int(m['total_cylinders']),
        totalPaid: _double(m['total_paid']),
      );
}

/// What the distributor delivered and took in (`driver_earnings_stats`).
class DriverEarnings {
  const DriverEarnings({
    this.monthDeliveries = 0,
    this.monthCylinders = 0,
    this.monthEarned = 0,
    this.yearDeliveries = 0,
    this.yearCylinders = 0,
    this.yearEarned = 0,
  });

  final int monthDeliveries;
  final int monthCylinders;
  final double monthEarned;
  final int yearDeliveries;
  final int yearCylinders;
  final double yearEarned;

  factory DriverEarnings.fromMap(Map<String, dynamic> m) => DriverEarnings(
        monthDeliveries: _int(m['month_deliveries']),
        monthCylinders: _int(m['month_cylinders']),
        monthEarned: _double(m['month_earned']),
        yearDeliveries: _int(m['year_deliveries']),
        yearCylinders: _int(m['year_cylinders']),
        yearEarned: _double(m['year_earned']),
      );
}

int _int(Object? v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
double _double(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

/// The signed-in user's `profiles` row. Throws only [AppFailure]; a phone
/// already used by another account surfaces as [FailureCode.phoneTaken].
class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile?> fetch(String userId) => guard('profile.fetch', () async {
        final row = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        return row == null ? null : Profile.fromMap(row);
      });

  /// Orders placed (customer) or taken (distributor), for the profile header.
  /// RLS already limits the rows to the user's own orders.
  Future<OrderCounts> orderCounts(String userId, {bool asDriver = false}) =>
      guard('profile.order_counts', () async {
        final rows = await _client
            .from('orders')
            .select('status')
            .eq(asDriver ? 'driver_id' : 'customer_id', userId);
        return OrderCounts(
          total: rows.length,
          delivered: rows.where((r) => r['status'] == 'delivered').length,
        );
      });

  /// Delivered-order totals for the signed-in customer, for the Profile
  /// screen and My Orders stats header.
  Future<CustomerOrderStats> myOrderStats() =>
      guard('profile.my_order_stats', () async {
        final rows = await _client.rpc('my_order_stats') as List;
        return CustomerOrderStats.fromMap(
          Map<String, dynamic>.from(rows.first as Map),
        );
      });

  /// Delivered-order totals for the signed-in distributor, for the
  /// Settings/Edit Profile earnings summary.
  Future<DriverEarnings> driverEarningsStats() =>
      guard('profile.driver_earnings_stats', () async {
        final rows = await _client.rpc('driver_earnings_stats') as List;
        return DriverEarnings.fromMap(
          Map<String, dynamic>.from(rows.first as Map),
        );
      });

  /// Only the columns the database lets users change (see column grants).
  Future<Profile> update(
    String userId, {
    required String fullName,
    required String phone,
    required int? cityId,
  }) =>
      guard('profile.update', () async {
        final row = await _client
            .from('profiles')
            .update({
              'full_name': fullName.trim(),
              'phone': phone,
              'city_id': cityId,
            })
            .eq('id', userId)
            .select()
            .single();
        return Profile.fromMap(row);
      });
}

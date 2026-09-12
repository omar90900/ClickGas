import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Customer side of the order lifecycle. Prices, fees and status changes are
/// enforced by the database (trigger + RPC functions), not by the app.
/// Throws only [AppFailure]; a second open order is
/// [FailureCode.openOrderExists].
class OrderRepository {
  OrderRepository(this._client);

  final SupabaseClient _client;

  Future<GasOrder> create({
    required String customerId,
    required int serviceId,
    required int quantity,
    required PaymentMethod paymentMethod,
    required double lat,
    required double lng,
    String? address,
    String? notes,
  }) =>
      guard('orders.create', () async {
        final row = await _client
            .from('orders')
            .insert({
              'customer_id': customerId,
              'service_id': serviceId,
              'quantity': quantity,
              'payment_method': paymentMethod.name,
              'delivery_lat': lat,
              'delivery_lng': lng,
              'delivery_address': address,
              'notes':
                  (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
            })
            .select()
            .single();
        final order = GasOrder.fromMap(row);
        Log.i('order_created', {
          'order': order.orderNumber,
          'total': order.totalPrice,
          'quantity': order.quantity,
        });
        return order;
      });

  /// Distributors online near a spot. The server also records a coverage
  /// gap when there are none (docs/business-rules.md#coverage).
  Future<Coverage> coverage(double lat, double lng) =>
      guard('orders.coverage', () async {
        final value = await _client.rpc(
          'coverage_check',
          params: {'p_lat': lat, 'p_lng': lng},
        );
        return Coverage.fromMap(Map<String, dynamic>.from(value as Map));
      });

  /// Live list of the customer's orders, newest first (Supabase Realtime).
  Stream<List<GasOrder>> watchCustomerOrders(String customerId) => _client
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerId)
      .order('created_at')
      .limit(50)
      .map((rows) => rows.map(GasOrder.fromMap).toList());

  Future<void> cancel(String orderId) => guard(
        'orders.cancel',
        () => _client.rpc('cancel_order', params: {'p_order_id': orderId}),
        context: {'order_id': orderId},
      );

  Future<void> rate(String orderId, int rating, String? comment) => guard(
        'orders.rate',
        () => _client.rpc('rate_order', params: {
          'p_order_id': orderId,
          'p_rating': rating,
          'p_comment': (comment == null || comment.trim().isEmpty)
              ? null
              : comment.trim(),
        }),
        context: {'order_id': orderId},
      );

  /// Customer confirms receipt after the driver marked the order delivered.
  Future<void> confirmDelivery(String orderId) => guard(
        'orders.confirm_delivery',
        () => _client.rpc('confirm_delivery', params: {'p_order_id': orderId}),
        context: {'order_id': orderId},
      );

  Future<OrderDriver?> fetchDriver(String orderId) =>
      guard('orders.fetch_driver', () async {
        final rows = await _client.rpc(
          'get_order_driver',
          params: {'p_order_id': orderId},
        );
        if (rows is List && rows.isNotEmpty) {
          return OrderDriver.fromMap(
            Map<String, dynamic>.from(rows.first as Map),
          );
        }
        return null;
      }, context: {'order_id': orderId});
}

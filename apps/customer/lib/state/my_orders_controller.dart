import 'dart:async';
import 'dart:math' as math;

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/order_repository.dart';

/// One realtime subscription to the signed-in customer's orders, shared by
/// the Home (open-order banner), Tracking and My Orders tabs.
///
/// If the stream fails (lost connection, expired token), it reconnects by
/// itself after 2, 4, 8... up to 30 seconds, refreshing the session first.
class MyOrdersController extends ChangeNotifier {
  MyOrdersController(this._repo);

  final OrderRepository _repo;
  StreamSubscription<List<GasOrder>>? _sub;
  Timer? _retry;
  int _failures = 0;
  String? _customerId;

  List<GasOrder> _orders = const [];
  bool _loading = false;
  Object? _error;

  List<GasOrder> get orders => _orders;
  bool get loading => _loading;
  Object? get error => _error;
  String? get customerId => _customerId;

  GasOrder? get openOrder =>
      _orders.where((o) => o.status.isOpen).firstOrNull;

  /// Delivered by the driver, waiting for the customer to confirm receipt.
  GasOrder? get awaitingConfirmation =>
      _orders.where((o) => o.needsConfirmation).firstOrNull;

  GasOrder? byId(String id) => _orders.where((o) => o.id == id).firstOrNull;

  /// The latest order, if nobody accepted it in time within the last 2 hours
  /// (Home offers "Order again").
  GasOrder? get recentlyExpired {
    final latest = _orders.fold<GasOrder?>(null, (a, o) {
      if (a == null) return o;
      return (o.createdAt ?? DateTime(0)).isAfter(a.createdAt ?? DateTime(0)) ? o : a;
    });
    if (latest == null || latest.status != OrderStatus.expired) return null;
    final at = latest.createdAt;
    if (at == null || DateTime.now().difference(at) > const Duration(hours: 2)) return null;
    return latest;
  }

  void bind(String? customerId) {
    if (customerId == _customerId) return;
    _customerId = customerId;
    _orders = const [];
    _error = null;
    _failures = 0;
    _loading = customerId != null;
    _subscribe();
    notifyListeners();
  }

  void _subscribe() {
    _retry?.cancel();
    _sub?.cancel();
    _sub = null;
    final id = _customerId;
    if (id == null) return;
    _sub = _repo.watchCustomerOrders(id).listen(
      (orders) {
        _orders = orders;
        _loading = false;
        _error = null;
        _failures = 0;
        notifyListeners();
      },
      onError: (Object e) {
        Log.w('orders_stream_error', {'error': e.toString()});
        _error = e;
        _loading = false;
        notifyListeners();
        _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    _retry?.cancel();
    final delay = Duration(seconds: math.min(30, 2 << math.min(_failures, 4)));
    _failures++;
    _retry = Timer(delay, () async {
      await SessionKeeper.instance?.ensureFresh();
      _subscribe();
    });
  }

  void retry() {
    _failures = 0;
    _subscribe();
  }

  @override
  void dispose() {
    _retry?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

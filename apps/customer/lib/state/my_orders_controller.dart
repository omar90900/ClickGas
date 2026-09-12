import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/models.dart';
import '../data/repositories/order_repository.dart';

/// One realtime subscription to the signed-in customer's orders, shared by
/// the Home (open-order banner), Tracking and My Orders tabs.
class MyOrdersController extends ChangeNotifier {
  MyOrdersController(this._repo);

  final OrderRepository _repo;
  StreamSubscription<List<GasOrder>>? _sub;
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

  void bind(String? customerId) {
    if (customerId == _customerId) return;
    _customerId = customerId;
    _sub?.cancel();
    _sub = null;
    _orders = const [];
    _error = null;
    _loading = customerId != null;
    if (customerId != null) {
      _sub = _repo.watchCustomerOrders(customerId).listen(
        (orders) {
          _orders = orders;
          _loading = false;
          _error = null;
          notifyListeners();
        },
        onError: (Object e) {
          debugPrint('Orders stream error: $e');
          _error = e;
          _loading = false;
          notifyListeners();
        },
      );
    }
    notifyListeners();
  }

  void retry() {
    final id = _customerId;
    _customerId = null;
    bind(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

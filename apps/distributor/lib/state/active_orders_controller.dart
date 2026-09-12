import 'dart:async';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/foundation.dart';

import '../data/driver_repository.dart';

/// The driver's accepted / in-progress orders, shared by the Home map and
/// the Orders tab. Refreshed by realtime changes on the driver's orders and
/// after every action. A delivered order leaves this list immediately, so
/// the slot is free even before the customer confirms receipt.
class ActiveOrdersController extends ChangeNotifier {
  ActiveOrdersController(this._repo);

  final DriverRepository _repo;
  StreamSubscription<List<GasOrder>>? _sub;
  String? _driverId;
  List<DriverOrder> _orders = const [];
  bool _loading = false;
  Set<String>? _confirmedIds;

  /// Called when a customer confirms receipt of one of this driver's orders.
  void Function(GasOrder order)? onCustomerConfirmed;

  List<DriverOrder> get orders => _orders;
  bool get loading => _loading;
  int get count => _orders.length;

  void bind(String? driverId) {
    if (driverId == _driverId) return;
    _driverId = driverId;
    _sub?.cancel();
    _sub = null;
    _orders = const [];
    _confirmedIds = null;
    if (driverId != null) {
      _sub = _repo.watchMyOrders(driverId).listen(
            _onRows,
            onError: (Object e) => debugPrint('Driver orders stream: $e'),
          );
      refresh();
    }
    notifyListeners();
  }

  void _onRows(List<GasOrder> rows) {
    final confirmed = {
      for (final o in rows)
        if (o.customerConfirmedAt != null) o.id,
    };
    final before = _confirmedIds;
    _confirmedIds = confirmed;
    if (before != null) {
      for (final o in rows) {
        if (confirmed.contains(o.id) && !before.contains(o.id)) {
          onCustomerConfirmed?.call(o);
        }
      }
    }
    refresh();
  }

  Future<void> refresh() async {
    if (_driverId == null) return;
    _loading = true;
    notifyListeners();
    try {
      _orders = await _repo.active();
    } catch (e) {
      debugPrint('Active orders refresh failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'dart:math' as math;

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
    _orders = const [];
    _confirmedIds = null;
    _failures = 0;
    _subscribe();
    if (driverId != null) refresh();
    notifyListeners();
  }

  Timer? _retry;
  int _failures = 0;

  /// Reconnects by itself after a stream error (lost connection, expired
  /// token): 2, 4, 8... up to 30 seconds, refreshing the session first.
  void _subscribe() {
    _retry?.cancel();
    _sub?.cancel();
    _sub = null;
    final id = _driverId;
    if (id == null) return;
    _sub = _repo.watchMyOrders(id).listen(
      (rows) {
        _failures = 0;
        _onRows(rows);
      },
      onError: (Object e) {
        Log.w('driver_orders_stream_error', {'error': e.toString()});
        _retry?.cancel();
        final delay = Duration(seconds: math.min(30, 2 << math.min(_failures, 4)));
        _failures++;
        _retry = Timer(delay, () async {
          await SessionKeeper.instance?.ensureFresh();
          _subscribe();
          await refresh();
        });
      },
    );
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
    _retry?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

import 'package:clickgas_admin/data/admin_models.dart';
import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaffRole', () {
    test('unknown roles fall back to the least powerful one', () {
      expect(StaffRole.parse('owner'), StaffRole.owner);
      expect(StaffRole.parse('nonsense'), StaffRole.support);
      expect(StaffRole.support.canOperate, isFalse);
      expect(StaffRole.operations.canOperate, isTrue);
      expect(StaffRole.operations.isOwner, isFalse);
    });
  });

  group('Overview', () {
    test('parses numbers sent as strings or numbers', () {
      final o = Overview.fromMap({
        'orders_today': 12,
        'fees_today': '1.350',
        'median_accept_seconds': 95.5,
        'pending_over_10m': 2,
        'last_14_days': [
          {'day': '2026-09-11', 'orders': 3, 'delivered': 2, 'fees': 0.3},
        ],
      });
      expect(o.ordersToday, 12);
      expect(o.feesToday, 1.35);
      expect(o.medianAcceptSeconds, 95.5);
      expect(o.days.single.delivered, 2);
      expect(o.days.single.day, DateTime(2026, 9, 11));
    });

    test('a missing median stays null', () {
      expect(Overview.fromMap({}).medianAcceptSeconds, isNull);
    });
  });

  group('live map', () {
    test('pending orders change colour band with waiting time', () {
      expect(WaitBand.of(const Duration(minutes: 4)), WaitBand.fresh);
      expect(WaitBand.of(const Duration(minutes: 5)), WaitBand.slow);
      expect(WaitBand.of(const Duration(minutes: 15)), WaitBand.late);
    });

    test('a distributor silent for over 2 minutes is stale', () {
      final now = DateTime(2026, 9, 12, 12);
      final d = LiveDriver(
        id: 'd1',
        fullName: 'D',
        phone: '+962790000001',
        lat: 31.9,
        lng: 35.9,
        locationUpdatedAt: now.subtract(const Duration(minutes: 3)),
      );
      expect(d.isStale(now), isTrue);
      expect(d.isStale(now.subtract(const Duration(minutes: 2))), isFalse);
    });
  });

  group('fees', () {
    test('the latest fee row that has started is in force', () {
      final now = DateTime(2026, 9, 12, 12);
      final all = [
        FeeSetting(id: 1, customerFee: 0.1, driverFee: 0.05, effectiveFrom: DateTime(2026, 9, 1)),
        FeeSetting(id: 2, customerFee: 0.2, driverFee: 0.1, effectiveFrom: DateTime(2026, 10, 1)),
      ];
      expect(feesInForce(all, now)!.id, 1);
      expect(all[1].isScheduled(now), isTrue);
      expect(feesInForce(all, DateTime(2026, 10, 2))!.id, 2);
    });
  });

  group('orders', () {
    test('the inspector keeps the fee snapshot and cancel reason', () {
      final d = OrderDetail.fromMap({
        'order': {
          'id': 'o1',
          'order_number': 1042,
          'customer_id': 'c1',
          'service_id': 1,
          'quantity': 2,
          'unit_price': 7,
          'delivery_fee': 0,
          'service_fee': 0.1,
          'driver_fee': 0.05,
          'total_price': 14.1,
          'payment_method': 'cash',
          'status': 'cancelled',
          'delivery_lat': 31.95,
          'delivery_lng': 35.91,
          'cancel_reason': 'customer called',
        },
        'customer': {'id': 'c1', 'full_name': 'C', 'phone': '+962790000001'},
        'driver': null,
        'events': [
          {'status': 'pending', 'at': '2026-09-12T09:00:00Z', 'actor_role': 'customer'},
          {'status': 'cancelled', 'at': '2026-09-12T09:05:00Z', 'actor_role': 'admin'},
        ],
      });
      expect(d.order.driverFee, 0.05);
      expect(d.cancelReason, 'customer called');
      expect(d.driver, isNull);
      expect(d.events.last.actorRole, UserRole.admin);
      expect(d.events.last.status, OrderStatus.cancelled);
    });

    test('query params leave out empty filters', () {
      const q = OrderQuery(search: '  ');
      final p = q.toParams();
      expect(p['p_search'], isNull);
      expect(p['p_statuses'], isNull);
      final withStatus = q.copyWith(statuses: {OrderStatus.pending}, offset: 50);
      expect(withStatus.toParams()['p_statuses'], ['pending']);
      expect(withStatus.offset, 50);
      expect(withStatus.copyWith(search: 'x').offset, 0, reason: 'a new filter starts at page 1');
    });

    test('customers who cancel half their orders are flagged', () {
      const c = AdminCustomer(id: 'c', fullName: 'C', phone: '', ordersTotal: 4, cancelled: 2);
      const ok = AdminCustomer(id: 'c', fullName: 'C', phone: '', ordersTotal: 3, cancelled: 3);
      expect(c.oftenCancels, isTrue);
      expect(ok.oftenCancels, isFalse, reason: 'too few orders to judge');
    });
  });

  test('distanceKm matches a known distance (Amman to Zarqa ~ 20 km)', () {
    final km = distanceKm(31.9539, 35.9106, 32.0728, 36.0880);
    expect(km, closeTo(21, 2));
  });
}

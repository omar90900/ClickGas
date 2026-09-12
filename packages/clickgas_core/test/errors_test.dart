import 'dart:io';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppFailure.from', () {
    test('maps database error codes raised by RPCs', () {
      final f = AppFailure.from(const PostgrestException(
        message: 'MAX_ACTIVE_ORDERS',
        code: 'P0001',
        details: 'driver has 3 open orders',
      ));
      expect(f.code, FailureCode.maxActiveOrders);
      expect(f.detail, 'driver has 3 open orders');
    });

    test('maps the one-open-order unique index', () {
      final f = AppFailure.from(const PostgrestException(
        message:
            'duplicate key value violates unique constraint "orders_one_open_per_customer"',
        code: '23505',
      ));
      expect(f.code, FailureCode.openOrderExists);
    });

    test('maps a duplicate phone number', () {
      final f = AppFailure.from(const PostgrestException(
        message: 'duplicate key value violates unique constraint "profiles_phone_key"',
        code: '23505',
      ));
      expect(f.code, FailureCode.phoneTaken);
    });

    test('maps permission errors and auth errors', () {
      expect(
        AppFailure.from(const PostgrestException(message: 'denied', code: '42501'))
            .code,
        FailureCode.permissionDenied,
      );
      expect(
        AppFailure.from(const AuthException('bad', code: 'invalid_credentials'))
            .code,
        FailureCode.invalidCredentials,
      );
    });

    test('network problems become NETWORK', () {
      expect(
        AppFailure.from(const SocketException('offline')).code,
        FailureCode.network,
      );
    });

    test('unknown errors keep their text for the log', () {
      final f = AppFailure.from(StateError('boom'));
      expect(f.code, FailureCode.unknown);
      expect(f.detail, contains('boom'));
    });

    test('an AppFailure passes through unchanged', () {
      const original = AppFailure(FailureCode.orderTooFar, detail: 'x');
      expect(identical(AppFailure.from(original), original), isTrue);
    });
  });

  group('guard', () {
    test('converts, logs and rethrows as AppFailure', () async {
      Log.clear();
      await expectLater(
        guard('test.op', () async => throw const PostgrestException(
              message: 'ORDER_TOO_FAR',
              code: 'P0001',
            )),
        throwsA(isA<AppFailure>()
            .having((f) => f.code, 'code', FailureCode.orderTooFar)),
      );
      final last = Log.snapshot().last;
      expect(last['event'], 'failure');
      expect((last['data'] as Map)['op'], 'test.op');
      expect((last['data'] as Map)['code'], 'ORDER_TOO_FAR');
    });
  });

  group('Log', () {
    test('keeps only the most recent entries', () {
      Log.clear();
      for (var i = 0; i < Log.capacity + 25; i++) {
        Log.d('tick', {'i': i});
      }
      final entries = Log.snapshot();
      expect(entries, hasLength(Log.capacity));
      expect((entries.first['data'] as Map)['i'], 25);
    });
  });

  group('fees and money', () {
    test('AppConfig carries the fees in force', () {
      final config = AppConfig.fromMap({'delivery_fee': '0.000'}).withFees(
        Fees.fromMap({'customer_fee': '0.100', 'driver_fee': '0.050'}),
      );
      expect(config.fees.customerFee, 0.1);
      expect(config.fees.total, closeTo(0.15, 1e-9));
      expect(config.customerExtras, closeTo(0.1, 1e-9));
    });

    test('orders read their fee snapshot', () {
      final o = GasOrder.fromMap({
        'id': 'o1',
        'order_number': 1042,
        'customer_id': 'c1',
        'service_id': 1,
        'quantity': 2,
        'unit_price': '7.000',
        'delivery_fee': '0.000',
        'service_fee': '0.100',
        'driver_fee': '0.050',
        'total_price': '14.100',
        'payment_method': 'cash',
        'status': 'expired',
        'delivery_lat': 31.95,
        'delivery_lng': 35.91,
      });
      expect(o.totalPrice, 14.1);
      expect(o.serviceFee, 0.1);
      expect(o.driverFee, 0.05);
      expect(o.status, OrderStatus.expired);
      expect(o.status.isOpen, isFalse);
      expect(o.status.isClosedWithoutDelivery, isTrue);
    });
  });
}

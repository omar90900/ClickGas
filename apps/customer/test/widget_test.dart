import 'package:clickgas/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JordanPhone', () {
    test('normalises common local formats to E.164', () {
      expect(JordanPhone.normalize('0791234567'), '+962791234567');
      expect(JordanPhone.normalize('079 123 4567'), '+962791234567');
      expect(JordanPhone.normalize('791234567'), '+962791234567');
      expect(JordanPhone.normalize('+962 78 123 4567'), '+962781234567');
      expect(JordanPhone.normalize('00962771234567'), '+962771234567');
    });

    test('accepts Arabic-Indic digits', () {
      expect(JordanPhone.normalize('٠٧٩١٢٣٤٥٦٧'), '+962791234567');
    });

    test('rejects non-mobile or malformed numbers', () {
      expect(JordanPhone.normalize('0761234567'), isNull); // not 77/78/79
      expect(JordanPhone.normalize('06 123 4567'), isNull); // landline
      expect(JordanPhone.normalize('079123'), isNull);
      expect(JordanPhone.normalize(''), isNull);
    });

    test('displays E.164 as a local number', () {
      expect(JordanPhone.display('+962791234567'), '079 123 4567');
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.isEmail('user@example.com'), isTrue);
      expect(Validators.isEmail(' user@mail.jo '), isTrue);
      expect(Validators.isEmail('user@'), isFalse);
      expect(Validators.isEmail('no-at-sign.com'), isFalse);
    });
  });

  group('Models from Supabase rows', () {
    test('GasOrder parses numeric strings, enums and timestamps', () {
      final order = GasOrder.fromMap({
        'id': 'a1b2',
        'order_number': 1001,
        'customer_id': 'c1',
        'driver_id': null,
        'service_id': 1,
        'service_code': 'exchange',
        'service_name_ar': 'استبدال جرة غاز',
        'service_name_en': 'Cylinder exchange',
        'quantity': 2,
        'unit_price': '7.00',
        'delivery_fee': 0,
        'total_price': 14,
        'payment_method': 'cash',
        'status': 'on_the_way',
        'delivery_lat': 31.95,
        'delivery_lng': 35.91,
        'created_at': '2026-09-11T08:00:00+00:00',
      });
      expect(order.unitPrice, 7.0);
      expect(order.totalPrice, 14.0);
      expect(order.status, OrderStatus.onTheWay);
      expect(order.status.isOpen, isTrue);
      expect(order.status.hasDriver, isTrue);
      expect(order.serviceName('ar'), 'استبدال جرة غاز');
      expect(order.serviceName('en'), 'Cylinder exchange');
      expect(order.createdAt, isNotNull);
    });

    test('unknown enum values fall back safely', () {
      expect(OrderStatus.parse('weird'), OrderStatus.pending);
      expect(PaymentMethod.parse(null), PaymentMethod.cash);
      expect(UserRole.parse('driver'), UserRole.driver);
    });

    test('DriverLocation requires coordinates', () {
      expect(DriverLocation.fromMap({'id': 'd1', 'lat': null, 'lng': 35.9}),
          isNull);
      expect(
        DriverLocation.fromMap({'id': 'd1', 'lat': 31.9, 'lng': 35.9})?.lat,
        31.9,
      );
    });

    test('Profile first name', () {
      final p = Profile.fromMap({
        'id': 'u1',
        'role': 'customer',
        'full_name': 'عمر السالم',
        'phone': '+962791234567',
      });
      expect(p.firstName, 'عمر');
      expect(p.role, UserRole.customer);
    });
  });
}

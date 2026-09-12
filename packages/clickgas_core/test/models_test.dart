import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppConfig reads driver dispatch settings with safe defaults', () {
    final c = AppConfig.fromMap({
      'delivery_fee': '0.50',
      'max_quantity': 5,
      'search_radius_km': 5,
      'driver_radius_km': 2.5,
      'max_active_orders': 3,
    });
    expect(c.deliveryFee, 0.5);
    expect(c.driverRadiusKm, 2.5);
    expect(c.maxActiveOrders, 3);

    final old = AppConfig.fromMap({'delivery_fee': 0, 'max_quantity': 5});
    expect(old.driverRadiusKm, 2);
    expect(old.maxActiveOrders, 3);
  });

  test('GasOrder needs confirmation only when delivered and unconfirmed', () {
    Map<String, dynamic> row(String status, String? confirmed) => {
          'id': 'o1',
          'order_number': 1002,
          'customer_id': 'c1',
          'service_id': 1,
          'quantity': 1,
          'unit_price': 7,
          'delivery_fee': 0,
          'total_price': 7,
          'payment_method': 'cash',
          'status': status,
          'delivery_lat': 31.9,
          'delivery_lng': 35.9,
          'customer_confirmed_at': confirmed,
        };
    expect(GasOrder.fromMap(row('delivered', null)).needsConfirmation, isTrue);
    expect(
      GasOrder.fromMap(row('delivered', '2026-09-11T10:00:00Z')).needsConfirmation,
      isFalse,
    );
    expect(GasOrder.fromMap(row('on_the_way', null)).needsConfirmation, isFalse);
  });

  test('NearbyOrder and DriverOrder parse RPC rows', () {
    final n = NearbyOrder.fromMap({
      'id': 'o1',
      'order_number': 1003,
      'customer_name': 'أحمد',
      'service_name_ar': 'استبدال جرة غاز',
      'service_name_en': 'Cylinder exchange',
      'quantity': 2,
      'total_price': '14.00',
      'payment_method': 'cash',
      'delivery_lat': 31.95,
      'delivery_lng': 35.91,
      'distance_m': 850.4,
    });
    expect(n.distanceM, closeTo(850.4, 0.01));
    expect(n.totalPrice, 14);
    expect(n.serviceName('en'), 'Cylinder exchange');

    final d = DriverOrder.fromMap({
      'id': 'o2',
      'order_number': 1004,
      'status': 'delivered',
      'customer_name': 'سارة',
      'customer_phone': '+962791234567',
      'service_name_ar': 'شراء جرة جديدة',
      'service_name_en': 'New cylinder',
      'quantity': 1,
      'total_price': 40,
      'payment_method': 'cash',
      'delivery_lat': 31.9,
      'delivery_lng': 35.9,
    });
    expect(d.awaitingConfirmation, isTrue);
    expect(d.customerPhone, '+962791234567');
  });

  test('DriverProfile rating average and vehicle type', () {
    final p = DriverProfile.fromMap({
      'id': 'd1',
      'vehicle_plate': '12-34567',
      'vehicle_model': 'pickup',
      'agency_name': 'وكالة النور',
      'is_verified': true,
      'cylinders_on_board': 12,
      'rating_sum': 9,
      'rating_count': 2,
    });
    expect(p.ratingAvg, 4.5);
    expect(p.vehicleType, 'pickup');
    expect(vehicleTypes, contains(p.vehicleType));
    expect(p.cylindersOnBoard, 12);
  });

  test('JordanPhone normalizes local numbers', () {
    expect(JordanPhone.normalize('079 123 4567'), '+962791234567');
    expect(JordanPhone.normalize('0612345678'), isNull);
  });
}

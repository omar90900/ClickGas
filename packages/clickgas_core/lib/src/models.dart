// Data models mapped 1:1 to the Supabase tables and RPCs in
// supabase/migrations/. Shared by the customer and distributor apps.
// Money is JOD with 3 decimals (fils); see docs/business-rules.md.

double _d(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    };

double? _dOrNull(Object? v) => v == null ? null : _d(v);

int _i(Object? v) => switch (v) {
      num n => n.toInt(),
      String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

String _localized(String locale, String ar, String en) =>
    locale == 'ar' ? ar : en;

// ---------------------------------------------------------------- enums

enum UserRole {
  customer,
  driver,
  admin;

  static UserRole parse(Object? v) =>
      values.firstWhere((r) => r.name == v, orElse: () => customer);
}

/// Order lifecycle. Allowed changes are listed in the `order_transitions`
/// table and enforced by the database (docs/business-rules.md#orders).
enum OrderStatus {
  pending('pending'),
  accepted('accepted'),
  onTheWay('on_the_way'),
  delivered('delivered'),
  cancelled('cancelled'),
  expired('expired');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus parse(Object? v) =>
      values.firstWhere((s) => s.value == v, orElse: () => pending);

  static const openValues = ['pending', 'accepted', 'on_the_way'];

  bool get isOpen => this == pending || this == accepted || this == onTheWay;
  bool get hasDriver => this == accepted || this == onTheWay;
  bool get isClosedWithoutDelivery => this == cancelled || this == expired;
}

enum PaymentMethod {
  cash,
  card;

  static PaymentMethod parse(Object? v) =>
      values.firstWhere((m) => m.name == v, orElse: () => cash);
}

/// Vehicle types a distributor can register with (stored as the code).
const vehicleTypes = ['pickup', 'van', 'small_truck', 'truck', 'tricycle'];

// ---------------------------------------------------------------- catalog

class City {
  final int id;
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;

  const City({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lng,
  });

  String name(String locale) => _localized(locale, nameAr, nameEn);

  factory City.fromMap(Map<String, dynamic> m) => City(
        id: _i(m['id']),
        nameAr: m['name_ar'] as String? ?? '',
        nameEn: m['name_en'] as String? ?? '',
        lat: _d(m['lat']),
        lng: _d(m['lng']),
      );
}

class GasService {
  final int id;
  final String code;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final double price;
  final String icon;
  final String? badge;

  const GasService({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    this.descriptionAr = '',
    this.descriptionEn = '',
    this.icon = 'exchange',
    this.badge,
  });

  String name(String locale) => _localized(locale, nameAr, nameEn);
  String description(String locale) =>
      _localized(locale, descriptionAr, descriptionEn);

  factory GasService.fromMap(Map<String, dynamic> m) => GasService(
        id: _i(m['id']),
        code: m['code'] as String? ?? '',
        nameAr: m['name_ar'] as String? ?? '',
        nameEn: m['name_en'] as String? ?? '',
        descriptionAr: m['description_ar'] as String? ?? '',
        descriptionEn: m['description_en'] as String? ?? '',
        price: _d(m['price']),
        icon: m['icon'] as String? ?? 'exchange',
        badge: m['badge'] as String?,
      );
}

/// Platform service fee per delivered order (`current_fees`).
class Fees {
  final double customerFee;
  final double driverFee;

  const Fees({required this.customerFee, required this.driverFee});

  static const zero = Fees(customerFee: 0, driverFee: 0);

  double get total => customerFee + driverFee;

  factory Fees.fromMap(Map<String, dynamic> m) => Fees(
        customerFee: _d(m['customer_fee']),
        driverFee: _d(m['driver_fee']),
      );
}

class AppConfig {
  final double deliveryFee;
  final int maxQuantity;
  final double searchRadiusKm;
  final String? supportPhone;
  final double driverRadiusKm;
  final int maxActiveOrders;
  final Fees fees;

  const AppConfig({
    this.deliveryFee = 0,
    this.maxQuantity = 5,
    this.searchRadiusKm = 5,
    this.supportPhone,
    this.driverRadiusKm = 2,
    this.maxActiveOrders = 3,
    this.fees = Fees.zero,
  });

  static const defaults = AppConfig();

  /// What the customer pays on top of the cylinders.
  double get customerExtras => deliveryFee + fees.customerFee;

  AppConfig withFees(Fees fees) => AppConfig(
        deliveryFee: deliveryFee,
        maxQuantity: maxQuantity,
        searchRadiusKm: searchRadiusKm,
        supportPhone: supportPhone,
        driverRadiusKm: driverRadiusKm,
        maxActiveOrders: maxActiveOrders,
        fees: fees,
      );

  factory AppConfig.fromMap(Map<String, dynamic> m) => AppConfig(
        deliveryFee: _d(m['delivery_fee']),
        maxQuantity: _i(m['max_quantity']) == 0 ? 5 : _i(m['max_quantity']),
        searchRadiusKm: _d(m['search_radius_km']),
        supportPhone: m['support_phone'] as String?,
        driverRadiusKm:
            m['driver_radius_km'] == null ? 2 : _d(m['driver_radius_km']),
        maxActiveOrders: m['max_active_orders'] == null
            ? 3
            : _i(m['max_active_orders']),
      );
}

// ---------------------------------------------------------------- people

class Profile {
  final String id;
  final UserRole role;
  final String fullName;
  final String phone;
  final String? email;
  final int? cityId;
  final String? avatarUrl;
  final bool isActive;
  final DateTime? createdAt;

  const Profile({
    required this.id,
    required this.role,
    required this.fullName,
    required this.phone,
    this.email,
    this.cityId,
    this.avatarUrl,
    this.isActive = true,
    this.createdAt,
  });

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  Profile withAvatar(String? url) => Profile(
        id: id,
        role: role,
        fullName: fullName,
        phone: phone,
        email: email,
        cityId: cityId,
        avatarUrl: url,
        isActive: isActive,
        createdAt: createdAt,
      );

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        role: UserRole.parse(m['role']),
        fullName: m['full_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String?,
        cityId: m['city_id'] == null ? null : _i(m['city_id']),
        avatarUrl: m['avatar_url'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        createdAt: _date(m['created_at']),
      );
}

/// A row of `drivers` as seen by customers (online distributors on the map).
class DriverLocation {
  final String id;
  final double lat;
  final double lng;
  final double? heading;
  final bool isOnline;
  final DateTime? updatedAt;

  const DriverLocation({
    required this.id,
    required this.lat,
    required this.lng,
    this.heading,
    this.isOnline = false,
    this.updatedAt,
  });

  static DriverLocation? fromMap(Map<String, dynamic> m) {
    final lat = _dOrNull(m['lat']);
    final lng = _dOrNull(m['lng']);
    if (lat == null || lng == null) return null;
    return DriverLocation(
      id: m['id'] as String,
      lat: lat,
      lng: lng,
      heading: _dOrNull(m['heading']),
      isOnline: m['is_online'] as bool? ?? false,
      updatedAt: _date(m['location_updated_at']),
    );
  }
}

/// The driver's own `drivers` row (distributor app).
class DriverProfile {
  final String id;
  final String vehiclePlate;
  final String vehicleType;
  final String agencyName;
  final int? cityId;
  final bool isVerified;
  final bool isOnline;
  final double? lat;
  final double? lng;
  final int cylindersOnBoard;
  final int ratingSum;
  final int ratingCount;

  const DriverProfile({
    required this.id,
    this.vehiclePlate = '',
    this.vehicleType = '',
    this.agencyName = '',
    this.cityId,
    this.isVerified = false,
    this.isOnline = false,
    this.lat,
    this.lng,
    this.cylindersOnBoard = 0,
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  double get ratingAvg => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  factory DriverProfile.fromMap(Map<String, dynamic> m) => DriverProfile(
        id: m['id'] as String,
        vehiclePlate: m['vehicle_plate'] as String? ?? '',
        vehicleType: m['vehicle_model'] as String? ?? '',
        agencyName: m['agency_name'] as String? ?? '',
        cityId: m['city_id'] == null ? null : _i(m['city_id']),
        isVerified: m['is_verified'] as bool? ?? false,
        isOnline: m['is_online'] as bool? ?? false,
        lat: _dOrNull(m['lat']),
        lng: _dOrNull(m['lng']),
        cylindersOnBoard: _i(m['cylinders_on_board']),
        ratingSum: _i(m['rating_sum']),
        ratingCount: _i(m['rating_count']),
      );
}

/// Driver card for the customer's open order (from `get_order_driver`).
class OrderDriver {
  final String id;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final String vehiclePlate;
  final String vehicleModel;
  final double ratingAvg;
  final double? lat;
  final double? lng;

  const OrderDriver({
    required this.id,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.vehiclePlate = '',
    this.vehicleModel = '',
    this.ratingAvg = 0,
    this.lat,
    this.lng,
  });

  factory OrderDriver.fromMap(Map<String, dynamic> m) => OrderDriver(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        avatarUrl: m['avatar_url'] as String?,
        vehiclePlate: m['vehicle_plate'] as String? ?? '',
        vehicleModel: m['vehicle_model'] as String? ?? '',
        ratingAvg: _d(m['rating_avg']),
        lat: _dOrNull(m['lat']),
        lng: _dOrNull(m['lng']),
      );
}

// ---------------------------------------------------------------- orders

class GasOrder {
  final String id;
  final int orderNumber;
  final String customerId;
  final String? driverId;
  final int serviceId;
  final String serviceCode;
  final String serviceNameAr;
  final String serviceNameEn;
  final int quantity;
  final double unitPrice;
  final double deliveryFee;

  /// Customer service fee copied from `current_fees` when ordered.
  final double serviceFee;

  /// Distributor fee copied from `current_fees` when ordered.
  final double driverFee;

  /// unit price x quantity + delivery fee + service fee.
  final double totalPrice;
  final PaymentMethod paymentMethod;
  final OrderStatus status;
  final double deliveryLat;
  final double deliveryLng;
  final String? deliveryAddress;
  final String? notes;
  final int? rating;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? onTheWayAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? customerConfirmedAt;

  const GasOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.serviceId,
    required this.serviceCode,
    required this.serviceNameAr,
    required this.serviceNameEn,
    required this.quantity,
    required this.unitPrice,
    required this.deliveryFee,
    required this.totalPrice,
    required this.paymentMethod,
    required this.status,
    required this.deliveryLat,
    required this.deliveryLng,
    this.serviceFee = 0,
    this.driverFee = 0,
    this.driverId,
    this.deliveryAddress,
    this.notes,
    this.rating,
    this.createdAt,
    this.acceptedAt,
    this.onTheWayAt,
    this.deliveredAt,
    this.cancelledAt,
    this.customerConfirmedAt,
  });

  String serviceName(String locale) =>
      _localized(locale, serviceNameAr, serviceNameEn);

  /// The driver marked it delivered; the customer hasn't confirmed receipt.
  bool get needsConfirmation =>
      status == OrderStatus.delivered && customerConfirmedAt == null;

  factory GasOrder.fromMap(Map<String, dynamic> m) => GasOrder(
        id: m['id'] as String,
        orderNumber: _i(m['order_number']),
        customerId: m['customer_id'] as String,
        driverId: m['driver_id'] as String?,
        serviceId: _i(m['service_id']),
        serviceCode: m['service_code'] as String? ?? '',
        serviceNameAr: m['service_name_ar'] as String? ?? '',
        serviceNameEn: m['service_name_en'] as String? ?? '',
        quantity: _i(m['quantity']),
        unitPrice: _d(m['unit_price']),
        deliveryFee: _d(m['delivery_fee']),
        serviceFee: _d(m['service_fee']),
        driverFee: _d(m['driver_fee']),
        totalPrice: _d(m['total_price']),
        paymentMethod: PaymentMethod.parse(m['payment_method']),
        status: OrderStatus.parse(m['status']),
        deliveryLat: _d(m['delivery_lat']),
        deliveryLng: _d(m['delivery_lng']),
        deliveryAddress: m['delivery_address'] as String?,
        notes: m['notes'] as String?,
        rating: m['rating'] == null ? null : _i(m['rating']),
        createdAt: _date(m['created_at']),
        acceptedAt: _date(m['accepted_at']),
        onTheWayAt: _date(m['on_the_way_at']),
        deliveredAt: _date(m['delivered_at']),
        cancelledAt: _date(m['cancelled_at']),
        customerConfirmedAt: _date(m['customer_confirmed_at']),
      );
}

/// A pending order near the driver (from `nearby_orders`).
class NearbyOrder {
  final String id;
  final int orderNumber;
  final String customerName;
  final String? customerAvatar;
  final String serviceNameAr;
  final String serviceNameEn;
  final int quantity;
  final double totalPrice;
  final PaymentMethod paymentMethod;
  final double lat;
  final double lng;
  final String? address;
  final String? notes;
  final DateTime? createdAt;
  final double distanceM;

  const NearbyOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.serviceNameAr,
    required this.serviceNameEn,
    required this.quantity,
    required this.totalPrice,
    required this.paymentMethod,
    required this.lat,
    required this.lng,
    required this.distanceM,
    this.customerAvatar,
    this.address,
    this.notes,
    this.createdAt,
  });

  String serviceName(String locale) =>
      _localized(locale, serviceNameAr, serviceNameEn);

  factory NearbyOrder.fromMap(Map<String, dynamic> m) => NearbyOrder(
        id: m['id'] as String,
        orderNumber: _i(m['order_number']),
        customerName: m['customer_name'] as String? ?? '',
        customerAvatar: m['customer_avatar'] as String?,
        serviceNameAr: m['service_name_ar'] as String? ?? '',
        serviceNameEn: m['service_name_en'] as String? ?? '',
        quantity: _i(m['quantity']),
        totalPrice: _d(m['total_price']),
        paymentMethod: PaymentMethod.parse(m['payment_method']),
        lat: _d(m['delivery_lat']),
        lng: _d(m['delivery_lng']),
        address: m['delivery_address'] as String?,
        notes: m['notes'] as String?,
        createdAt: _date(m['created_at']),
        distanceM: _d(m['distance_m']),
      );
}

/// One of the driver's accepted orders (from `driver_active_orders`).
class DriverOrder {
  final String id;
  final int orderNumber;
  final OrderStatus status;
  final String customerName;
  final String customerPhone;
  final String? customerAvatar;
  final String serviceNameAr;
  final String serviceNameEn;
  final int quantity;
  final double totalPrice;
  final PaymentMethod paymentMethod;
  final double lat;
  final double lng;
  final String? address;
  final String? notes;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;

  const DriverOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.serviceNameAr,
    required this.serviceNameEn,
    required this.quantity,
    required this.totalPrice,
    required this.paymentMethod,
    required this.lat,
    required this.lng,
    this.customerAvatar,
    this.address,
    this.notes,
    this.acceptedAt,
    this.deliveredAt,
  });

  String serviceName(String locale) =>
      _localized(locale, serviceNameAr, serviceNameEn);

  /// Delivered by the driver, waiting for the customer to confirm.
  bool get awaitingConfirmation => status == OrderStatus.delivered;

  factory DriverOrder.fromMap(Map<String, dynamic> m) => DriverOrder(
        id: m['id'] as String,
        orderNumber: _i(m['order_number']),
        status: OrderStatus.parse(m['status']),
        customerName: m['customer_name'] as String? ?? '',
        customerPhone: m['customer_phone'] as String? ?? '',
        customerAvatar: m['customer_avatar'] as String?,
        serviceNameAr: m['service_name_ar'] as String? ?? '',
        serviceNameEn: m['service_name_en'] as String? ?? '',
        quantity: _i(m['quantity']),
        totalPrice: _d(m['total_price']),
        paymentMethod: PaymentMethod.parse(m['payment_method']),
        lat: _d(m['delivery_lat']),
        lng: _d(m['delivery_lng']),
        address: m['delivery_address'] as String?,
        notes: m['notes'] as String?,
        acceptedAt: _date(m['accepted_at']),
        deliveredAt: _date(m['delivered_at']),
      );
}

/// An order the driver released back to other drivers (`order_releases`).
class OrderRelease {
  final int id;
  final String orderId;
  final int orderNumber;
  final String serviceNameAr;
  final String serviceNameEn;
  final int quantity;
  final double totalPrice;
  final String? reason;
  final DateTime? createdAt;

  const OrderRelease({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.serviceNameAr,
    required this.serviceNameEn,
    required this.quantity,
    required this.totalPrice,
    this.reason,
    this.createdAt,
  });

  String serviceName(String locale) =>
      _localized(locale, serviceNameAr, serviceNameEn);

  factory OrderRelease.fromMap(Map<String, dynamic> m) => OrderRelease(
        id: _i(m['id']),
        orderId: m['order_id'] as String,
        orderNumber: _i(m['order_number']),
        serviceNameAr: m['service_name_ar'] as String? ?? '',
        serviceNameEn: m['service_name_en'] as String? ?? '',
        quantity: _i(m['quantity']),
        totalPrice: _d(m['total_price']),
        reason: m['reason'] as String?,
        createdAt: _date(m['created_at']),
      );
}

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
  card,

  /// Paid from the customer's e-wallet to the distributor at the door
  /// (see wallet.dart).
  wallet;

  static PaymentMethod parse(Object? v) =>
      values.firstWhere((m) => m.name == v, orElse: () => cash);
}

/// Vehicle types a distributor can register with (stored as the code).
const vehicleTypes = ['pickup', 'van', 'small_truck', 'truck', 'tricycle'];

/// Distributor approval state (`drivers.status`). Only [approved]
/// distributors can go online and take orders.
enum DriverStatus {
  pending,
  approved,
  rejected,
  suspended;

  static DriverStatus parse(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => pending);
}

/// Papers a distributor uploads for approval (`driver_documents.kind`).
enum DocumentKind {
  nationalId('national_id'),
  drivingLicence('driving_licence'),
  vehicleRegistration('vehicle_registration'),
  agencyLetter('agency_letter');

  const DocumentKind(this.value);
  final String value;

  static DocumentKind parse(Object? v) =>
      values.firstWhere((k) => k.value == v, orElse: () => nationalId);
}

enum DocumentStatus {
  pending,
  approved,
  rejected;

  static DocumentStatus parse(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => pending);
}

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

  /// Language of pushes from the server (ar / en).
  final String locale;

  /// Pushes about the user's own orders.
  final bool notifyOrderUpdates;

  /// Distributors: pushes about new orders nearby.
  final bool notifyNewOrders;

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
    this.locale = 'ar',
    this.notifyOrderUpdates = true,
    this.notifyNewOrders = true,
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
        locale: locale,
        notifyOrderUpdates: notifyOrderUpdates,
        notifyNewOrders: notifyNewOrders,
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
        locale: m['locale'] as String? ?? 'ar',
        notifyOrderUpdates: m['notify_order_updates'] as bool? ?? true,
        notifyNewOrders: m['notify_new_orders'] as bool? ?? true,
      );
}

/// A row of the user's notification history (`notifications`).
class AppNotification {
  final int id;
  final String kind;
  final String titleAr;
  final String bodyAr;
  final String titleEn;
  final String bodyEn;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.titleAr,
    required this.bodyAr,
    required this.titleEn,
    required this.bodyEn,
    this.data = const {},
    this.createdAt,
    this.readAt,
  });

  String title(String locale) => _localized(locale, titleAr, titleEn);
  String body(String locale) => _localized(locale, bodyAr, bodyEn);
  bool get isRead => readAt != null;
  String? get orderId => data['order_id'] as String?;

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: _i(m['id']),
        kind: m['kind'] as String? ?? '',
        titleAr: m['title_ar'] as String? ?? '',
        bodyAr: m['body_ar'] as String? ?? '',
        titleEn: m['title_en'] as String? ?? '',
        bodyEn: m['body_en'] as String? ?? '',
        data: m['data'] is Map ? Map<String, dynamic>.from(m['data'] as Map) : const {},
        createdAt: _date(m['created_at']),
        readAt: _date(m['read_at']),
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

  /// Approval state; [isVerified] is true exactly when this is approved.
  final DriverStatus status;

  /// Why staff rejected or suspended the account (shown to the distributor).
  final String? statusReason;
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
    this.status = DriverStatus.pending,
    this.statusReason,
    this.isOnline = false,
    this.lat,
    this.lng,
    this.cylindersOnBoard = 0,
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  double get ratingAvg => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  factory DriverProfile.fromMap(Map<String, dynamic> m) {
    final verified = m['is_verified'] as bool? ?? false;
    return DriverProfile(
      id: m['id'] as String,
      vehiclePlate: m['vehicle_plate'] as String? ?? '',
      vehicleType: m['vehicle_model'] as String? ?? '',
      agencyName: m['agency_name'] as String? ?? '',
      cityId: m['city_id'] == null ? null : _i(m['city_id']),
      isVerified: verified,
      // Before the admin_core migration there is no status column.
      status: m['status'] == null
          ? (verified ? DriverStatus.approved : DriverStatus.pending)
          : DriverStatus.parse(m['status']),
      statusReason: m['status_reason'] as String?,
      isOnline: m['is_online'] as bool? ?? false,
      lat: _dOrNull(m['lat']),
      lng: _dOrNull(m['lng']),
      cylindersOnBoard: _i(m['cylinders_on_board']),
      ratingSum: _i(m['rating_sum']),
      ratingCount: _i(m['rating_count']),
    );
  }
}

/// One uploaded paper (`driver_documents`); the file is in the private
/// `driver-docs` bucket at [filePath].
class DriverDocument {
  final int id;
  final String driverId;
  final DocumentKind kind;
  final String filePath;
  final DocumentStatus status;
  final DateTime? expiresOn;
  final String? reviewNote;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;

  const DriverDocument({
    required this.id,
    required this.driverId,
    required this.kind,
    required this.filePath,
    this.status = DocumentStatus.pending,
    this.expiresOn,
    this.reviewNote,
    this.uploadedAt,
    this.reviewedAt,
  });

  bool get isPdf => filePath.toLowerCase().endsWith('.pdf');

  bool isExpired([DateTime? now]) {
    final e = expiresOn;
    if (e == null) return false;
    final today = now ?? DateTime.now();
    return DateTime(e.year, e.month, e.day)
        .isBefore(DateTime(today.year, today.month, today.day));
  }

  factory DriverDocument.fromMap(Map<String, dynamic> m) => DriverDocument(
        id: _i(m['id']),
        driverId: m['driver_id'] as String,
        kind: DocumentKind.parse(m['kind']),
        filePath: m['file_path'] as String? ?? '',
        status: DocumentStatus.parse(m['status']),
        // A date without time: parse as a local calendar date.
        expiresOn: m['expires_on'] is String
            ? DateTime.tryParse(m['expires_on'] as String)
            : null,
        reviewNote: m['review_note'] as String?,
        uploadedAt: _date(m['uploaded_at']),
        reviewedAt: _date(m['reviewed_at']),
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
  final String serviceCode;
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
    this.serviceCode = '',
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
        serviceCode: m['service_code'] as String? ?? '',
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
  final String serviceCode;
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
    this.serviceCode = '',
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
        serviceCode: m['service_code'] as String? ?? '',
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

// ---------------------------------------------------------------- coverage

/// `coverage_check(lat, lng)`: is any distributor online near this spot?
class Coverage {
  /// Online distributors within [maxRadiusKm].
  final int nearby;

  /// Nearest online distributor, anywhere (null when none is online).
  final double? nearestKm;
  final double radiusKm;
  final double maxRadiusKm;

  /// An order nobody accepts expires after this many minutes.
  final int expiryMinutes;

  const Coverage({
    required this.nearby,
    this.nearestKm,
    this.radiusKm = 2,
    this.maxRadiusKm = 6,
    this.expiryMinutes = 20,
  });

  bool get none => nearby == 0;

  factory Coverage.fromMap(Map<String, dynamic> m) => Coverage(
        nearby: _i(m['nearby']),
        nearestKm: _dOrNull(m['nearest_km']),
        radiusKm: m['radius_km'] == null ? 2 : _d(m['radius_km']),
        maxRadiusKm: m['max_radius_km'] == null ? 6 : _d(m['max_radius_km']),
        expiryMinutes: m['expiry_minutes'] == null ? 20 : _i(m['expiry_minutes']),
      );
}

// ---------------------------------------------------------------- charges

enum ChargeKind {
  fine('fine'),
  itemFee('item_fee'),
  other('other');

  const ChargeKind(this.value);
  final String value;

  static ChargeKind parse(Object? v) =>
      values.firstWhere((k) => k.value == v, orElse: () => other);
}

enum ChargeStatus {
  open,
  paid,
  waived;

  static ChargeStatus parse(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => open);
}

/// A fine or item fee staff raised against a distributor (`driver_charges`,
/// or a row of `admin_list_charges` with the names filled in). Not the
/// per-order service fee, which is platform revenue on the order itself.
class DriverCharge {
  final int id;
  final String driverId;
  final String? orderId;
  final int? orderNumber;
  final ChargeKind kind;
  final String title;

  /// The explanation the distributor sees.
  final String note;
  final double amount;
  final ChargeStatus status;
  final DateTime? createdAt;
  final DateTime? settledAt;
  final String? settleNote;

  // Filled by admin_list_charges only.
  final String? driverName;
  final String? driverPhone;
  final String? agencyName;
  final String? createdByName;
  final String? settledByName;

  const DriverCharge({
    required this.id,
    required this.driverId,
    required this.kind,
    required this.title,
    required this.note,
    required this.amount,
    this.status = ChargeStatus.open,
    this.orderId,
    this.orderNumber,
    this.createdAt,
    this.settledAt,
    this.settleNote,
    this.driverName,
    this.driverPhone,
    this.agencyName,
    this.createdByName,
    this.settledByName,
  });

  bool get isOpen => status == ChargeStatus.open;

  factory DriverCharge.fromMap(Map<String, dynamic> m) => DriverCharge(
        id: _i(m['id']),
        driverId: m['driver_id'] as String,
        orderId: m['order_id'] as String?,
        orderNumber: m['order_number'] == null ? null : _i(m['order_number']),
        kind: ChargeKind.parse(m['kind']),
        title: m['title'] as String? ?? '',
        note: m['note'] as String? ?? '',
        amount: _d(m['amount']),
        status: ChargeStatus.parse(m['status']),
        createdAt: _date(m['created_at']),
        settledAt: _date(m['settled_at']),
        settleNote: m['settle_note'] as String?,
        driverName: m['driver_name'] as String?,
        driverPhone: m['driver_phone'] as String?,
        agencyName: m['agency_name'] as String?,
        createdByName: m['created_by_name'] as String?,
        settledByName: m['settled_by_name'] as String?,
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

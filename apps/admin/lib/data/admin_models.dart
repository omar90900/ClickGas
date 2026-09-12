// Admin-only models, mapped 1:1 to the staff functions and tables in
// supabase/migrations/20260912150000_admin_core.sql (docs/api.md#staff).
// Shared models (GasOrder, DriverStatus, DriverDocument...) come from
// clickgas_core. Money is JOD with 3 decimals.
import 'dart:math' as math;

import 'package:clickgas_core/clickgas_core.dart';

double _d(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    };

double? _dn(Object? v) => v == null ? null : _d(v);

int _i(Object? v) => switch (v) {
      num n => n.toInt(),
      String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _list(Object? v) => v is List
    ? v.map((e) => Map<String, dynamic>.from(e as Map)).toList()
    : const [];

String _localized(String locale, String ar, String en) =>
    locale == 'ar' ? ar : en;

// ---------------------------------------------------------------- staff

/// Owner: everything. Operations: orders, distributors, payments.
/// Support: customers, read-only on money. The database enforces this;
/// the dashboard only hides what a role can't do.
enum StaffRole {
  owner,
  operations,
  support;

  /// Unknown values fall back to the least powerful role.
  static StaffRole parse(Object? v) =>
      values.firstWhere((r) => r.name == v, orElse: () => support);

  bool get isOwner => this == owner;

  /// Orders, distributor approvals and payments.
  bool get canOperate => this == owner || this == operations;
}

class StaffMember {
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final StaffRole role;
  final DateTime? createdAt;

  const StaffMember({
    required this.userId,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
    this.createdAt,
  });

  /// A row of `admin_whoami()`.
  factory StaffMember.fromWhoami(Map<String, dynamic> m) => StaffMember(
        userId: m['user_id'] as String,
        fullName: m['full_name'] as String? ?? '',
        email: m['email'] as String?,
        role: StaffRole.parse(m['role']),
      );

  /// A row of `staff_members` with the embedded `profiles` row.
  factory StaffMember.fromRow(Map<String, dynamic> m) {
    final p = _map(m['profiles']);
    return StaffMember(
      userId: m['user_id'] as String,
      fullName: p['full_name'] as String? ?? '',
      email: p['email'] as String?,
      phone: p['phone'] as String?,
      role: StaffRole.parse(m['role']),
      createdAt: _date(m['created_at']),
    );
  }
}

// ---------------------------------------------------------------- overview

class DayStat {
  final DateTime day;
  final int orders;
  final int delivered;
  final double fees;

  const DayStat({
    required this.day,
    required this.orders,
    required this.delivered,
    required this.fees,
  });

  factory DayStat.fromMap(Map<String, dynamic> m) => DayStat(
        day: DateTime.tryParse(m['day'] as String? ?? '') ?? DateTime(2000),
        orders: _i(m['orders']),
        delivered: _i(m['delivered']),
        fees: _d(m['fees']),
      );
}

/// `admin_overview()`: today in Jordan time plus a 14-day series.
class Overview {
  final int ordersToday;
  final int deliveredToday;
  final int cancelledToday;
  final int expiredToday;
  final double salesToday;
  final double feesToday;
  final double? medianAcceptSeconds;
  final int pending;
  final int inProgress;
  final int pendingOver10m;
  final int driversOnline;
  final int driversApproved;
  final int driversAwaitingApproval;
  final int documentsToReview;
  final int customersTotal;
  final int customersNewToday;
  final double feesOutstanding;
  final List<DayStat> days;

  const Overview({
    this.ordersToday = 0,
    this.deliveredToday = 0,
    this.cancelledToday = 0,
    this.expiredToday = 0,
    this.salesToday = 0,
    this.feesToday = 0,
    this.medianAcceptSeconds,
    this.pending = 0,
    this.inProgress = 0,
    this.pendingOver10m = 0,
    this.driversOnline = 0,
    this.driversApproved = 0,
    this.driversAwaitingApproval = 0,
    this.documentsToReview = 0,
    this.customersTotal = 0,
    this.customersNewToday = 0,
    this.feesOutstanding = 0,
    this.days = const [],
  });

  factory Overview.fromMap(Map<String, dynamic> m) => Overview(
        ordersToday: _i(m['orders_today']),
        deliveredToday: _i(m['delivered_today']),
        cancelledToday: _i(m['cancelled_today']),
        expiredToday: _i(m['expired_today']),
        salesToday: _d(m['sales_today']),
        feesToday: _d(m['fees_today']),
        medianAcceptSeconds: _dn(m['median_accept_seconds']),
        pending: _i(m['pending']),
        inProgress: _i(m['in_progress']),
        pendingOver10m: _i(m['pending_over_10m']),
        driversOnline: _i(m['drivers_online']),
        driversApproved: _i(m['drivers_approved']),
        driversAwaitingApproval: _i(m['drivers_awaiting_approval']),
        documentsToReview: _i(m['documents_to_review']),
        customersTotal: _i(m['customers_total']),
        customersNewToday: _i(m['customers_new_today']),
        feesOutstanding: _d(m['fees_outstanding']),
        days: _list(m['last_14_days']).map(DayStat.fromMap).toList(),
      );
}

// ---------------------------------------------------------------- live map

/// How long a pending order has waited: under 5 min, 5-15, over 15.
enum WaitBand {
  fresh,
  slow,
  late;

  static WaitBand of(Duration waited) => waited.inMinutes < 5
      ? fresh
      : waited.inMinutes < 15
          ? slow
          : late;
}

class LiveOrder {
  final String id;
  final int orderNumber;
  final OrderStatus status;
  final int quantity;
  final double totalPrice;
  final double lat;
  final double lng;
  final String? address;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final String? driverId;
  final String customerName;
  final String serviceNameAr;
  final String serviceNameEn;

  const LiveOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.quantity,
    required this.totalPrice,
    required this.lat,
    required this.lng,
    required this.customerName,
    this.serviceNameAr = '',
    this.serviceNameEn = '',
    this.address,
    this.createdAt,
    this.acceptedAt,
    this.driverId,
  });

  String serviceName(String locale) =>
      _localized(locale, serviceNameAr, serviceNameEn);

  Duration waited(DateTime now) =>
      createdAt == null ? Duration.zero : now.difference(createdAt!);

  factory LiveOrder.fromMap(Map<String, dynamic> m) => LiveOrder(
        id: m['id'] as String,
        orderNumber: _i(m['order_number']),
        status: OrderStatus.parse(m['status']),
        quantity: _i(m['quantity']),
        totalPrice: _d(m['total_price']),
        lat: _d(m['lat']),
        lng: _d(m['lng']),
        address: m['address'] as String?,
        createdAt: _date(m['created_at']),
        acceptedAt: _date(m['accepted_at']),
        driverId: m['driver_id'] as String?,
        customerName: m['customer_name'] as String? ?? '',
        serviceNameAr: m['service_name_ar'] as String? ?? '',
        serviceNameEn: m['service_name_en'] as String? ?? '',
      );
}

class LiveDriver {
  final String id;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final double lat;
  final double lng;
  final double? heading;
  final bool isOnline;
  final DateTime? locationUpdatedAt;
  final int cylindersOnBoard;
  final String vehiclePlate;
  final int openOrders;

  const LiveDriver({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.lat,
    required this.lng,
    this.avatarUrl,
    this.heading,
    this.isOnline = false,
    this.locationUpdatedAt,
    this.cylindersOnBoard = 0,
    this.vehiclePlate = '',
    this.openOrders = 0,
  });

  /// The app sends a position every few seconds while online; two minutes
  /// of silence means the phone lost signal or the app was closed.
  bool isStale(DateTime now) =>
      locationUpdatedAt == null ||
      now.difference(locationUpdatedAt!) > const Duration(minutes: 2);

  factory LiveDriver.fromMap(Map<String, dynamic> m) => LiveDriver(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        avatarUrl: m['avatar_url'] as String?,
        lat: _d(m['lat']),
        lng: _d(m['lng']),
        heading: _dn(m['heading']),
        isOnline: m['is_online'] as bool? ?? false,
        locationUpdatedAt: _date(m['location_updated_at']),
        cylindersOnBoard: _i(m['cylinders_on_board']),
        vehiclePlate: m['vehicle_plate'] as String? ?? '',
        openOrders: _i(m['open_orders']),
      );
}

class LiveMap {
  final List<LiveOrder> orders;
  final List<LiveDriver> drivers;

  const LiveMap({this.orders = const [], this.drivers = const []});

  factory LiveMap.fromMap(Map<String, dynamic> m) => LiveMap(
        orders: _list(m['orders']).map(LiveOrder.fromMap).toList(),
        drivers: _list(m['drivers']).map(LiveDriver.fromMap).toList(),
      );
}

// ---------------------------------------------------------------- people

/// A row of `admin_list_drivers()`.
class AdminDriver {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final bool isActive;
  final int? cityId;
  final DateTime? createdAt;
  final String vehiclePlate;
  final String vehicleType;
  final String agencyName;
  final DriverStatus status;
  final String? statusReason;
  final DateTime? statusChangedAt;
  final bool isOnline;
  final double? lat;
  final double? lng;
  final DateTime? locationUpdatedAt;
  final int cylindersOnBoard;
  final double ratingAvg;
  final int ratingCount;
  final int openOrders;
  final int deliveredOrders;

  /// What the distributor owes the platform now (negative = in credit).
  final double balance;
  final int documentsPending;
  final int documentsTotal;

  const AdminDriver({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    this.email,
    this.avatarUrl,
    this.isActive = true,
    this.cityId,
    this.createdAt,
    this.vehiclePlate = '',
    this.vehicleType = '',
    this.agencyName = '',
    this.statusReason,
    this.statusChangedAt,
    this.isOnline = false,
    this.lat,
    this.lng,
    this.locationUpdatedAt,
    this.cylindersOnBoard = 0,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.openOrders = 0,
    this.deliveredOrders = 0,
    this.balance = 0,
    this.documentsPending = 0,
    this.documentsTotal = 0,
  });

  factory AdminDriver.fromMap(Map<String, dynamic> m) => AdminDriver(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        cityId: m['city_id'] == null ? null : _i(m['city_id']),
        createdAt: _date(m['created_at']),
        vehiclePlate: m['vehicle_plate'] as String? ?? '',
        vehicleType: m['vehicle_model'] as String? ?? '',
        agencyName: m['agency_name'] as String? ?? '',
        status: DriverStatus.parse(m['status']),
        statusReason: m['status_reason'] as String?,
        statusChangedAt: _date(m['status_changed_at']),
        isOnline: m['is_online'] as bool? ?? false,
        lat: _dn(m['lat']),
        lng: _dn(m['lng']),
        locationUpdatedAt: _date(m['location_updated_at']),
        cylindersOnBoard: _i(m['cylinders_on_board']),
        ratingAvg: _d(m['rating_avg']),
        ratingCount: _i(m['rating_count']),
        openOrders: _i(m['open_orders']),
        deliveredOrders: _i(m['delivered_orders']),
        balance: _d(m['balance']),
        documentsPending: _i(m['documents_pending']),
        documentsTotal: _i(m['documents_total']),
      );
}

/// A row of `admin_list_customers()`.
class AdminCustomer {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final int? cityId;
  final bool isActive;
  final DateTime? createdAt;
  final int ordersTotal;
  final int delivered;
  final int cancelled;
  final int openOrders;
  final DateTime? lastOrderAt;

  const AdminCustomer({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.cityId,
    this.isActive = true,
    this.createdAt,
    this.ordersTotal = 0,
    this.delivered = 0,
    this.cancelled = 0,
    this.openOrders = 0,
    this.lastOrderAt,
  });

  /// Reliability flag: at least 4 orders and half or more cancelled.
  bool get oftenCancels => ordersTotal >= 4 && cancelled * 2 >= ordersTotal;

  factory AdminCustomer.fromMap(Map<String, dynamic> m) => AdminCustomer(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        cityId: m['city_id'] == null ? null : _i(m['city_id']),
        isActive: m['is_active'] as bool? ?? true,
        createdAt: _date(m['created_at']),
        ordersTotal: _i(m['orders_total']),
        delivered: _i(m['delivered']),
        cancelled: _i(m['cancelled']),
        openOrders: _i(m['open_orders']),
        lastOrderAt: _date(m['last_order_at']),
      );
}

/// One page of a list plus the number of all matches.
class Paged<T> {
  final List<T> items;
  final int total;

  const Paged(this.items, this.total);

  static Paged<T> fromRows<T>(
    List<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) parse,
  ) =>
      Paged(
        rows.map(parse).toList(),
        rows.isEmpty ? 0 : _i(rows.first['total_count']),
      );
}

// ---------------------------------------------------------------- orders

/// A row of `admin_search_orders()`.
class AdminOrder {
  final String id;
  final int orderNumber;
  final OrderStatus status;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final int? cityId;
  final String serviceNameAr;
  final String serviceNameEn;
  final int quantity;
  final double totalPrice;
  final double serviceFee;
  final double driverFee;
  final String? address;
  final double lat;
  final double lng;
  final String? cancelReason;
  final int? rating;

  const AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.quantity,
    required this.totalPrice,
    this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.cityId,
    this.serviceNameAr = '',
    this.serviceNameEn = '',
    this.serviceFee = 0,
    this.driverFee = 0,
    this.address,
    this.lat = 0,
    this.lng = 0,
    this.cancelReason,
    this.rating,
  });

  String serviceName(String locale) =>
      _localized(locale, serviceNameAr, serviceNameEn);

  factory AdminOrder.fromMap(Map<String, dynamic> m) => AdminOrder(
        id: m['id'] as String,
        orderNumber: _i(m['order_number']),
        status: OrderStatus.parse(m['status']),
        createdAt: _date(m['created_at']),
        acceptedAt: _date(m['accepted_at']),
        deliveredAt: _date(m['delivered_at']),
        cancelledAt: _date(m['cancelled_at']),
        customerId: m['customer_id'] as String,
        customerName: m['customer_name'] as String? ?? '',
        customerPhone: m['customer_phone'] as String? ?? '',
        driverId: m['driver_id'] as String?,
        driverName: m['driver_name'] as String?,
        driverPhone: m['driver_phone'] as String?,
        cityId: m['city_id'] == null ? null : _i(m['city_id']),
        serviceNameAr: m['service_name_ar'] as String? ?? '',
        serviceNameEn: m['service_name_en'] as String? ?? '',
        quantity: _i(m['quantity']),
        totalPrice: _d(m['total_price']),
        serviceFee: _d(m['service_fee']),
        driverFee: _d(m['driver_fee']),
        address: m['delivery_address'] as String?,
        lat: _d(m['delivery_lat']),
        lng: _d(m['delivery_lng']),
        cancelReason: m['cancel_reason'] as String?,
        rating: m['rating'] == null ? null : _i(m['rating']),
      );
}

/// Filters for the Orders page (all optional).
class OrderQuery {
  final String search;
  final Set<OrderStatus> statuses;
  final DateTime? from;
  final DateTime? to;
  final String? driverId;
  final String? customerId;
  final int limit;
  final int offset;

  const OrderQuery({
    this.search = '',
    this.statuses = const {},
    this.from,
    this.to,
    this.driverId,
    this.customerId,
    this.limit = 50,
    this.offset = 0,
  });

  OrderQuery copyWith({
    String? search,
    Set<OrderStatus>? statuses,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
    int? offset,
  }) =>
      OrderQuery(
        search: search ?? this.search,
        statuses: statuses ?? this.statuses,
        from: clearDates ? null : (from ?? this.from),
        to: clearDates ? null : (to ?? this.to),
        driverId: driverId,
        customerId: customerId,
        limit: limit,
        offset: offset ?? 0,
      );

  Map<String, dynamic> toParams() => {
        'p_search': search.trim().isEmpty ? null : search.trim(),
        'p_statuses':
            statuses.isEmpty ? null : statuses.map((s) => s.value).toList(),
        'p_driver_id': driverId,
        'p_customer_id': customerId,
        'p_from': from?.toUtc().toIso8601String(),
        'p_to': to?.toUtc().toIso8601String(),
        'p_limit': limit,
        'p_offset': offset,
      };

  /// Stable identity for widget keys: a new key reloads the list.
  String get key => toParams().toString();
}

class PersonCard {
  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final bool isActive;
  final bool isOnline;
  final String vehiclePlate;
  final String vehicleType;
  final double? lat;
  final double? lng;
  final DateTime? locationUpdatedAt;

  const PersonCard({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.isActive = true,
    this.isOnline = false,
    this.vehiclePlate = '',
    this.vehicleType = '',
    this.lat,
    this.lng,
    this.locationUpdatedAt,
  });

  factory PersonCard.fromMap(Map<String, dynamic> m) => PersonCard(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        email: m['email'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        isOnline: m['is_online'] as bool? ?? false,
        vehiclePlate: m['vehicle_plate'] as String? ?? '',
        vehicleType: m['vehicle_model'] as String? ?? '',
        lat: _dn(m['lat']),
        lng: _dn(m['lng']),
        locationUpdatedAt: _date(m['location_updated_at']),
      );
}

class OrderEvent {
  final OrderStatus status;
  final DateTime? at;
  final String? actorName;

  /// customer / driver / admin; null when the system made the change.
  final UserRole? actorRole;

  const OrderEvent({required this.status, this.at, this.actorName, this.actorRole});

  factory OrderEvent.fromMap(Map<String, dynamic> m) => OrderEvent(
        status: OrderStatus.parse(m['status']),
        at: _date(m['at']),
        actorName: m['actor_name'] as String?,
        actorRole: m['actor_role'] == null ? null : UserRole.parse(m['actor_role']),
      );
}

class ReleaseEntry {
  final String driverId;
  final String? driverName;
  final String? reason;
  final DateTime? at;

  const ReleaseEntry({required this.driverId, this.driverName, this.reason, this.at});

  factory ReleaseEntry.fromMap(Map<String, dynamic> m) => ReleaseEntry(
        driverId: m['driver_id'] as String,
        driverName: m['driver_name'] as String?,
        reason: m['reason'] as String?,
        at: _date(m['at']),
      );
}

enum LedgerKind {
  orderFee('order_fee'),
  payment('payment'),
  adjustment('adjustment');

  const LedgerKind(this.value);
  final String value;

  static LedgerKind parse(Object? v) =>
      values.firstWhere((k) => k.value == v, orElse: () => adjustment);
}

/// A `driver_ledger` row: positive = owed by the distributor, negative =
/// paid or waived.
class LedgerEntry {
  final int id;
  final String driverId;
  final String? orderId;
  final LedgerKind kind;
  final double amount;
  final String? note;
  final DateTime? createdAt;

  const LedgerEntry({
    required this.id,
    required this.driverId,
    required this.kind,
    required this.amount,
    this.orderId,
    this.note,
    this.createdAt,
  });

  factory LedgerEntry.fromMap(Map<String, dynamic> m) => LedgerEntry(
        id: _i(m['id']),
        driverId: m['driver_id'] as String,
        orderId: m['order_id'] as String?,
        kind: LedgerKind.parse(m['kind']),
        amount: _d(m['amount']),
        note: m['note'] as String?,
        createdAt: _date(m['created_at']),
      );
}

/// A row of the `admin_actions` audit trail.
class AdminAction {
  final int id;
  final String? actorId;
  final String? actorName;
  final StaffRole? actorRole;
  final String action;
  final String targetType;
  final String? targetId;
  final String? reason;
  final Map<String, dynamic> detail;
  final DateTime? createdAt;

  const AdminAction({
    required this.id,
    required this.action,
    required this.targetType,
    this.actorId,
    this.actorName,
    this.actorRole,
    this.targetId,
    this.reason,
    this.detail = const {},
    this.createdAt,
  });

  factory AdminAction.fromMap(Map<String, dynamic> m) => AdminAction(
        id: _i(m['id']),
        actorId: m['actor_id'] as String?,
        actorName: m['actor_name'] as String?,
        actorRole: m['actor_role'] == null ? null : StaffRole.parse(m['actor_role']),
        action: m['action'] as String? ?? '',
        targetType: m['target_type'] as String? ?? '',
        targetId: m['target_id'] as String?,
        reason: m['reason'] as String?,
        detail: _map(m['detail']),
        createdAt: _date(m['created_at']),
      );
}

/// `admin_order_detail()`: everything about one order.
class OrderDetail {
  final GasOrder order;
  final String? cancelReason;
  final String? ratingComment;
  final PersonCard? customer;
  final PersonCard? driver;
  final List<OrderEvent> events;
  final List<ReleaseEntry> releases;
  final List<LedgerEntry> ledger;
  final List<AdminAction> actions;

  const OrderDetail({
    required this.order,
    this.cancelReason,
    this.ratingComment,
    this.customer,
    this.driver,
    this.events = const [],
    this.releases = const [],
    this.ledger = const [],
    this.actions = const [],
  });

  factory OrderDetail.fromMap(Map<String, dynamic> m) {
    final o = _map(m['order']);
    final customer = _map(m['customer']);
    final driver = _map(m['driver']);
    return OrderDetail(
      order: GasOrder.fromMap(o),
      cancelReason: o['cancel_reason'] as String?,
      ratingComment: o['rating_comment'] as String?,
      customer: customer.isEmpty ? null : PersonCard.fromMap(customer),
      driver: driver.isEmpty ? null : PersonCard.fromMap(driver),
      events: _list(m['events']).map(OrderEvent.fromMap).toList(),
      releases: _list(m['releases']).map(ReleaseEntry.fromMap).toList(),
      ledger: _list(m['ledger']).map(LedgerEntry.fromMap).toList(),
      actions: _list(m['actions']).map(AdminAction.fromMap).toList(),
    );
  }
}

// ---------------------------------------------------------------- money

/// A row of `admin_balances()`.
class Balance {
  final String driverId;
  final String fullName;
  final String phone;
  final DriverStatus status;
  final double fees;
  final double payments;
  final double adjustments;
  final double balance;
  final int deliveries;
  final DateTime? lastPaymentAt;

  const Balance({
    required this.driverId,
    required this.fullName,
    required this.phone,
    required this.status,
    this.fees = 0,
    this.payments = 0,
    this.adjustments = 0,
    this.balance = 0,
    this.deliveries = 0,
    this.lastPaymentAt,
  });

  factory Balance.fromMap(Map<String, dynamic> m) => Balance(
        driverId: m['driver_id'] as String,
        fullName: m['full_name'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        status: DriverStatus.parse(m['status']),
        fees: _d(m['fees']),
        payments: _d(m['payments']),
        adjustments: _d(m['adjustments']),
        balance: _d(m['balance']),
        deliveries: _i(m['deliveries']),
        lastPaymentAt: _date(m['last_payment_at']),
      );
}

// ---------------------------------------------------------------- settings

/// The single `app_config` row, as edited on the Settings page.
class ConfigSettings {
  final double deliveryFee;
  final int maxQuantity;
  final double searchRadiusKm;
  final String? supportPhone;
  final double driverRadiusKm;
  final int maxActiveOrders;
  final bool autoVerifyDrivers;
  final int confirmTimeoutMinutes;
  final String minCustomerVersion;
  final String minDistributorVersion;
  final DateTime? updatedAt;

  const ConfigSettings({
    this.deliveryFee = 0,
    this.maxQuantity = 5,
    this.searchRadiusKm = 5,
    this.supportPhone,
    this.driverRadiusKm = 2,
    this.maxActiveOrders = 3,
    this.autoVerifyDrivers = false,
    this.confirmTimeoutMinutes = 120,
    this.minCustomerVersion = '1.0.0',
    this.minDistributorVersion = '1.0.0',
    this.updatedAt,
  });

  factory ConfigSettings.fromMap(Map<String, dynamic> m) => ConfigSettings(
        deliveryFee: _d(m['delivery_fee']),
        maxQuantity: _i(m['max_quantity']),
        searchRadiusKm: _d(m['search_radius_km']),
        supportPhone: m['support_phone'] as String?,
        driverRadiusKm: _d(m['driver_radius_km']),
        maxActiveOrders: _i(m['max_active_orders']),
        autoVerifyDrivers: m['auto_verify_drivers'] as bool? ?? false,
        confirmTimeoutMinutes: _i(m['confirm_timeout_minutes']),
        minCustomerVersion: m['min_customer_version'] as String? ?? '1.0.0',
        minDistributorVersion: m['min_distributor_version'] as String? ?? '1.0.0',
        updatedAt: _date(m['updated_at']),
      );

  /// The keys `admin_update_config` accepts, with their current values.
  Map<String, Object?> toMap() => {
        'delivery_fee': deliveryFee,
        'max_quantity': maxQuantity,
        'search_radius_km': searchRadiusKm,
        'support_phone': supportPhone,
        'driver_radius_km': driverRadiusKm,
        'max_active_orders': maxActiveOrders,
        'auto_verify_drivers': autoVerifyDrivers,
        'confirm_timeout_minutes': confirmTimeoutMinutes,
        'min_customer_version': minCustomerVersion,
        'min_distributor_version': minDistributorVersion,
      };
}

/// A `fee_settings` row: the pair in force from [effectiveFrom].
class FeeSetting {
  final int id;
  final double customerFee;
  final double driverFee;
  final DateTime? effectiveFrom;
  final String? note;
  final DateTime? createdAt;

  const FeeSetting({
    required this.id,
    required this.customerFee,
    required this.driverFee,
    this.effectiveFrom,
    this.note,
    this.createdAt,
  });

  double get total => customerFee + driverFee;

  bool isScheduled(DateTime now) =>
      effectiveFrom != null && effectiveFrom!.isAfter(now);

  factory FeeSetting.fromMap(Map<String, dynamic> m) => FeeSetting(
        id: _i(m['id']),
        customerFee: _d(m['customer_fee']),
        driverFee: _d(m['driver_fee']),
        effectiveFrom: _date(m['effective_from']),
        note: m['note'] as String?,
        createdAt: _date(m['created_at']),
      );
}

/// The fee pair in force at [now]: the latest row that has started.
FeeSetting? feesInForce(List<FeeSetting> all, DateTime now) {
  FeeSetting? best;
  for (final f in all) {
    final from = f.effectiveFrom;
    if (from == null || from.isAfter(now)) continue;
    if (best == null ||
        from.isAfter(best.effectiveFrom!) ||
        (from == best.effectiveFrom && f.id > best.id)) {
      best = f;
    }
  }
  return best;
}

/// A `services` row including inactive ones (staff see all).
class AdminService {
  final int id;
  final String code;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double price;
  final String icon;
  final String? badge;
  final bool isActive;
  final int sortOrder;

  const AdminService({
    required this.id,
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    this.descriptionAr,
    this.descriptionEn,
    this.icon = 'exchange',
    this.badge,
    this.isActive = true,
    this.sortOrder = 0,
  });

  String name(String locale) => _localized(locale, nameAr, nameEn);

  factory AdminService.fromMap(Map<String, dynamic> m) => AdminService(
        id: _i(m['id']),
        code: m['code'] as String? ?? '',
        nameAr: m['name_ar'] as String? ?? '',
        nameEn: m['name_en'] as String? ?? '',
        descriptionAr: m['description_ar'] as String?,
        descriptionEn: m['description_en'] as String?,
        price: _d(m['price']),
        icon: m['icon'] as String? ?? 'exchange',
        badge: m['badge'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        sortOrder: _i(m['sort_order']),
      );
}

class PriceChange {
  final int id;
  final int serviceId;
  final double? oldPrice;
  final double newPrice;
  final DateTime? changedAt;

  const PriceChange({
    required this.id,
    required this.serviceId,
    required this.newPrice,
    this.oldPrice,
    this.changedAt,
  });

  factory PriceChange.fromMap(Map<String, dynamic> m) => PriceChange(
        id: _i(m['id']),
        serviceId: _i(m['service_id']),
        oldPrice: _dn(m['old_price']),
        newPrice: _d(m['new_price']),
        changedAt: _date(m['changed_at']),
      );
}

class AdminCity {
  final int id;
  final String nameAr;
  final String nameEn;
  final bool isActive;
  final int sortOrder;

  const AdminCity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.isActive = true,
    this.sortOrder = 0,
  });

  String name(String locale) => _localized(locale, nameAr, nameEn);

  factory AdminCity.fromMap(Map<String, dynamic> m) => AdminCity(
        id: _i(m['id']),
        nameAr: m['name_ar'] as String? ?? '',
        nameEn: m['name_en'] as String? ?? '',
        isActive: m['is_active'] as bool? ?? true,
        sortOrder: _i(m['sort_order']),
      );
}

class FeatureFlag {
  final String key;
  final bool enabled;
  final String description;
  final DateTime? updatedAt;

  const FeatureFlag({
    required this.key,
    required this.enabled,
    this.description = '',
    this.updatedAt,
  });

  factory FeatureFlag.fromMap(Map<String, dynamic> m) => FeatureFlag(
        key: m['key'] as String,
        enabled: m['enabled'] as bool? ?? false,
        description: m['description'] as String? ?? '',
        updatedAt: _date(m['updated_at']),
      );
}

// ---------------------------------------------------------------- geometry

/// Great-circle distance in kilometres (same formula as `distance_m` in SQL).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

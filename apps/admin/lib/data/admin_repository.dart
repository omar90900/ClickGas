import 'package:clickgas_core/clickgas_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_models.dart';

/// Every staff read and write. Writes go only through the audited
/// `admin_*` functions (docs/api.md#staff); reads use those functions or
/// tables whose Row Level Security lets staff see them. Throws only
/// [AppFailure].
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _rows(Object? value) => (value as List)
      .map((r) => Map<String, dynamic>.from(r as Map))
      .toList();

  Map<String, dynamic> _row(Object? value) =>
      Map<String, dynamic>.from(value as Map);

  // ---------------------------------------------------------- session

  /// The signed-in staff member, or null when the account is not staff.
  Future<StaffMember?> whoami() => guard('admin.whoami', () async {
        final rows = _rows(await _client.rpc('admin_whoami'));
        return rows.isEmpty ? null : StaffMember.fromWhoami(rows.first);
      });

  // ---------------------------------------------------------- dashboard

  Future<Overview> overview() => guard('admin.overview', () async {
        return Overview.fromMap(_row(await _client.rpc('admin_overview')));
      });

  Future<LiveMap> liveMap() => guard('admin.live_map', () async {
        return LiveMap.fromMap(_row(await _client.rpc('admin_live_map')));
      });

  /// Orders served vs expired, coverage gaps and job runs for [from]..[to].
  Future<CoverageReport> coverage(DateTime from, DateTime to) => guard('admin.coverage', () async {
        final value = await _client.rpc('admin_coverage', params: {
          'p_from': from.toUtc().toIso8601String(),
          'p_to': to.toUtc().toIso8601String(),
        });
        return CoverageReport.fromMap(_row(value));
      });

  /// The caller's dashboard shows or hides demo data (tools/demo).
  Future<bool> setHideDemo(bool hide) => guard('admin.hide_demo', () async {
        final value = await _client.rpc('admin_set_hide_demo', params: {'p_hide': hide});
        return value == true;
      });

  // ---------------------------------------------------------- distributors

  Future<List<AdminDriver>> drivers({DriverStatus? status, String? search}) =>
      guard('admin.drivers', () async {
        final rows = await _client.rpc('admin_list_drivers', params: {
          'p_status': status?.name,
          'p_search': (search == null || search.trim().isEmpty) ? null : search.trim(),
        });
        return _rows(rows).map(AdminDriver.fromMap).toList();
      });

  Future<AdminDriver> driver(String driverId) => guard('admin.driver', () async {
        final rows = _rows(await _client.rpc('admin_list_drivers', params: {'p_driver_id': driverId}));
        if (rows.isEmpty) throw const AppFailure(FailureCode.notFound);
        return AdminDriver.fromMap(rows.first);
      }, context: {'driver_id': driverId});

  Future<void> setDriverStatus(String driverId, DriverStatus status, {String? reason}) =>
      guard('admin.driver_status', () async {
        await _client.rpc('admin_set_driver_status', params: {
          'p_driver_id': driverId,
          'p_status': status.name,
          'p_reason': reason,
        });
        Log.i('driver_status_set', {'driver_id': driverId, 'status': status.name});
      }, context: {'driver_id': driverId, 'status': status.name});

  Future<void> reviewDocument(int documentId, {required bool approve, String? note}) =>
      guard('admin.review_document', () async {
        await _client.rpc('admin_review_document', params: {
          'p_document_id': documentId,
          'p_approve': approve,
          'p_note': note,
        });
      }, context: {'document_id': documentId, 'approve': approve});

  /// Block (with a reason) or unblock a customer or distributor.
  Future<void> setAccountActive(String userId, bool active, {String? reason}) =>
      guard('admin.account_active', () async {
        await _client.rpc('admin_set_account_active', params: {
          'p_user_id': userId,
          'p_active': active,
          'p_reason': reason,
        });
        Log.i(active ? 'account_unblocked' : 'account_blocked', {'user_id': userId});
      }, context: {'user_id': userId, 'active': active});

  // ---------------------------------------------------------- customers

  Future<Paged<AdminCustomer>> customers({String? search, int limit = 50, int offset = 0}) =>
      guard('admin.customers', () async {
        final rows = await _client.rpc('admin_list_customers', params: {
          'p_search': (search == null || search.trim().isEmpty) ? null : search.trim(),
          'p_limit': limit,
          'p_offset': offset,
        });
        return Paged.fromRows(_rows(rows), AdminCustomer.fromMap);
      });

  // ---------------------------------------------------------- orders

  Future<Paged<AdminOrder>> searchOrders(OrderQuery query) =>
      guard('admin.search_orders', () async {
        final rows = await _client.rpc('admin_search_orders', params: query.toParams());
        return Paged.fromRows(_rows(rows), AdminOrder.fromMap);
      });

  Future<OrderDetail> orderDetail(String orderId) => guard('admin.order_detail', () async {
        final value = await _client.rpc('admin_order_detail', params: {'p_order_id': orderId});
        return OrderDetail.fromMap(_row(value));
      }, context: {'order_id': orderId});

  Future<void> cancelOrder(String orderId, String reason) => guard('admin.cancel_order', () async {
        await _client.rpc('admin_cancel_order', params: {'p_order_id': orderId, 'p_reason': reason});
        Log.i('order_cancelled_by_staff', {'order_id': orderId});
      }, context: {'order_id': orderId});

  /// Gives the order to [driverId], or back to the queue when it is null.
  Future<void> assignOrder(String orderId, String? driverId, String reason) =>
      guard('admin.assign_order', () async {
        await _client.rpc('admin_assign_order', params: {
          'p_order_id': orderId,
          'p_driver_id': driverId,
          'p_reason': reason,
        });
        Log.i('order_assigned_by_staff', {'order_id': orderId, 'driver_id': driverId});
      }, context: {'order_id': orderId, 'driver_id': driverId});

  // ---------------------------------------------------------- finance & charges

  /// Income and charges for [from]..[to] (end exclusive).
  Future<FinanceReport> finance(DateTime from, DateTime to) => guard('admin.finance', () async {
        final value = await _client.rpc('admin_finance', params: {
          'p_from': from.toUtc().toIso8601String(),
          'p_to': to.toUtc().toIso8601String(),
        });
        return FinanceReport.fromMap(_row(value));
      });

  Future<Paged<DriverCharge>> charges({
    ChargeStatus? status,
    String? driverId,
    int limit = 100,
    int offset = 0,
  }) =>
      guard('admin.charges', () async {
        final rows = await _client.rpc('admin_list_charges', params: {
          'p_status': status?.name,
          'p_driver_id': driverId,
          'p_limit': limit,
          'p_offset': offset,
        });
        return Paged.fromRows(_rows(rows), DriverCharge.fromMap);
      });

  /// A fine or item fee with the explanation the distributor sees.
  Future<void> createCharge({
    required String driverId,
    required ChargeKind kind,
    required String title,
    required double amount,
    required String note,
    String? orderId,
  }) =>
      guard('admin.create_charge', () async {
        await _client.rpc('admin_create_charge', params: {
          'p_driver_id': driverId,
          'p_kind': kind.value,
          'p_title': title,
          'p_amount': amount,
          'p_note': note,
          'p_order_id': orderId,
        });
        Log.i('charge_created', {'driver_id': driverId, 'kind': kind.value});
      }, context: {'driver_id': driverId});

  /// Paid (owner, operations) or waived (owner, with a reason).
  Future<void> settleCharge(int chargeId, ChargeStatus status, {String? note}) =>
      guard('admin.settle_charge', () async {
        await _client.rpc('admin_settle_charge', params: {
          'p_charge_id': chargeId,
          'p_status': status.name,
          'p_note': note,
        });
      }, context: {'charge_id': chargeId, 'status': status.name});

  // ---------------------------------------------------------- prices & fees

  Future<List<AdminService>> services() => guard('admin.services', () async {
        final rows = await _client.from('services').select().order('sort_order');
        return rows.map(AdminService.fromMap).toList();
      });

  Future<List<PriceChange>> priceHistory({int limit = 50}) =>
      guard('admin.price_history', () async {
        final rows = await _client
            .from('price_history')
            .select()
            .order('changed_at', ascending: false)
            .limit(limit);
        return rows.map(PriceChange.fromMap).toList();
      });

  /// Null leaves a field unchanged; an empty description or badge clears it.
  Future<void> updateService(
    int serviceId, {
    double? price,
    bool? isActive,
    String? nameAr,
    String? nameEn,
    String? descriptionAr,
    String? descriptionEn,
    String? badge,
  }) =>
      guard('admin.update_service', () async {
        await _client.rpc('admin_update_service', params: {
          'p_service_id': serviceId,
          'p_price': price,
          'p_is_active': isActive,
          'p_name_ar': nameAr,
          'p_name_en': nameEn,
          'p_description_ar': descriptionAr,
          'p_description_en': descriptionEn,
          'p_badge': badge,
        });
      }, context: {'service_id': serviceId});

  Future<void> createService({
    required String code,
    required String nameAr,
    required String nameEn,
    required double price,
    String? descriptionAr,
    String? descriptionEn,
  }) =>
      guard('admin.create_service', () async {
        await _client.rpc('admin_create_service', params: {
          'p_code': code,
          'p_name_ar': nameAr,
          'p_name_en': nameEn,
          'p_price': price,
          'p_description_ar': descriptionAr,
          'p_description_en': descriptionEn,
        });
      }, context: {'code': code});

  Future<List<FeeSetting>> fees() => guard('admin.fees', () async {
        final rows = await _client
            .from('fee_settings')
            .select()
            .order('effective_from', ascending: false)
            .order('id', ascending: false)
            .limit(50);
        return rows.map(FeeSetting.fromMap).toList();
      });

  Future<void> setFees({
    required double customerFee,
    required double driverFee,
    DateTime? effectiveFrom,
    String? note,
  }) =>
      guard('admin.set_fees', () async {
        await _client.rpc('admin_set_fees', params: {
          'p_customer_fee': customerFee,
          'p_driver_fee': driverFee,
          'p_effective_from': effectiveFrom?.toUtc().toIso8601String(),
          'p_note': note,
        });
        Log.i('fees_set', {'customer_fee': customerFee, 'driver_fee': driverFee});
      });

  // ---------------------------------------------------------- settings

  Future<ConfigSettings> config() => guard('admin.config', () async {
        final row = await _client.from('app_config').select().single();
        return ConfigSettings.fromMap(row);
      });

  /// Sends only the changed keys, e.g. `{'driver_radius_km': 3}`.
  Future<ConfigSettings> updateConfig(Map<String, Object?> changes) =>
      guard('admin.update_config', () async {
        final row = await _client.rpc('admin_update_config', params: {'p_changes': changes});
        return ConfigSettings.fromMap(_row(row));
      }, context: {'keys': changes.keys.join(',')});

  Future<List<AdminCity>> cities() => guard('admin.cities', () async {
        final rows = await _client.from('cities').select().order('sort_order');
        return rows.map(AdminCity.fromMap).toList();
      });

  Future<void> setCityActive(int cityId, bool active) => guard('admin.city_active', () async {
        await _client.rpc('admin_set_city_active', params: {
          'p_city_id': cityId,
          'p_is_active': active,
        });
      }, context: {'city_id': cityId});

  Future<List<FeatureFlag>> flags() => guard('admin.flags', () async {
        final rows = await _client.from('feature_flags').select().order('key');
        return rows.map(FeatureFlag.fromMap).toList();
      });

  Future<void> setFlag(String key, bool enabled) => guard('admin.set_flag', () async {
        await _client.rpc('admin_set_flag', params: {'p_key': key, 'p_enabled': enabled});
      }, context: {'flag': key});

  // ---------------------------------------------------------- staff

  Future<List<StaffMember>> staff() => guard('admin.staff', () async {
        final rows = await _client
            .from('staff_members')
            .select('user_id, role, created_at, profiles(full_name, email, phone)')
            .order('created_at');
        return rows.map(StaffMember.fromRow).toList();
      });

  /// [login] is the account's email or +962 phone.
  Future<void> saveStaff(String login, StaffRole role) => guard('admin.save_staff', () async {
        await _client.rpc('admin_save_staff', params: {'p_login': login, 'p_role': role.name});
      }, context: {'role': role.name});

  Future<void> removeStaff(String userId) => guard('admin.remove_staff', () async {
        await _client.rpc('admin_remove_staff', params: {'p_user_id': userId});
      }, context: {'user_id': userId});

  // ---------------------------------------------------------- audit

  Future<List<AdminAction>> audit({
    String? targetType,
    String? targetId,
    int limit = 50,
    int offset = 0,
  }) =>
      guard('admin.audit', () async {
        var query = _client.from('admin_actions').select();
        if (targetType != null) query = query.eq('target_type', targetType);
        if (targetId != null) query = query.eq('target_id', targetId);
        final rows = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
        return rows.map(AdminAction.fromMap).toList();
      });
}

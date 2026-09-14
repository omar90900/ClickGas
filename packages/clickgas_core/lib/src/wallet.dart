import 'package:supabase_flutter/supabase_flutter.dart';

import 'errors.dart';
import 'logger.dart';

DateTime? _date(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;

double _d(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    };

/// A wallet a distributor can receive with (`wallet_providers`).
class WalletProvider {
  const WalletProvider({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    this.androidPackage,
    this.storeUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String code;
  final String nameAr;
  final String nameEn;

  /// Opens the wallet app from the customer app when set.
  final String? androidPackage;

  /// Where to get the wallet app when it can't be opened directly.
  final String? storeUrl;
  final bool isActive;
  final int sortOrder;

  /// CliQ has no app of its own: it is paid from any bank or wallet app.
  bool get isCliq => code == 'cliq';

  String name(String locale) => locale == 'ar' ? nameAr : nameEn;

  factory WalletProvider.fromMap(Map<String, dynamic> m) => WalletProvider(
        code: m['code'] as String,
        nameAr: m['name_ar'] as String? ?? '',
        nameEn: m['name_en'] as String? ?? '',
        androidPackage: m['android_package'] as String?,
        storeUrl: m['store_url'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      );
}

/// One of a distributor's receiving accounts (`driver_wallets`).
class DriverWallet {
  const DriverWallet({
    required this.id,
    required this.driverId,
    required this.provider,
    required this.accountName,
    this.walletNumber,
    this.cliqAlias,
    this.isActive = true,
    this.termsAcceptedAt,
    this.updatedAt,
  });

  final int id;
  final String driverId;
  final String provider;
  final String accountName;
  final String? walletNumber;
  final String? cliqAlias;
  final bool isActive;
  final DateTime? termsAcceptedAt;
  final DateTime? updatedAt;

  factory DriverWallet.fromMap(Map<String, dynamic> m) => DriverWallet(
        id: (m['id'] as num).toInt(),
        driverId: m['driver_id'] as String,
        provider: m['provider'] as String,
        accountName: m['account_name'] as String? ?? '',
        walletNumber: m['wallet_number'] as String?,
        cliqAlias: m['cliq_alias'] as String?,
        isActive: m['is_active'] as bool? ?? true,
        termsAcceptedAt: _date(m['terms_accepted_at']),
        updatedAt: _date(m['updated_at']),
      );
}

/// Where the customer sends the money: a copy of one distributor account,
/// taken when the distributor got the order.
class WalletPayee {
  const WalletPayee({
    required this.provider,
    required this.accountName,
    this.walletNumber,
    this.cliqAlias,
  });

  final String provider;
  final String accountName;
  final String? walletNumber;
  final String? cliqAlias;

  factory WalletPayee.fromMap(Map<String, dynamic> m) => WalletPayee(
        provider: m['provider'] as String? ?? '',
        accountName: m['account_name'] as String? ?? '',
        walletNumber: m['wallet_number'] as String?,
        cliqAlias: m['cliq_alias'] as String?,
      );
}

/// awaiting -> claimed (customer says paid) -> confirmed (distributor got it);
/// disputed: distributor says it didn't arrive; cash: paid in cash instead.
enum PaymentStatus {
  awaiting,
  claimed,
  confirmed,
  disputed,
  cash;

  static PaymentStatus parse(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => awaiting);

  /// The order can be marked delivered.
  bool get isSettled => this == confirmed || this == cash;
}

/// The wallet payment of one order (`order_payments`).
class OrderPayment {
  const OrderPayment({
    required this.orderId,
    required this.driverId,
    required this.amount,
    required this.payees,
    required this.status,
    this.paidWith,
    this.reference,
    this.note,
    this.claimedAt,
    this.confirmedAt,
    this.disputedAt,
  });

  final String orderId;
  final String driverId;
  final double amount;
  final List<WalletPayee> payees;
  final PaymentStatus status;
  final String? paidWith;
  final String? reference;

  /// Why the distributor said it didn't arrive.
  final String? note;
  final DateTime? claimedAt;
  final DateTime? confirmedAt;
  final DateTime? disputedAt;

  factory OrderPayment.fromMap(Map<String, dynamic> m) => OrderPayment(
        orderId: m['order_id'] as String,
        driverId: m['driver_id'] as String,
        amount: _d(m['amount']),
        payees: [
          for (final p in (m['payees'] as List? ?? const []))
            WalletPayee.fromMap(Map<String, dynamic>.from(p as Map)),
        ],
        status: PaymentStatus.parse(m['status']),
        paidWith: m['paid_with'] as String?,
        reference: m['reference'] as String?,
        note: m['note'] as String?,
        claimedAt: _date(m['claimed_at']),
        confirmedAt: _date(m['confirmed_at']),
        disputedAt: _date(m['disputed_at']),
      );
}

/// Wallet payments for the customer and distributor apps
/// (docs/decisions/0015-wallet-payments.md). The money goes straight from the
/// customer's wallet to the distributor's; this records who said what.
/// Throws only [AppFailure].
class WalletRepository {
  WalletRepository(this._client);

  final SupabaseClient _client;
  List<WalletProvider>? _providers;

  Future<List<WalletProvider>> providers({bool refresh = false}) async {
    if (_providers != null && !refresh) return _providers!;
    return guard('wallet.providers', () async {
      final rows = await _client.from('wallet_providers').select().order('sort_order', ascending: true);
      return _providers = rows.map(WalletProvider.fromMap).toList();
    });
  }

  // ---------------------------------------------------------- distributor

  Future<List<DriverWallet>> myWallets(String driverId) =>
      guard('wallet.mine', () async {
        final rows = await _client
            .from('driver_wallets')
            .select()
            .eq('driver_id', driverId)
            .order('created_at', ascending: true);
        return rows.map(DriverWallet.fromMap).toList();
      });

  /// Needs [acceptTerms]: ClickGas is not liable for wrong details.
  Future<DriverWallet> saveWallet({
    required String provider,
    required String accountName,
    String? walletNumber,
    String? cliqAlias,
    required bool acceptTerms,
  }) =>
      guard('wallet.save', () async {
        final row = await _client.rpc('save_my_wallet', params: {
          'p_provider': provider,
          'p_account_name': accountName,
          'p_wallet_number': walletNumber,
          'p_cliq_alias': cliqAlias,
          'p_accept_terms': acceptTerms,
        });
        Log.i('wallet_saved', {'provider': provider});
        return DriverWallet.fromMap(Map<String, dynamic>.from(row as Map));
      }, context: {'provider': provider});

  Future<void> setWalletActive(String provider, bool active) => guard(
        'wallet.set_active',
        () => _client.rpc('set_my_wallet_active',
            params: {'p_provider': provider, 'p_active': active}),
        context: {'provider': provider, 'active': active},
      );

  Future<void> removeWallet(String provider) => guard(
        'wallet.remove',
        () => _client.rpc('remove_my_wallet', params: {'p_provider': provider}),
        context: {'provider': provider},
      );

  /// Received the wallet payment, or ([inCash]) was paid in cash instead.
  Future<void> confirmPayment(String orderId, {bool inCash = false}) => guard(
        'wallet.confirm',
        () => _client.rpc('confirm_wallet_payment',
            params: {'p_order_id': orderId, 'p_in_cash': inCash}),
        context: {'order_id': orderId, 'in_cash': inCash},
      );

  Future<void> disputePayment(String orderId, String note) => guard(
        'wallet.dispute',
        () => _client.rpc('dispute_wallet_payment',
            params: {'p_order_id': orderId, 'p_note': note}),
        context: {'order_id': orderId},
      );

  // ---------------------------------------------------------- customer

  Future<void> claimPayment(String orderId, {String? provider, String? reference}) =>
      guard(
        'wallet.claim',
        () => _client.rpc('claim_wallet_payment', params: {
          'p_order_id': orderId,
          'p_provider': provider,
          'p_reference': reference,
        }),
        context: {'order_id': orderId},
      );

  // ---------------------------------------------------------- both

  /// Live payment of one order; null until a distributor has it.
  Stream<OrderPayment?> watchPayment(String orderId) => _client
      .from('order_payments')
      .stream(primaryKey: ['order_id'])
      .eq('order_id', orderId)
      .map((rows) => rows.isEmpty ? null : OrderPayment.fromMap(rows.first));
}

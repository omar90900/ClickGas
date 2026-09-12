import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'logger.dart';

/// Stable error codes, shared with the database and documented in
/// docs/errors.md. Database functions raise the same strings, e.g.
/// `raise exception 'ORDER_TOO_FAR' using detail = ...`.
enum FailureCode {
  // ---- auth
  invalidCredentials('INVALID_CREDENTIALS'),
  tooManyAttempts('TOO_MANY_ATTEMPTS'),
  emailNotConfirmed('EMAIL_NOT_CONFIRMED'),
  emailTaken('EMAIL_TAKEN'),
  phoneTaken('PHONE_TAKEN'),
  weakPassword('WEAK_PASSWORD'),
  // ---- orders
  serviceUnavailable('SERVICE_UNAVAILABLE'),
  openOrderExists('OPEN_ORDER_EXISTS'),
  orderNotCancellable('ORDER_NOT_CANCELLABLE'),
  orderNotRateable('ORDER_NOT_RATEABLE'),
  orderNotConfirmable('ORDER_NOT_CONFIRMABLE'),
  invalidRating('INVALID_RATING'),
  invalidTransition('INVALID_TRANSITION'),
  // ---- dispatch
  notVerifiedDriver('NOT_A_VERIFIED_DRIVER'),
  driverOffline('DRIVER_OFFLINE'),
  maxActiveOrders('MAX_ACTIVE_ORDERS'),
  orderNotAvailable('ORDER_NOT_AVAILABLE'),
  notEnoughCylinders('NOT_ENOUGH_CYLINDERS'),
  orderTooFar('ORDER_TOO_FAR'),
  // ---- generic
  permissionDenied('PERMISSION_DENIED'),
  network('NETWORK'),
  unknown('UNKNOWN');

  const FailureCode(this.value);
  final String value;

  /// Finds a code inside a server message such as "ORDER_TOO_FAR".
  static FailureCode? fromMessage(String? message) {
    if (message == null) return null;
    for (final c in values) {
      if (c != unknown && message.contains(c.value)) return c;
    }
    return null;
  }
}

/// The only exception type repositories throw. Screens show a translated
/// message for [code]; [detail] goes to the log for troubleshooting.
class AppFailure implements Exception {
  const AppFailure(this.code, {this.detail, this.cause});

  final FailureCode code;
  final String? detail;
  final Object? cause;

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is SocketException ||
        error is TimeoutException ||
        error is AuthRetryableFetchException) {
      return AppFailure(FailureCode.network, cause: error);
    }
    if (error is AuthException) {
      final code = switch (error.code) {
        'invalid_credentials' => FailureCode.invalidCredentials,
        'email_not_confirmed' => FailureCode.emailNotConfirmed,
        'user_already_exists' || 'email_exists' => FailureCode.emailTaken,
        'weak_password' => FailureCode.weakPassword,
        'over_request_rate_limit' ||
        'over_email_send_rate_limit' =>
          FailureCode.tooManyAttempts,
        _ => FailureCode.unknown,
      };
      return AppFailure(code, detail: error.message, cause: error);
    }
    if (error is PostgrestException) {
      final text = '${error.message} ${error.details ?? ''}';
      final FailureCode code;
      if (error.code == '23505' && text.contains('orders_one_open_per_customer')) {
        code = FailureCode.openOrderExists;
      } else if (error.code == '23505' && text.contains('phone')) {
        code = FailureCode.phoneTaken;
      } else if (error.code == '42501') {
        code = FailureCode.permissionDenied;
      } else {
        code = FailureCode.fromMessage(error.message) ?? FailureCode.unknown;
      }
      final detail = error.details?.toString();
      return AppFailure(
        code,
        detail: (detail == null || detail.isEmpty) ? error.message : detail,
        cause: error,
      );
    }
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup')) {
      return AppFailure(FailureCode.network, cause: error);
    }
    return AppFailure(
      FailureCode.fromMessage(text) ?? FailureCode.unknown,
      detail: text,
      cause: error,
    );
  }

  @override
  String toString() =>
      'AppFailure(${code.value}${detail == null ? '' : ': $detail'})';
}

/// Runs a server call, converts any failure into an [AppFailure] and logs
/// it with the [operation] name, so every failure is traceable.
Future<T> guard<T>(
  String operation,
  Future<T> Function() action, {
  Map<String, Object?> context = const {},
}) async {
  try {
    return await action();
  } catch (error, stack) {
    final failure = AppFailure.from(error);
    final data = {
      'op': operation,
      'code': failure.code.value,
      if (failure.detail != null) 'detail': failure.detail,
      ...context,
    };
    if (failure.code == FailureCode.unknown) {
      Log.e('failure', data, error, stack);
    } else {
      Log.w('failure', data);
    }
    throw failure;
  }
}

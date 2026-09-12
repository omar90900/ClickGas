import 'dart:collection';

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warn, error }

class LogEntry {
  LogEntry(this.level, this.event, this.data) : at = DateTime.now().toUtc();

  final DateTime at;
  final LogLevel level;
  final String event;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {
        'at': at.toIso8601String(),
        'level': level.name,
        'event': event,
        if (data.isNotEmpty) 'data': data,
      };

  @override
  String toString() =>
      '${at.toIso8601String()} ${level.name.toUpperCase()} $event ${data.isEmpty ? '' : data}';
}

/// Structured, in-memory log shared by every app.
///
/// Keeps the last [capacity] entries so "Send diagnostics" can upload them.
/// Rules (docs/architecture.md#logging): log events with an order number or
/// error code where possible; never log passwords, tokens or full addresses.
class Log {
  static const capacity = 300;
  static final _buffer = ListQueue<LogEntry>(capacity);

  /// Which app is writing ("customer", "distributor", "admin").
  static String app = 'unknown';

  static void d(String event, [Map<String, Object?> data = const {}]) =>
      _add(LogLevel.debug, event, data);
  static void i(String event, [Map<String, Object?> data = const {}]) =>
      _add(LogLevel.info, event, data);
  static void w(String event, [Map<String, Object?> data = const {}]) =>
      _add(LogLevel.warn, event, data);

  static void e(
    String event, [
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stack,
  ]) =>
      _add(LogLevel.error, event, {
        ...data,
        if (error != null) 'error': error.toString(),
        if (stack != null) 'stack': _shortStack(stack),
      });

  /// Oldest first, ready to upload as JSON.
  static List<Map<String, Object?>> snapshot() =>
      _buffer.map((e) => e.toJson()).toList(growable: false);

  static void clear() => _buffer.clear();

  /// Routes uncaught Flutter and platform errors into the log.
  static void install({required String app}) {
    Log.app = app;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      e('flutter_error', {'library': details.library}, details.exception,
          details.stack);
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      e('uncaught_error', const {}, error, stack);
      return true;
    };
    i('app_start', {'app': app});
  }

  static void _add(LogLevel level, String event, Map<String, Object?> data) {
    final entry = LogEntry(level, event, data);
    if (_buffer.length >= capacity) _buffer.removeFirst();
    _buffer.addLast(entry);
    if (kDebugMode) debugPrint('[clickgas] $entry');
  }

  static String _shortStack(StackTrace stack) =>
      stack.toString().split('\n').take(8).join('\n');
}

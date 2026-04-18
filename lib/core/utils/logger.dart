// lib/core/utils/logger.dart

import 'package:flutter/foundation.dart';

import 'package:briluxforge/services/local_logger_service.dart';

enum LogLevel { debug, info, warning, error }

/// Structured logger that writes to both [debugPrint] and the local log file
/// managed by [LocalLoggerService].
///
/// All four severity levels ([d], [i], [w], [e]) are active in debug builds.
/// In release builds the minimum level is [LogLevel.warning].
///
/// **Security rule**: never pass raw API keys, passwords, or prompt content
/// to any logger method. The [ApiClientService] sanitizes errors before they
/// reach here, but callers must also apply due diligence.
abstract final class AppLogger {
  static LogLevel minimumLevel =
      kDebugMode ? LogLevel.debug : LogLevel.warning;

  // ── Severity shortcuts ─────────────────────────────────────────────────────

  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void w(String tag, String message) =>
      _log(LogLevel.warning, tag, message);

  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) {
    _log(LogLevel.error, tag, message);
    if (error != null) _log(LogLevel.error, tag, 'Error: $error');
    if (stack != null) _log(LogLevel.error, tag, 'Stack: $stack');
  }

  // ── Core sink ─────────────────────────────────────────────────────────────

  static void _log(LogLevel level, String tag, String message) {
    if (level.index < minimumLevel.index) return;

    final String timestamp = DateTime.now().toIso8601String();
    final String prefix = '[${level.name.toUpperCase()}][$tag]';
    final String line = '$timestamp $prefix $message';

    // Always write to the Flutter console (visible in debug + profile builds).
    debugPrint(line);

    // Also persist to the local log file when the service is initialized.
    // [LocalLoggerService.instance] is null until [initialize()] completes,
    // so early startup logs go to the console only — that is acceptable.
    LocalLoggerService.instance?.append(line);
  }
}

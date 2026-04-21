// lib/services/local_logger_service.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Writes structured log lines to a local flat file in the application
/// documents directory. Every log entry is appended synchronously so that
/// no data is lost on an unexpected crash.
///
/// **Initialization**: call [initialize] once at app startup (before the
/// first frame) and await it. Until that completes, [AppLogger] falls back
/// gracefully to [debugPrint] only — no data is lost.
///
/// **Privacy**: this logger must NEVER receive raw API keys or prompt
/// content. It is wired exclusively to [AppLogger], which already enforces
/// the redaction rules defined in Section 7.3 of CLAUDE.md.
class LocalLoggerService {
  LocalLoggerService._(this._file);

  // ── Constants ──────────────────────────────────────────────────────────────

  static const String kLogFileName = 'briluxforge_debug.log';

  /// Maximum log file size in bytes before the file is rotated (2 MB).
  static const int _maxFileSizeBytes = 2 * 1024 * 1024;

  // ── Singleton state ────────────────────────────────────────────────────────

  static LocalLoggerService? _instance;

  final File _file;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// The initialized singleton, or [null] if [initialize] has not been
  /// called yet.
  static LocalLoggerService? get instance => _instance;

  /// Absolute path of the log file, or [null] if not initialized.
  static String? get logFilePath => _instance?._file.path;

  /// Initializes the singleton by resolving the documents directory and
  /// opening (or creating) the log file. Subsequent calls are no-ops.
  static Future<void> initialize() async {
    if (_instance != null) return;
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File('${dir.path}/$kLogFileName');
      _instance = LocalLoggerService._(file);
      _instance!._writeSessionHeader();
    } catch (e) {
      // If path_provider fails (rare on desktop), continue with console-only
      // logging. The app must not crash because a log file can't be opened.
      debugPrint('[LocalLoggerService] Initialization failed: $e');
    }
  }

  /// Appends [line] (with a trailing newline) to the log file.
  ///
  /// Silently swallows write errors — the app must never crash because of
  /// a logging failure.
  void append(String line) {
    try {
      // Rotate if the file has grown past the size limit.
      if (_file.existsSync() &&
          _file.lengthSync() > _maxFileSizeBytes) {
        _rotate();
      }
      _file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Intentionally swallowed.
    }
  }

  /// Deletes the current log file. Useful from a "Clear logs" settings
  /// action or in integration tests.
  Future<void> clear() async {
    try {
      if (_file.existsSync()) await _file.delete();
    } catch (_) {}
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Writes a session boundary marker so that separate app launches are
  /// clearly delineated in the log file.
  void _writeSessionHeader() {
    final String separator = '─' * 60;
    final String ts = DateTime.now().toIso8601String();
    append('\n$separator');
    append('SESSION START  $ts');
    append(separator);
  }

  /// Renames the existing log file to `briluxforge_debug.log.bak`, then
  /// the next [append] call will create a fresh log file. Only one backup
  /// is kept at a time.
  void _rotate() {
    try {
      final File backup = File('${_file.path}.bak');
      if (backup.existsSync()) backup.deleteSync();
      _file.renameSync(backup.path);
    } catch (_) {}
  }
}

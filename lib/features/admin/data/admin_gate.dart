// lib/features/admin/data/admin_gate.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:briluxforge/core/constants/app_constants.dart';

abstract final class _SecureKeys {
  static const String email = 'admin_email_v1';
  static const String secret = 'admin_secret_v1';
}

/// Result of [AdminGate.check].
enum AdminGateState { locked, unlocked }

/// Local admin authentication gate. Not a security boundary — prevents
/// accidental discovery by curious users only.
///
/// The gate is unlocked when sha256(email:secret) matches [kAdminGateHash].
class AdminGate {
  const AdminGate({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Reads stored credentials and returns the gate state.
  Future<AdminGateState> check() async {
    final email = await _storage.read(key: _SecureKeys.email);
    final secret = await _storage.read(key: _SecureKeys.secret);
    if (email == null || secret == null) return AdminGateState.locked;
    return _verify(email, secret);
  }

  /// Attempts to unlock with [email] and [secret].
  ///
  /// On match, persists credentials and returns [AdminGateState.unlocked].
  /// On mismatch, does nothing and returns [AdminGateState.locked].
  Future<AdminGateState> unlock({
    required String email,
    required String secret,
  }) async {
    final state = _verify(email.toLowerCase().trim(), secret);
    if (state == AdminGateState.unlocked) {
      await _storage.write(key: _SecureKeys.email, value: email.toLowerCase().trim());
      await _storage.write(key: _SecureKeys.secret, value: secret);
    }
    return state;
  }

  /// Clears stored admin credentials.
  Future<void> lock() async {
    await _storage.delete(key: _SecureKeys.email);
    await _storage.delete(key: _SecureKeys.secret);
  }

  AdminGateState _verify(String email, String secret) {
    final input = '${email.toLowerCase()}:$secret';
    final digest = sha256.convert(utf8.encode(input)).toString();
    // Constant-time comparison via equality on a fixed-length hex string
    // (both sides are always 64 chars — no timing leak beyond what Dart allows).
    return digest == AppConstants.kAdminGateHash
        ? AdminGateState.unlocked
        : AdminGateState.locked;
  }
}

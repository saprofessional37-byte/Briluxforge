// lib/features/updater/data/signing/ed25519_verifier.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §6.7

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/updater/data/update_constants.dart';

/// Stateless Ed25519 signature verifier.
///
/// The production-facing [verify] method is locked to [kUpdatePublicKeyBase64].
/// A [visibleForTesting] overload [verifyWithKey] accepts explicit public-key
/// bytes, enabling deterministic unit tests with test-only key pairs that are
/// never present in production code paths.
///
/// Per the SIGNED-OR-DIE LAW (§1.2): any exception during verification is
/// caught, logged at error level, and the method returns false. There is no
/// path through this class that returns true without a successful cryptographic
/// verification against the correct public key.
class Ed25519Verifier {
  const Ed25519Verifier._();

  static final _algorithm = Ed25519();

  /// Returns true iff [signature] is a valid Ed25519 signature over [message]
  /// under the app's bundled public key ([kUpdatePublicKeyBase64]).
  ///
  /// Never throws. Any internal exception is caught, logged, and treated as
  /// verification failure — per SIGNED-OR-DIE LAW.
  static Future<bool> verify({
    required List<int> message,
    required List<int> signature,
  }) {
    final List<int> keyBytes;
    try {
      keyBytes = base64.decode(kUpdatePublicKeyBase64);
    } catch (e, st) {
      AppLogger.e('[Updater]', 'Bundled public key is not valid base64.', e, st);
      return Future.value(false);
    }
    return verifyWithKey(
      message: message,
      signature: signature,
      publicKeyBytes: keyBytes,
    );
  }

  /// Verify [signature] over [message] using explicit [publicKeyBytes].
  ///
  /// Only exposed for deterministic unit tests. All production callers must
  /// use [verify] so the bundled key is always the verification authority.
  @visibleForTesting
  static Future<bool> verifyWithKey({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKeyBytes,
  }) async {
    try {
      if (signature.length != 64) {
        AppLogger.e(
          '[Updater]',
          'Signature has wrong length: ${signature.length} bytes (expected 64). '
          'Treating as verification failure.',
        );
        return false;
      }
      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );
      final sig = Signature(signature, publicKey: publicKey);
      return await _algorithm.verify(message, signature: sig);
    } catch (e, st) {
      AppLogger.e('[Updater]', 'Ed25519 verification threw an exception.', e, st);
      return false;
    }
  }
}

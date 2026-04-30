// test/features/updater/signature_verify_test.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §13.1

import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:briluxforge/features/updater/data/signing/ed25519_verifier.dart';

void main() {
  group('Ed25519Verifier', () {
    // A test-only key pair generated once per test run.
    // Distinct from the production key per §13.1 fixture requirements.
    late List<int> testPublicKeyBytes;
    late List<int> manifestBytes;
    late List<int> validSignature;

    setUpAll(() async {
      final algorithm = Ed25519();

      // Generate a fresh test key pair (never the production key).
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      testPublicKeyBytes = publicKey.bytes;

      // The canonical fixture manifest is the message for all signing tests.
      manifestBytes = await File(
        'test/fixtures/updater/manifest_v1_valid.json',
      ).readAsBytes();

      // Sign the fixture with the test private key.
      final sig = await algorithm.sign(manifestBytes, keyPair: keyPair);
      validSignature = sig.bytes;
    });

    // ── Test 1: known-good signature passes ─────────────────────────────────
    test('known-good signature over fixture manifest is accepted', () async {
      final result = await Ed25519Verifier.verifyWithKey(
        message: manifestBytes,
        signature: validSignature,
        publicKeyBytes: testPublicKeyBytes,
      );
      expect(result, isTrue);
    });

    // ── Test 2: tampered message is rejected ─────────────────────────────────
    test('single-byte message flip causes signature failure', () async {
      final tampered = List<int>.from(manifestBytes);
      tampered[0] = tampered[0] ^ 0xFF;

      final result = await Ed25519Verifier.verifyWithKey(
        message: tampered,
        signature: validSignature,
        publicKeyBytes: testPublicKeyBytes,
      );
      expect(result, isFalse);
    });

    // ── Test 3: tampered signature is rejected ────────────────────────────────
    test('single-byte signature flip causes signature failure', () async {
      final tampered = List<int>.from(validSignature);
      tampered[0] = tampered[0] ^ 0xFF;

      final result = await Ed25519Verifier.verifyWithKey(
        message: manifestBytes,
        signature: tampered,
        publicKeyBytes: testPublicKeyBytes,
      );
      expect(result, isFalse);
    });

    // ── Test 4: wrong-length (32-byte) signature is rejected without throwing ─
    test('wrong-length 32-byte signature returns false, does not throw',
        () async {
      final shortSig = List<int>.filled(32, 0xAB);

      final result = await Ed25519Verifier.verifyWithKey(
        message: manifestBytes,
        signature: shortSig,
        publicKeyBytes: testPublicKeyBytes,
      );
      expect(result, isFalse);
    });

    // ── Test 5: empty signature is rejected without throwing ──────────────────
    test('empty signature returns false, does not throw', () async {
      final result = await Ed25519Verifier.verifyWithKey(
        message: manifestBytes,
        signature: [],
        publicKeyBytes: testPublicKeyBytes,
      );
      expect(result, isFalse);
    });

    // ── Test 6: signature from a different key pair is rejected ───────────────
    test('signature created under a different key pair is rejected', () async {
      final algorithm = Ed25519();
      final differentKeyPair = await algorithm.newKeyPair();
      final wrongSig =
          await algorithm.sign(manifestBytes, keyPair: differentKeyPair);

      final result = await Ed25519Verifier.verifyWithKey(
        message: manifestBytes,
        signature: wrongSig.bytes,
        publicKeyBytes: testPublicKeyBytes,
      );
      expect(result, isFalse);
    });
  });
}

// tools/generate_keys.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §11.4
//
// One-time Ed25519 key-pair generator for the Briluxforge OTA signing system.
//
// Run ONCE from the project root:
//   dart run tools/generate_keys.dart
//
// Copy the PUBLIC key into:
//   lib/features/updater/data/update_constants.dart → kUpdatePublicKeyBase64
//
// Store the PRIVATE key in GitHub Secret: UPDATE_SIGNING_PRIVATE_KEY
//
// ⚠  DELETE the private key from local disk immediately after storing it.
// ⚠  DO NOT commit the private key to git under any circumstances.
// ⚠  Rotating the key requires shipping a new binary (BUNDLED-KEY LAW §1.2).

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main() async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPair();
  final publicKey = await keyPair.extractPublicKey();
  final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

  final publicBase64 = base64.encode(publicKey.bytes);
  final privateBase64 = base64.encode(privateKeyBytes);

  final separator = '─' * 70;
  stdout.writeln(separator);
  stdout.writeln(
    'Briluxforge Ed25519 Key Pair — ${DateTime.now().toIso8601String()}',
  );
  stdout.writeln(separator);
  stdout.writeln();
  stdout.writeln(
    'PUBLIC  (embed in lib/features/updater/data/update_constants.dart):',
  );
  stdout.writeln(publicBase64);
  stdout.writeln();
  stdout.writeln(
    'PRIVATE (store in GitHub Secret UPDATE_SIGNING_PRIVATE_KEY):',
  );
  stdout.writeln(privateBase64);
  stdout.writeln();
  stdout.writeln(separator);
  stdout.writeln('⚠  DO NOT commit the private key to git.');
  stdout.writeln('⚠  DO NOT back it up to cloud storage.');
  stdout.writeln('⚠  Rotating the key requires shipping a new binary.');
  stdout.writeln(separator);

  exitCode = 0;
}

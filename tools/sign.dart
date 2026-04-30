// tools/sign.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §11.3
//
// CI signing helper. Reads the Ed25519 private key from the environment
// variable UPDATE_SIGNING_PRIVATE_KEY, signs the given file, and prints
// the base64-encoded detached signature to stdout.
//
// Usage (in GitHub Actions):
//   dart run tools/sign.dart <path-to-file>
//
// Stdout: base64-encoded 64-byte Ed25519 signature (single line, no newline)
// Exit 0 on success, non-zero on any error.
//
// The caller is responsible for writing the output to a .sig file alongside
// the signed artifact, e.g.:
//   dart run tools/sign.dart manifest.json > manifest.json.sig

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tools/sign.dart <file>');
    exitCode = 1;
    return;
  }

  final privateKeyB64 = Platform.environment['UPDATE_SIGNING_PRIVATE_KEY'];
  if (privateKeyB64 == null || privateKeyB64.trim().isEmpty) {
    stderr.writeln(
      'ERROR: Environment variable UPDATE_SIGNING_PRIVATE_KEY is not set.',
    );
    exitCode = 1;
    return;
  }

  final inputFile = File(args[0]);
  if (!inputFile.existsSync()) {
    stderr.writeln('ERROR: File not found: ${args[0]}');
    exitCode = 1;
    return;
  }

  try {
    final privateKeyBytes = base64.decode(privateKeyB64.trim());
    if (privateKeyBytes.length != 32) {
      stderr.writeln(
        'ERROR: Private key must be 32 bytes when decoded. '
        'Got ${privateKeyBytes.length} bytes.',
      );
      exitCode = 1;
      return;
    }

    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
    final messageBytes = await inputFile.readAsBytes();
    final signature = await algorithm.sign(messageBytes, keyPair: keyPair);

    // Print base64 signature without a trailing newline so the caller can
    // write it directly to a .sig file without trimming.
    stdout.write(base64.encode(signature.bytes));
    exitCode = 0;
  } on FormatException catch (e) {
    stderr.writeln('ERROR: Private key is not valid base64: $e');
    exitCode = 1;
  } catch (e) {
    stderr.writeln('ERROR: Signing failed: $e');
    exitCode = 1;
  }
}

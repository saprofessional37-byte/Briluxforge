// tools/brain_editor/lib/brain_signer.dart
// Ed25519 signer for brain payloads. Requires package:cryptography.
// The CLI invokes this; it is never imported from lib/.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

/// Thrown when signing fails for any reason.
class BrainSigningException implements Exception {
  const BrainSigningException(this.message);
  final String message;

  @override
  String toString() => 'BrainSigningException: $message';
}

class BrainSigner {
  const BrainSigner();

  /// Signs [payload] with the Ed25519 private key at [keyFile].
  ///
  /// Produces `<payload>.sig` containing the base64-encoded 64-byte signature.
  /// Zeroes the key buffer before returning.
  /// Throws [BrainSigningException] on any error.
  Future<File> sign({
    required File payload,
    required File keyFile,
  }) async {
    // Read and validate the key.
    if (!keyFile.existsSync()) {
      throw const BrainSigningException('Key file does not exist.');
    }
    final keyBytes = keyFile.readAsBytesSync();
    if (keyBytes.length != 32) {
      throw BrainSigningException(
          'Key file must be exactly 32 bytes, got ${keyBytes.length}.');
    }

    // Read payload bytes.
    if (!payload.existsSync()) {
      throw const BrainSigningException('Payload file does not exist.');
    }
    final payloadBytes = payload.readAsBytesSync();

    // Sign.
    try {
      final algorithm = Ed25519();
      final keyPair =
          await algorithm.newKeyPairFromSeed(keyBytes);
      final signature = await algorithm.sign(payloadBytes, keyPair: keyPair);
      final sigBase64 = base64.encode(signature.bytes);

      // Write signature file.
      final sigFile = File('${payload.path}.sig');
      sigFile.writeAsStringSync(sigBase64);

      return sigFile;
    } catch (e) {
      throw BrainSigningException('Signing failed: $e');
    } finally {
      // Zero key material in memory.
      keyBytes.fillRange(0, keyBytes.length, 0);
    }
  }
}

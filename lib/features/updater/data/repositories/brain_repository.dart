// lib/features/updater/data/repositories/brain_repository.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §7.1

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/updater/data/models/brain_update_info.dart';
import 'package:briluxforge/features/updater/data/repositories/allow_listed_client.dart';
import 'package:briluxforge/features/updater/data/signing/ed25519_verifier.dart';
import 'package:briluxforge/core/errors/app_exception.dart';

/// Fetches, verifies, and atomically persists the Smart Brain payload.
///
/// The brain payload is pure configuration JSON (< 50 KB per §3.1) and is
/// safe to buffer in memory — the §6.6 streaming requirement applies only to
/// the large binary artifact. SHA-256 and Ed25519 are both checked before any
/// bytes are written to disk (SIGNED-OR-DIE LAW §1.2).
///
/// ## Atomic write contract
/// The payload is first written to `<targetFile>.tmp`, then renamed over
/// `<targetFile>`. The running app never sees a half-written brain file.
///
/// ## Brain path precedence (§7.2)
/// Callers are responsible for supplying the correct [targetFile]. The
/// [UpdaterService] (Phase 11.6) enforces the precedence logic:
///   1. `<appSupportDir>/Briluxforge/brain/current.json` if present + parseable.
///   2. Bundled `assets/brain/model_profiles.json` as fallback.
class BrainRepository {
  BrainRepository({
    http.Client? httpClient,
    VerifyFn? verifySignature,
    String? userAgent,
  })  : _httpClient = httpClient ?? buildUpdaterClient(),
        _verifySignature = verifySignature ?? Ed25519Verifier.verify,
        _userAgent = userAgent ?? kUpdaterUserAgent;

  static const Duration _kFetchTimeout = Duration(seconds: 30);

  final http.Client _httpClient;
  final VerifyFn _verifySignature;
  final String _userAgent;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Fetches the brain payload described by [brainInfo], verifies it, and
  /// atomically writes it to [targetFile].
  ///
  /// Returns the brain [BrainUpdateInfo.version] on success.
  ///
  /// Throws:
  /// - [ManifestFetchException] on network / HTTP failure.
  /// - [ArtifactVerificationException] on SHA-256 or Ed25519 failure.
  /// - [StagingException] on file I/O failure after successful verification.
  Future<int> fetchAndApply({
    required BrainUpdateInfo brainInfo,
    required File targetFile,
  }) async {
    AppLogger.d(
      '[Brain]',
      'Fetching brain v${brainInfo.version} from ${brainInfo.url}.',
    );

    // ── 1. Fetch payload ──────────────────────────────────────────────────────
    final List<int> bytes = await _fetchPayload(brainInfo);

    // ── 2. Size check (soft) ──────────────────────────────────────────────────
    // A mismatch is logged but does not abort — SHA-256 is the authoritative
    // integrity check. A corrupt partial transfer will fail SHA-256.
    if (bytes.length != brainInfo.sizeBytes) {
      AppLogger.w(
        '[Brain]',
        'Size mismatch for brain v${brainInfo.version}: '
        'expected ${brainInfo.sizeBytes} bytes, got ${bytes.length}.',
      );
    }

    // ── 3. SHA-256 verification ───────────────────────────────────────────────
    final String digestHex = sha256.convert(bytes).toString();
    if (digestHex != brainInfo.sha256) {
      AppLogger.e(
        '[Brain]',
        'SHA-256 mismatch for brain v${brainInfo.version}. '
        'Expected: ${brainInfo.sha256}. Got: $digestHex. Discarding.',
      );
      throw ArtifactVerificationException(
        message: 'The model profile update failed integrity verification.',
        technicalDetail: 'SHA-256 mismatch for brain v${brainInfo.version}.',
      );
    }
    AppLogger.d('[Brain]', 'SHA-256 passed for v${brainInfo.version}.');

    // ── 4. Ed25519 verification — SIGNED-OR-DIE LAW ───────────────────────────
    final List<int> signatureBytes;
    try {
      signatureBytes = base64.decode(brainInfo.ed25519Signature);
    } catch (e) {
      AppLogger.e(
        '[Brain]',
        'Brain v${brainInfo.version} Ed25519 signature is not valid base64. '
        'Discarding.',
        e,
      );
      throw ArtifactVerificationException(
        message: 'The model profile update has an invalid signature format.',
        technicalDetail:
            'Brain Ed25519 signature is not valid base64: ${e.toString()}',
      );
    }

    final bool valid = await _verifySignature(
      message: bytes,
      signature: signatureBytes,
    );
    if (!valid) {
      AppLogger.e(
        '[Brain]',
        'Ed25519 verification FAILED for brain v${brainInfo.version}. '
        'Discarding.',
      );
      throw ArtifactVerificationException(
        message: 'The model profile update failed security verification.',
        technicalDetail:
            'Ed25519 signature did not verify for brain v${brainInfo.version}.',
      );
    }
    AppLogger.d('[Brain]', 'Ed25519 passed for v${brainInfo.version}.');

    // ── 5. Atomic write ───────────────────────────────────────────────────────
    // Write to <targetFile>.tmp first, then rename over targetFile.
    // This guarantees the running app never observes a partial write.
    final File tmpFile = File('${targetFile.path}.tmp');
    try {
      await targetFile.parent.create(recursive: true);
      await tmpFile.writeAsBytes(bytes, flush: true);
      await tmpFile.rename(targetFile.path);
    } catch (e, st) {
      // Best-effort cleanup of the tmp file.
      try {
        if (tmpFile.existsSync()) await tmpFile.delete();
      } catch (_) {}
      AppLogger.e(
        '[Brain]',
        'Failed to persist brain v${brainInfo.version}.',
        e,
        st,
      );
      throw StagingException(
        message: 'Could not save the model profile update.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    AppLogger.i(
      '[Brain]',
      'Brain v${brainInfo.version} written to ${targetFile.path}.',
    );
    return brainInfo.version;
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<List<int>> _fetchPayload(BrainUpdateInfo brainInfo) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse(brainInfo.url),
            headers: {
              'User-Agent': _userAgent,
              'Accept': 'application/json',
            },
          )
          .timeout(_kFetchTimeout);

      if (response.statusCode != 200) {
        AppLogger.w(
          '[Brain]',
          'HTTP ${response.statusCode} fetching brain v${brainInfo.version}.',
        );
        throw ManifestFetchException(
          message: 'Could not download the model profile update.',
          technicalDetail:
              'HTTP ${response.statusCode} from ${brainInfo.url}.',
        );
      }
      return response.bodyBytes;
    } on ManifestFetchException {
      rethrow;
    } on TimeoutException catch (e) {
      AppLogger.w('[Brain]', 'Timeout fetching brain v${brainInfo.version}: $e');
      throw ManifestFetchException(
        message: 'Timed out reaching the update server.',
        technicalDetail: e.toString(),
      );
    } on SocketException catch (e) {
      AppLogger.w('[Brain]', 'Network error fetching brain v${brainInfo.version}: $e');
      throw ManifestFetchException(
        message: 'Could not reach the update server.',
        technicalDetail: e.toString(),
      );
    } catch (e, st) {
      AppLogger.w('[Brain]', 'Unexpected error fetching brain v${brainInfo.version}: $e');
      throw ManifestFetchException(
        message: 'Could not reach the update server.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }
  }
}

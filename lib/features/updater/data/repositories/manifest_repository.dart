// lib/features/updater/data/repositories/manifest_repository.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §11.4 (Phase 11.4 deliverable)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/updater/data/models/update_manifest.dart';
import 'package:briluxforge/features/updater/data/repositories/allow_listed_client.dart';
import 'package:briluxforge/features/updater/data/signing/ed25519_verifier.dart';
import 'package:briluxforge/features/updater/data/update_constants.dart';
import 'package:briluxforge/core/errors/app_exception.dart';

/// Fetches and cryptographically verifies the remote update manifest.
///
/// Verification order (§4.2):
///   1. Fetch manifest bytes over HTTPS.
///   2. Fetch detached Ed25519 signature.
///   3. Verify signature — SIGNED-OR-DIE LAW (§1.2).
///   4. Parse JSON only after successful verification.
///   5. Reject unknown `manifest_version` values — FAIL-CLOSED (§4.1).
///
/// All constructor parameters are injectable for testing. Production callers
/// use the zero-argument constructor which applies production defaults.
class ManifestRepository {
  ManifestRepository({
    String? manifestUrl,
    String? signatureUrl,
    http.Client? httpClient,
    VerifyFn? verifySignature,
    String? userAgent,
  })  : _manifestUrl = manifestUrl ?? kUpdateManifestUrl,
        _signatureUrl = signatureUrl ?? kUpdateManifestSignatureUrl,
        _httpClient = httpClient ?? buildUpdaterClient(),
        _verifySignature = verifySignature ?? Ed25519Verifier.verify,
        _userAgent = userAgent ?? kUpdaterUserAgent;

  /// The only manifest schema version this binary understands.
  static const int _kSupportedManifestVersion = 1;

  /// Timeout for manifest and signature HTTP fetches.
  static const Duration _kFetchTimeout = Duration(seconds: 30);

  final String _manifestUrl;
  final String _signatureUrl;
  final http.Client _httpClient;
  final VerifyFn _verifySignature;
  final String _userAgent;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Fetches, verifies, and returns the parsed [UpdateManifest].
  ///
  /// Throws:
  /// - [ManifestFetchException] on network error, timeout, or non-200 HTTP.
  /// - [ManifestSignatureException] on Ed25519 verification failure.
  /// - [ManifestSchemaException] on unknown schema version or malformed JSON.
  Future<UpdateManifest> fetchAndVerify() async {
    AppLogger.d('[Updater]', 'Starting manifest check.');

    // ── 1. Fetch manifest bytes ───────────────────────────────────────────────
    final List<int> manifestBytes =
        await _fetchBytes(_manifestUrl, 'manifest');

    // ── 2. Fetch detached signature ───────────────────────────────────────────
    final List<int> sigFileBytes =
        await _fetchBytes(_signatureUrl, 'manifest signature');

    // ── 3. Decode signature from base64 ──────────────────────────────────────
    final List<int> signatureBytes;
    try {
      signatureBytes = base64.decode(utf8.decode(sigFileBytes).trim());
    } catch (e) {
      AppLogger.e(
        '[Updater]',
        'Manifest signature is not valid base64. Discarding manifest.',
        e,
      );
      throw ManifestSignatureException(
        message: 'The update manifest has an invalid signature format.',
        technicalDetail: e.toString(),
      );
    }

    // ── 4. Ed25519 verify — SIGNED-OR-DIE LAW ────────────────────────────────
    // Manifest bytes are discarded (never parsed) if verification fails.
    final bool valid = await _verifySignature(
      message: manifestBytes,
      signature: signatureBytes,
    );
    if (!valid) {
      AppLogger.e(
        '[Updater]',
        'Manifest Ed25519 verification FAILED. Manifest discarded.',
      );
      throw const ManifestSignatureException(
        message: 'The update manifest failed security verification.',
        technicalDetail:
            'Ed25519 signature did not verify against the bundled public key.',
      );
    }
    AppLogger.d('[Updater]', 'Manifest signature verified.');

    // ── 5. Parse JSON ─────────────────────────────────────────────────────────
    final Map<String, Object?> json;
    try {
      json = jsonDecode(utf8.decode(manifestBytes)) as Map<String, Object?>;
    } on FormatException catch (e) {
      AppLogger.e('[Updater]', 'Manifest JSON is malformed.', e);
      throw ManifestSchemaException(
        message: 'The update manifest could not be read.',
        technicalDetail: e.toString(),
      );
    } catch (e, st) {
      AppLogger.e('[Updater]', 'Unexpected error parsing manifest JSON.', e, st);
      throw ManifestSchemaException(
        message: 'The update manifest could not be read.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    // ── 6. Schema version guard — FAIL-CLOSED (§4.1) ─────────────────────────
    final int? schemaVersion = json['manifest_version'] as int?;
    if (schemaVersion != _kSupportedManifestVersion) {
      AppLogger.w(
        '[Updater]',
        'Unknown manifest_version: $schemaVersion. '
        'This binary understands only v$_kSupportedManifestVersion. '
        'Aborting check cycle.',
      );
      throw ManifestSchemaException(
        message: 'The update manifest uses an unrecognised schema version.',
        technicalDetail: 'manifest_version=$schemaVersion; '
            'supported=$_kSupportedManifestVersion.',
      );
    }

    // ── 7. Deserialise ────────────────────────────────────────────────────────
    try {
      final manifest = UpdateManifest.fromJson(json);
      AppLogger.i(
        '[Updater]',
        'Manifest verified — binary=${manifest.binary?.version}, '
        'brain=${manifest.brain?.version}.',
      );
      return manifest;
    } catch (e, st) {
      AppLogger.e('[Updater]', 'Failed to deserialise manifest.', e, st);
      throw ManifestSchemaException(
        message: 'The update manifest has an unexpected structure.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Fetches [url] and returns the raw response bytes.
  ///
  /// Throws [ManifestFetchException] for any non-200 response, timeout, or
  /// network failure. Callers are responsible for further interpretation.
  Future<List<int>> _fetchBytes(String url, String label) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': _userAgent,
              'Accept': 'application/json, application/octet-stream, text/plain',
            },
          )
          .timeout(_kFetchTimeout);

      if (response.statusCode != 200) {
        AppLogger.w(
          '[Updater]',
          'HTTP ${response.statusCode} fetching $label.',
        );
        throw ManifestFetchException(
          message: 'Could not download the update $label.',
          technicalDetail: 'HTTP ${response.statusCode} from $url.',
        );
      }
      return response.bodyBytes;
    } on ManifestFetchException {
      rethrow;
    } on TimeoutException catch (e) {
      AppLogger.w('[Updater]', 'Timeout fetching $label: $e');
      throw ManifestFetchException(
        message: 'Timed out reaching the update server.',
        technicalDetail: e.toString(),
      );
    } on SocketException catch (e) {
      AppLogger.w('[Updater]', 'Network error fetching $label: $e');
      throw ManifestFetchException(
        message: 'Could not reach the update server.',
        technicalDetail: e.toString(),
      );
    } catch (e, st) {
      AppLogger.w('[Updater]', 'Unexpected error fetching $label: $e');
      throw ManifestFetchException(
        message: 'Could not reach the update server.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }
  }
}

// lib/features/updater/data/repositories/binary_download_repository.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §6.6

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/updater/data/models/update_artifact.dart';
import 'package:briluxforge/features/updater/data/repositories/allow_listed_client.dart';
import 'package:briluxforge/features/updater/data/signing/ed25519_verifier.dart';
import 'package:briluxforge/core/errors/app_exception.dart';

// ── Value types ───────────────────────────────────────────────────────────────

/// Snapshot of download progress emitted by [BinaryDownloadRepository.download].
///
/// Throttled to at most one event per 100 ms (§6.6). The final event always
/// has [isComplete] == true regardless of the throttle window.
@immutable
class DownloadProgress {
  const DownloadProgress({
    required this.bytesReceived,
    required this.bytesTotal,
    required this.isComplete,
  });

  final int bytesReceived;
  final int bytesTotal;

  /// Whether this is the terminal event for a successful download + stage.
  final bool isComplete;

  /// Fractional progress in [0.0, 1.0]. Zero when total size is unknown.
  double get fraction =>
      bytesTotal == 0 ? 0.0 : (bytesReceived / bytesTotal).clamp(0.0, 1.0);
}

/// Describes a payload that has been verified and moved to the pending dir.
@immutable
class StagedPayload {
  const StagedPayload({
    required this.version,
    required this.payloadFile,
    required this.sha256,
    required this.stagedAt,
  });

  final String version;
  final File payloadFile;
  final String sha256;
  final DateTime stagedAt;
}

// ── Private SHA-256 accumulator ───────────────────────────────────────────────

/// Minimal [Sink<Digest>] that stores the single [Digest] produced when a
/// [Hash.startChunkedConversion] sink is closed.
class _DigestSink implements Sink<Digest> {
  Digest? _value;

  /// The computed digest. Null until [close] has been called on the
  /// corresponding [ByteConversionSink].
  Digest get value => _value!;

  @override
  void add(Digest data) => _value = data;

  @override
  void close() {}
}

// ── Repository ────────────────────────────────────────────────────────────────

/// Streams a binary artifact to disk, verifies it, and stages it ready for
/// installation by the platform installer.
///
/// ## Verification (§1.2 SIGNED-OR-DIE LAW)
/// 1. SHA-256 of every written byte is checked against the manifest value.
/// 2. Ed25519 of the full file is checked against the bundled public key.
/// If either check fails the downloaded file is deleted and
/// [ArtifactVerificationException] is thrown — there is no bypass.
///
/// ## Retry policy (§6.6)
/// Exponential backoff starting at 2 s, capped at 5 min, up to 5 retries.
/// Verification failures are not retried.
///
/// ## Resume (§6.6)
/// If a partial file exists in [stagingDir] a `Range: bytes=N-` header is
/// sent. If the server responds with 200 instead of 206 the download restarts
/// from zero.
class BinaryDownloadRepository {
  BinaryDownloadRepository({
    http.Client? httpClient,
    VerifyFn? verifySignature,
    String? userAgent,
  })  : _httpClient = httpClient ?? buildUpdaterClient(),
        _verifySignature = verifySignature ?? Ed25519Verifier.verify,
        _userAgent = userAgent ?? kUpdaterUserAgent;

  static const int _kMaxRetries = 5;
  static const Duration _kBaseBackoff = Duration(seconds: 2);
  static const Duration _kMaxBackoff = Duration(minutes: 5);
  static const Duration _kDownloadTimeout = Duration(minutes: 10);
  static const Duration _kProgressThrottle = Duration(milliseconds: 100);

  /// Name of the in-progress download file inside [stagingDir].
  static const String _kPartialName = 'payload.partial';

  final http.Client _httpClient;
  final VerifyFn _verifySignature;
  final String _userAgent;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Downloads [artifact] for [targetVersion], yielding [DownloadProgress]
  /// events until the verified payload is staged in [pendingDir].
  ///
  /// The final yielded event has [DownloadProgress.isComplete] == true.
  ///
  /// Throws [ArtifactVerificationException] on SHA-256 or Ed25519 failure.
  /// Throws [ArtifactDownloadException] when all retries are exhausted.
  /// Throws [StagingException] on unrecoverable file I/O error.
  Stream<DownloadProgress> download({
    required UpdateArtifact artifact,
    required Directory stagingDir,
    required Directory pendingDir,
    required String targetVersion,
  }) async* {
    int attempt = 0;

    while (true) {
      try {
        await for (final progress in _attemptDownload(
          artifact: artifact,
          stagingDir: stagingDir,
          pendingDir: pendingDir,
          targetVersion: targetVersion,
        )) {
          yield progress;
        }
        return; // stream completes successfully

      } on ArtifactVerificationException {
        rethrow; // verification failure is terminal — never retry
      } on StagingException {
        rethrow; // disk / I/O failure is terminal
      } catch (e) {
        attempt++;
        if (attempt > _kMaxRetries) {
          AppLogger.e(
            '[Updater]',
            'Download failed after $_kMaxRetries retries. Giving up.',
            e,
          );
          throw ArtifactDownloadException(
            message:
                "We couldn't finish downloading the update. We'll try again later.",
            technicalDetail: e.toString(),
          );
        }
        final backoff = _backoffFor(attempt);
        AppLogger.w(
          '[Updater]',
          'Download attempt $attempt failed; retrying in '
          '${backoff.inSeconds}s: $e',
        );
        await Future<void>.delayed(backoff);
      }
    }
  }

  // ── Private: single download attempt ───────────────────────────────────────

  Stream<DownloadProgress> _attemptDownload({
    required UpdateArtifact artifact,
    required Directory stagingDir,
    required Directory pendingDir,
    required String targetVersion,
  }) async* {
    await stagingDir.create(recursive: true);
    await pendingDir.create(recursive: true);

    final partialFile = File(p.join(stagingDir.path, _kPartialName));
    final int startByte =
        partialFile.existsSync() ? partialFile.lengthSync() : 0;

    // ── Build HTTP request ────────────────────────────────────────────────────
    final request = http.Request('GET', Uri.parse(artifact.url));
    request.headers.addAll({
      'User-Agent': _userAgent,
      'Accept': 'application/octet-stream',
    });
    if (startByte > 0) {
      request.headers['Range'] = 'bytes=$startByte-';
      AppLogger.d('[Updater]', 'Resuming download from byte $startByte.');
    } else {
      AppLogger.d('[Updater]', 'Starting download of ${artifact.url}.');
    }

    // ── Send request ──────────────────────────────────────────────────────────
    final http.StreamedResponse response;
    try {
      response = await _httpClient.send(request).timeout(_kDownloadTimeout);
    } on TimeoutException catch (e) {
      throw ArtifactDownloadException(
        message: 'Timed out connecting to the download server.',
        technicalDetail: e.toString(),
      );
    }

    // ── Interpret status code ─────────────────────────────────────────────────
    final bool serverHonouredRange;
    final FileMode fileMode;
    int bytesReceived;

    if (startByte > 0 && response.statusCode == 206) {
      // Server supports Range — true resume.
      serverHonouredRange = true;
      fileMode = FileMode.writeOnlyAppend;
      bytesReceived = startByte;
      AppLogger.d('[Updater]', 'Server returned 206; resuming from $startByte bytes.');
    } else if (response.statusCode == 200) {
      // Either fresh start or server ignored Range — restart from zero.
      if (startByte > 0) {
        AppLogger.d(
          '[Updater]',
          'Server ignored Range header (returned 200); restarting from zero.',
        );
      }
      serverHonouredRange = false;
      fileMode = FileMode.writeOnly;
      bytesReceived = 0;
    } else {
      throw ArtifactDownloadException(
        message: 'Could not start downloading the update.',
        technicalDetail:
            'Unexpected HTTP ${response.statusCode} from ${artifact.url}.',
      );
    }

    // ── Stream to disk + SHA-256 in flight ────────────────────────────────────
    // Per §6.6: pipe stream directly to IOSink — do not buffer entire artifact.
    // SHA-256 is computed via chunked conversion so no second file read is
    // needed. Ed25519 requires the full message (no streaming API exists), so
    // the file is read back once after SHA-256 passes (§6.6 note).
    final digestSink = _DigestSink();
    final sha256Input = sha256.startChunkedConversion(digestSink);

    // When resuming, seed the SHA-256 state with the already-written bytes so
    // the final digest covers the complete file, not just the appended portion.
    if (serverHonouredRange && startByte > 0) {
      sha256Input.add(await partialFile.readAsBytes());
    }

    final int totalBytes = response.contentLength ?? artifact.sizeBytes;
    DateTime lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
    IOSink? fileSink;

    try {
      fileSink = partialFile.openWrite(mode: fileMode);
      await for (final chunk in response.stream) {
        fileSink.add(chunk);
        sha256Input.add(chunk);
        bytesReceived += chunk.length;

        final now = DateTime.now();
        if (now.difference(lastEmit) >= _kProgressThrottle) {
          lastEmit = now;
          yield DownloadProgress(
            bytesReceived: bytesReceived,
            bytesTotal: totalBytes,
            isComplete: false,
          );
        }
      }
      await fileSink.flush();
    } catch (e) {
      AppLogger.w('[Updater]', 'Network interrupt during download: $e');
      rethrow; // outer retry loop will handle
    } finally {
      await fileSink?.close();
    }

    sha256Input.close();

    // ── Byte-count sanity check ───────────────────────────────────────────────
    // Per §6.6: byte-count mismatch after (attempted) resume → delete + retry.
    if (bytesReceived != artifact.sizeBytes) {
      AppLogger.w(
        '[Updater]',
        'Byte count mismatch: expected ${artifact.sizeBytes}, '
        'got $bytesReceived. Deleting partial file and retrying from zero.',
      );
      try {
        await partialFile.delete();
      } catch (_) {}
      throw ArtifactDownloadException(
        message: 'Download was incomplete.',
        technicalDetail:
            'Expected ${artifact.sizeBytes} bytes, received $bytesReceived.',
      );
    }

    // ── SHA-256 verification ──────────────────────────────────────────────────
    final String digestHex = digestSink.value.toString();
    if (digestHex != artifact.sha256) {
      AppLogger.e(
        '[Updater]',
        'SHA-256 mismatch. Expected: ${artifact.sha256}. '
        'Got: $digestHex. Deleting payload.',
      );
      try {
        await partialFile.delete();
      } catch (_) {}
      throw const ArtifactVerificationException(
        message: 'The update download failed integrity verification.',
        technicalDetail: 'SHA-256 mismatch.',
      );
    }
    AppLogger.d('[Updater]', 'SHA-256 passed.');

    // ── Ed25519 verification — SIGNED-OR-DIE LAW ─────────────────────────────
    // Read the completed file back for Ed25519. The crypto package provides no
    // streaming Ed25519 API; buffering during download is forbidden by §6.6.
    // A single post-download read of ~50 MB on a desktop is acceptable.
    final List<int> fullBytes;
    try {
      fullBytes = await partialFile.readAsBytes();
    } catch (e, st) {
      AppLogger.e('[Updater]', 'Could not read staged payload for Ed25519.', e, st);
      try {
        await partialFile.delete();
      } catch (_) {}
      throw StagingException(
        message: 'Could not read the downloaded update file.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    final List<int> artifactSigBytes;
    try {
      artifactSigBytes = base64.decode(artifact.ed25519Signature);
    } catch (e) {
      AppLogger.e(
        '[Updater]',
        'Artifact Ed25519 signature is not valid base64. Deleting payload.',
        e,
      );
      try {
        await partialFile.delete();
      } catch (_) {}
      throw const ArtifactVerificationException(
        message: 'The update has an invalid signature format.',
        technicalDetail: 'Artifact Ed25519 signature is not valid base64.',
      );
    }

    final bool sigValid = await _verifySignature(
      message: fullBytes,
      signature: artifactSigBytes,
    );
    if (!sigValid) {
      AppLogger.e(
        '[Updater]',
        'Artifact Ed25519 FAILED. Deleting payload. '
        'Treating as a security event.',
      );
      try {
        await partialFile.delete();
      } catch (_) {}
      throw const ArtifactVerificationException(
        message: 'The update failed security verification.',
        technicalDetail: 'Artifact Ed25519 signature did not verify.',
      );
    }
    AppLogger.d('[Updater]', 'Ed25519 passed.');

    // ── Atomic move to pending ────────────────────────────────────────────────
    final String ext = _extensionFromUrl(artifact.url);
    final File pendingPayload = File(p.join(pendingDir.path, 'payload$ext'));
    final File pendingMetadata =
        File(p.join(pendingDir.path, 'metadata.json'));
    final File pendingSig = File(p.join(pendingDir.path, 'payload.sig'));

    try {
      // Clear any stale pending files from a previous staged update.
      if (pendingPayload.existsSync()) await pendingPayload.delete();
      if (pendingMetadata.existsSync()) await pendingMetadata.delete();
      if (pendingSig.existsSync()) await pendingSig.delete();

      // Move verified payload into pending.
      await partialFile.rename(pendingPayload.path);

      // Write sidecar files.
      await pendingSig.writeAsString(
        artifact.ed25519Signature,
        flush: true,
      );
      final now = DateTime.now().toUtc();
      await pendingMetadata.writeAsString(
        jsonEncode({
          'version': targetVersion,
          'staged_at': now.toIso8601String(),
          'sha256': artifact.sha256,
        }),
        flush: true,
      );
    } catch (e, st) {
      AppLogger.e('[Updater]', 'Failed to stage downloaded payload.', e, st);
      throw StagingException(
        message: 'Could not prepare the update for installation.',
        technicalDetail: e.toString(),
        stackTrace: st,
      );
    }

    AppLogger.i(
      '[Updater]',
      'Artifact v$targetVersion staged at ${pendingPayload.path}.',
    );

    // Always emit the terminal progress event regardless of throttle window.
    yield DownloadProgress(
      bytesReceived: bytesReceived,
      bytesTotal: totalBytes,
      isComplete: true,
    );
  }

  // ── Static helpers ──────────────────────────────────────────────────────────

  static Duration _backoffFor(int attempt) {
    // base * 2^(attempt-1), capped at max.
    final secs = min(
      _kBaseBackoff.inSeconds * pow(2, attempt - 1).toInt(),
      _kMaxBackoff.inSeconds,
    );
    return Duration(seconds: secs);
  }

  /// Extracts the file extension (including leading dot) from a URL path.
  /// Returns an empty string if the filename has no extension.
  static String _extensionFromUrl(String url) {
    final lastSegment = Uri.parse(url).pathSegments.lastOrNull ?? '';
    final dot = lastSegment.lastIndexOf('.');
    return dot >= 0 ? lastSegment.substring(dot) : '';
  }
}

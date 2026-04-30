// test/features/updater/repository_integration_test.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §11.4 (deliverable 5) + §13.2
//
// Integration tests for ManifestRepository, BinaryDownloadRepository, and
// BrainRepository. Each test group spins up a dart:io HttpServer that serves
// fixture content signed with a test-only Ed25519 key pair.
//
// PREREQUISITE: run `dart run build_runner build --delete-conflicting-outputs`
// before running these tests.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/features/updater/data/models/brain_update_info.dart';
import 'package:briluxforge/features/updater/data/models/update_artifact.dart';
import 'package:briluxforge/features/updater/data/repositories/allow_listed_client.dart';
import 'package:briluxforge/features/updater/data/repositories/binary_download_repository.dart';
import 'package:briluxforge/features/updater/data/repositories/brain_repository.dart';
import 'package:briluxforge/features/updater/data/repositories/manifest_repository.dart';
import 'package:briluxforge/features/updater/data/signing/ed25519_verifier.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

/// Signs [message] with [keyPair] and returns the 64-byte signature.
Future<List<int>> _sign(List<int> message, SimpleKeyPair keyPair) async {
  final sig = await Ed25519().sign(message, keyPair: keyPair);
  return sig.bytes;
}

/// Returns base64-encoded Ed25519 signature of [message] under [keyPair].
Future<String> _signBase64(List<int> message, SimpleKeyPair keyPair) async {
  return base64.encode(await _sign(message, keyPair));
}

/// Builds a [VerifyFn] that uses [Ed25519Verifier.verifyWithKey] with the
/// supplied [publicKeyBytes]. Injected into repositories so tests are
/// independent of the production bundled key.
VerifyFn _makeVerifyFn(List<int> publicKeyBytes) {
  return ({required List<int> message, required List<int> signature}) =>
      Ed25519Verifier.verifyWithKey(
        message: message,
        signature: signature,
        publicKeyBytes: publicKeyBytes,
      );
}

/// A minimal HTTP server for tests. Route handlers are registered by path;
/// unregistered paths return 404. Supports Range request handling when the
/// handler sets [_RangeAware] metadata on the response bytes.
class _TestServer {
  _TestServer._(this._server);

  final HttpServer _server;
  final Map<String, _Handler> _routes = {};

  int get port => _server.port;
  String get baseUrl => 'http://127.0.0.1:$port';

  static Future<_TestServer> bind() async {
    final s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final ts = _TestServer._(s);
    s.listen(ts._dispatch);
    return ts;
  }

  /// Registers a static byte-slice route. If the request carries a valid
  /// `Range: bytes=N-` header, a 206 response with the tail bytes is returned.
  void route(String path, List<int> bytes, {int statusCode = 200}) {
    _routes[path] = _StaticHandler(bytes, statusCode);
  }

  /// Registers a route that always returns [statusCode] with an empty body.
  void routeStatus(String path, int statusCode) {
    _routes[path] = _StatusHandler(statusCode);
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _dispatch(HttpRequest req) async {
    final handler = _routes[req.uri.path];
    if (handler == null) {
      req.response.statusCode = 404;
      await req.response.close();
      return;
    }
    await handler.handle(req);
  }
}

abstract class _Handler {
  Future<void> handle(HttpRequest req);
}

class _StaticHandler implements _Handler {
  _StaticHandler(this.bytes, this.defaultStatus);
  final List<int> bytes;
  final int defaultStatus;

  @override
  Future<void> handle(HttpRequest req) async {
    final rangeHeader = req.headers.value('range');
    if (rangeHeader != null) {
      // Parse `Range: bytes=N-` (suffix ranges not needed for these tests).
      final match = RegExp(r'^bytes=(\d+)-$').firstMatch(rangeHeader);
      if (match != null) {
        final start = int.parse(match.group(1)!);
        if (start < bytes.length) {
          req.response.statusCode = 206;
          req.response.headers.set(
            'Content-Range',
            'bytes $start-${bytes.length - 1}/${bytes.length}',
          );
          req.response.headers.set(
            'Content-Length',
            '${bytes.length - start}',
          );
          req.response.add(bytes.sublist(start));
          await req.response.close();
          return;
        }
      }
    }
    req.response.statusCode = defaultStatus;
    req.response.headers.set('Content-Length', '${bytes.length}');
    req.response.add(bytes);
    await req.response.close();
  }
}

class _StatusHandler implements _Handler {
  _StatusHandler(this.statusCode);
  final int statusCode;

  @override
  Future<void> handle(HttpRequest req) async {
    req.response.statusCode = statusCode;
    await req.response.close();
  }
}

// ── ManifestRepository ────────────────────────────────────────────────────────

void main() {
  // ── Shared test infrastructure ────────────────────────────────────────────

  late SimpleKeyPair testKeyPair;
  late List<int> testPublicKeyBytes;

  // Raw fixture manifest bytes (loaded from file once).
  late List<int> manifestBytes;

  setUpAll(() async {
    testKeyPair = await Ed25519().newKeyPair();
    testPublicKeyBytes =
        (await testKeyPair.extractPublicKey()).bytes;

    manifestBytes = await File(
      'test/fixtures/updater/manifest_v1_valid.json',
    ).readAsBytes();
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('ManifestRepository', () {
    late _TestServer server;
    late ManifestRepository repo;

    setUp(() async {
      server = await _TestServer.bind();

      // Default valid routes — overridden per-test where needed.
      final validSigBytes =
          utf8.encode(base64.encode(await _sign(manifestBytes, testKeyPair)));
      server.route('/manifest.json', manifestBytes);
      server.route('/manifest.json.sig', validSigBytes);

      repo = ManifestRepository(
        manifestUrl: '${server.baseUrl}/manifest.json',
        signatureUrl: '${server.baseUrl}/manifest.json.sig',
        httpClient: http.Client(),
        verifySignature: _makeVerifyFn(testPublicKeyBytes),
      );
    });

    tearDown(() => server.close());

    // ── 1. Valid manifest + valid signature → success ───────────────────────
    test('fetchAndVerify returns parsed manifest on valid payload + sig',
        () async {
      final manifest = await repo.fetchAndVerify();

      expect(manifest.manifestVersion, 1);
      expect(manifest.binary?.version, '1.2.3');
      expect(manifest.brain?.version, 47);
      expect(
        manifest.featureFlags.getFlag('enable_groq_provider'),
        isTrue,
      );
    });

    // ── 2. Valid manifest + corrupted signature → ManifestSignatureException ─
    test('fetchAndVerify throws ManifestSignatureException on bad signature',
        () async {
      // Overwrite the signature route with corrupted bytes.
      final corruptedSig = List<int>.filled(64, 0xDE);
      server.route(
        '/manifest.json.sig',
        utf8.encode(base64.encode(corruptedSig)),
      );

      expect(
        () => repo.fetchAndVerify(),
        throwsA(isA<ManifestSignatureException>()),
      );
    });

    // ── 3. HTTP 404 for manifest → ManifestFetchException ──────────────────
    test('fetchAndVerify throws ManifestFetchException on 404 manifest',
        () async {
      final notFoundRepo = ManifestRepository(
        manifestUrl: '${server.baseUrl}/nonexistent.json',
        signatureUrl: '${server.baseUrl}/manifest.json.sig',
        httpClient: http.Client(),
        verifySignature: _makeVerifyFn(testPublicKeyBytes),
      );

      expect(
        () => notFoundRepo.fetchAndVerify(),
        throwsA(isA<ManifestFetchException>()),
      );
    });

    // ── 4. HTTP 404 for signature → ManifestFetchException ─────────────────
    test('fetchAndVerify throws ManifestFetchException on 404 signature',
        () async {
      final noSigRepo = ManifestRepository(
        manifestUrl: '${server.baseUrl}/manifest.json',
        signatureUrl: '${server.baseUrl}/nonexistent.sig',
        httpClient: http.Client(),
        verifySignature: _makeVerifyFn(testPublicKeyBytes),
      );

      expect(
        () => noSigRepo.fetchAndVerify(),
        throwsA(isA<ManifestFetchException>()),
      );
    });

    // ── 5. manifest_version 99 → ManifestSchemaException ──────────────────
    test(
        'fetchAndVerify throws ManifestSchemaException for unknown '
        'manifest_version', () async {
      final v99Json = jsonDecode(utf8.decode(manifestBytes)) as Map<String, Object?>;
      v99Json['manifest_version'] = 99;
      final v99Bytes = utf8.encode(jsonEncode(v99Json));
      final v99SigBytes = utf8.encode(
        base64.encode(await _sign(v99Bytes, testKeyPair)),
      );

      server.route('/manifest_v99.json', v99Bytes);
      server.route('/manifest_v99.json.sig', v99SigBytes);

      final v99Repo = ManifestRepository(
        manifestUrl: '${server.baseUrl}/manifest_v99.json',
        signatureUrl: '${server.baseUrl}/manifest_v99.json.sig',
        httpClient: http.Client(),
        verifySignature: _makeVerifyFn(testPublicKeyBytes),
      );

      expect(
        () => v99Repo.fetchAndVerify(),
        throwsA(isA<ManifestSchemaException>()),
      );
    });

    // ── 6. Malformed JSON → ManifestSchemaException ─────────────────────────
    test(
        'fetchAndVerify throws ManifestSchemaException for malformed JSON',
        () async {
      final brokenBytes = utf8.encode('{ "manifest_version": 1, BROKEN }');
      final brokenSigBytes = utf8.encode(
        base64.encode(await _sign(brokenBytes, testKeyPair)),
      );

      server.route('/broken.json', brokenBytes);
      server.route('/broken.json.sig', brokenSigBytes);

      final brokenRepo = ManifestRepository(
        manifestUrl: '${server.baseUrl}/broken.json',
        signatureUrl: '${server.baseUrl}/broken.json.sig',
        httpClient: http.Client(),
        verifySignature: _makeVerifyFn(testPublicKeyBytes),
      );

      expect(
        () => brokenRepo.fetchAndVerify(),
        throwsA(isA<ManifestSchemaException>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('BinaryDownloadRepository', () {
    late _TestServer server;
    late Directory tempDir;
    late Directory stagingDir;
    late Directory pendingDir;

    // Test binary payload: 1 024 bytes of deterministic data.
    late List<int> binaryPayload;
    late String binaryPayloadSha256;
    late String binaryPayloadSigBase64;

    setUp(() async {
      binaryPayload = List<int>.generate(1024, (i) => i % 256);
      binaryPayloadSha256 = sha256.convert(binaryPayload).toString();
      binaryPayloadSigBase64 =
          await _signBase64(binaryPayload, testKeyPair);

      tempDir = await Directory.systemTemp.createTemp('brilux_test_');
      stagingDir = Directory('${tempDir.path}/staging');
      pendingDir = Directory('${tempDir.path}/pending');

      server = await _TestServer.bind();
      server.route('/payload.zip', binaryPayload);
    });

    tearDown(() async {
      await server.close();
      await tempDir.delete(recursive: true);
    });

    UpdateArtifact _makeArtifact({
      String? sha256Override,
      String? sigOverride,
      String? urlOverride,
    }) {
      return UpdateArtifact(
        platform: 'windows',
        arch: 'x64',
        url: urlOverride ?? '${server.baseUrl}/payload.zip',
        sizeBytes: binaryPayload.length,
        sha256: sha256Override ?? binaryPayloadSha256,
        ed25519Signature: sigOverride ?? binaryPayloadSigBase64,
      );
    }

    BinaryDownloadRepository _makeRepo() {
      return BinaryDownloadRepository(
        httpClient: http.Client(),
        verifySignature: _makeVerifyFn(testPublicKeyBytes),
      );
    }

    // ── 1. Full successful download ─────────────────────────────────────────
    test(
        'download streams progress and stages verified payload in pendingDir',
        () async {
      final repo = _makeRepo();
      final events = <DownloadProgress>[];

      await repo
          .download(
            artifact: _makeArtifact(),
            stagingDir: stagingDir,
            pendingDir: pendingDir,
            targetVersion: '1.2.3',
          )
          .forEach(events.add);

      // At least one progress event emitted.
      expect(events, isNotEmpty);

      // Terminal event is marked complete.
      expect(events.last.isComplete, isTrue);
      expect(events.last.bytesReceived, binaryPayload.length);

      // Pending payload file exists.
      final pendingPayload = File('${pendingDir.path}/payload.zip');
      expect(pendingPayload.existsSync(), isTrue);
      expect(pendingPayload.lengthSync(), binaryPayload.length);

      // Metadata sidecar written.
      final metadata = jsonDecode(
        File('${pendingDir.path}/metadata.json').readAsStringSync(),
      ) as Map<String, Object?>;
      expect(metadata['version'], '1.2.3');
      expect(metadata['sha256'], binaryPayloadSha256);

      // Signature sidecar written.
      final sig =
          File('${pendingDir.path}/payload.sig').readAsStringSync();
      expect(sig, binaryPayloadSigBase64);
    });

    // ── 2. SHA-256 mismatch → ArtifactVerificationException ────────────────
    test(
        'download throws ArtifactVerificationException on SHA-256 mismatch',
        () async {
      final repo = _makeRepo();

      expect(
        () => repo
            .download(
              artifact: _makeArtifact(
                sha256Override: 'deadbeef' * 8, // wrong hash, correct length
              ),
              stagingDir: stagingDir,
              pendingDir: pendingDir,
              targetVersion: '1.2.3',
            )
            .drain<void>(),
        throwsA(isA<ArtifactVerificationException>()),
      );
    });

    // ── 3. Ed25519 mismatch → ArtifactVerificationException ────────────────
    test(
        'download throws ArtifactVerificationException on Ed25519 mismatch',
        () async {
      final repo = _makeRepo();
      // Use a different key pair for signing → signature mismatch.
      final wrongKey = await Ed25519().newKeyPair();
      final wrongSig = await _signBase64(binaryPayload, wrongKey);

      expect(
        () => repo
            .download(
              artifact: _makeArtifact(sigOverride: wrongSig),
              stagingDir: stagingDir,
              pendingDir: pendingDir,
              targetVersion: '1.2.3',
            )
            .drain<void>(),
        throwsA(isA<ArtifactVerificationException>()),
      );
    });

    // ── 4. Partial file present → Range header sent, correct final file ─────
    test(
        'download resumes from existing partial file and produces correct '
        'final payload', () async {
      // Pre-create a partial file containing the first 512 bytes.
      await stagingDir.create(recursive: true);
      final partialFile = File('${stagingDir.path}/payload.partial');
      await partialFile.writeAsBytes(binaryPayload.sublist(0, 512));

      final repo = _makeRepo();
      final events = <DownloadProgress>[];

      await repo
          .download(
            artifact: _makeArtifact(),
            stagingDir: stagingDir,
            pendingDir: pendingDir,
            targetVersion: '1.2.3',
          )
          .forEach(events.add);

      expect(events.last.isComplete, isTrue);
      // bytesReceived should be full size (512 pre-existing + 512 fetched).
      expect(events.last.bytesReceived, binaryPayload.length);

      // Verify the staged file contains the complete payload.
      final staged = File('${pendingDir.path}/payload.zip');
      expect(staged.readAsBytesSync(), equals(binaryPayload));

      // Partial file has been moved (should no longer exist in staging).
      expect(partialFile.existsSync(), isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  group('BrainRepository', () {
    late _TestServer server;
    late Directory tempDir;

    // Test brain payload.
    late List<int> brainPayload;
    late String brainSha256;
    late String brainSigBase64;

    setUp(() async {
      brainPayload = utf8.encode(
        jsonEncode({
          'version': 47,
          'models': [
            {'id': 'gpt-4o', 'provider': 'openai'},
          ],
        }),
      );
      brainSha256 = sha256.convert(brainPayload).toString();
      brainSigBase64 = await _signBase64(brainPayload, testKeyPair);

      tempDir = await Directory.systemTemp.createTemp('brilux_brain_test_');
      server = await _TestServer.bind();
      server.route('/brain.json', brainPayload);
    });

    tearDown(() async {
      await server.close();
      await tempDir.delete(recursive: true);
    });

    BrainUpdateInfo _makeBrainInfo({
      String? sha256Override,
      String? sigOverride,
    }) {
      return BrainUpdateInfo(
        version: 47,
        url: '${server.baseUrl}/brain.json',
        sizeBytes: brainPayload.length,
        sha256: sha256Override ?? brainSha256,
        ed25519Signature: sigOverride ?? brainSigBase64,
      );
    }

    BrainRepository _makeRepo() {
      return BrainRepository(
        httpClient: http.Client(),
        verifySignature: _makeVerifyFn(testPublicKeyBytes),
      );
    }

    // ── 1. Valid payload → current.json written, version returned ───────────
    test('fetchAndApply writes brain to targetFile and returns version',
        () async {
      final targetFile = File('${tempDir.path}/brain/current.json');
      final repo = _makeRepo();

      final version = await repo.fetchAndApply(
        brainInfo: _makeBrainInfo(),
        targetFile: targetFile,
      );

      expect(version, 47);
      expect(targetFile.existsSync(), isTrue);

      final written = jsonDecode(targetFile.readAsStringSync())
          as Map<String, Object?>;
      expect(written['version'], 47);
    });

    // ── 2. SHA-256 mismatch → ArtifactVerificationException ────────────────
    test(
        'fetchAndApply throws ArtifactVerificationException on SHA-256 mismatch',
        () async {
      final targetFile = File('${tempDir.path}/brain/current.json');
      final repo = _makeRepo();

      await expectLater(
        repo.fetchAndApply(
          brainInfo: _makeBrainInfo(sha256Override: 'cafebabe' * 8),
          targetFile: targetFile,
        ),
        throwsA(isA<ArtifactVerificationException>()),
      );
      // targetFile must NOT have been written.
      expect(targetFile.existsSync(), isFalse);
    });

    // ── 3. Ed25519 mismatch → ArtifactVerificationException ────────────────
    test(
        'fetchAndApply throws ArtifactVerificationException on Ed25519 mismatch',
        () async {
      final targetFile = File('${tempDir.path}/brain/current2.json');
      final wrongKey = await Ed25519().newKeyPair();
      final wrongSig = await _signBase64(brainPayload, wrongKey);
      final repo = _makeRepo();

      await expectLater(
        repo.fetchAndApply(
          brainInfo: _makeBrainInfo(sigOverride: wrongSig),
          targetFile: targetFile,
        ),
        throwsA(isA<ArtifactVerificationException>()),
      );
      expect(targetFile.existsSync(), isFalse);
    });

    // ── 4. Atomic write: no .tmp file left after success ───────────────────
    test('fetchAndApply leaves no .tmp file after successful write', () async {
      final targetFile = File('${tempDir.path}/brain/current3.json');
      final repo = _makeRepo();

      await repo.fetchAndApply(
        brainInfo: _makeBrainInfo(),
        targetFile: targetFile,
      );

      final tmpFile = File('${targetFile.path}.tmp');
      expect(tmpFile.existsSync(), isFalse);
      expect(targetFile.existsSync(), isTrue);
    });
  });
}

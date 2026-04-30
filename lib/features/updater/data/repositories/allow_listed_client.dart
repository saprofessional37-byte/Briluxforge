// lib/features/updater/data/repositories/allow_listed_client.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §10.3

import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:briluxforge/core/errors/app_exception.dart';

// ── User-Agent ────────────────────────────────────────────────────────────────

/// Default User-Agent sent by all updater HTTP requests.
///
/// Per ZERO-CONTENT-EXFILTRATION LAW (§1.2) this string contains only app
/// name and OS. [UpdaterService] (Phase 11.6) injects a richer value that
/// includes the installed version and architecture at runtime.
String get kUpdaterUserAgent =>
    'Briluxforge-Updater/${Platform.operatingSystem}';

// ── Verify function typedef ───────────────────────────────────────────────────

/// Signature of a function that verifies an Ed25519 signature.
///
/// All three repositories accept an injectable [VerifyFn] so tests can
/// supply [Ed25519Verifier.verifyWithKey] with a test-only key pair, while
/// production code paths use [Ed25519Verifier.verify] (bundled public key).
typedef VerifyFn = Future<bool> Function({
  required List<int> message,
  required List<int> signature,
});

// ── Allow-listed hosts ────────────────────────────────────────────────────────

/// The exhaustive set of hosts the updater HTTP client may contact.
///
/// Any request to a host not in this set is rejected before transmission.
/// This is a defense-in-depth check on top of Ed25519 signature verification
/// (§10.2). Extend this list only if the manifest topology changes.
const Set<String> kUpdaterAllowedHosts = {
  'updates.briluxlabs.com',
  'github.com',
  'objects.githubusercontent.com',
  'github-releases.githubusercontent.com',
  'codeload.github.com',
};

// ── Factory ───────────────────────────────────────────────────────────────────

/// Creates the updater's HTTP client wrapped with [AllowListedClient].
///
/// Pass [overrideHosts] only in tests to permit requests to localhost.
http.Client buildUpdaterClient({Set<String>? overrideHosts}) {
  final inner = http.Client();
  return AllowListedClient(
    inner,
    allowedHosts: overrideHosts ?? kUpdaterAllowedHosts,
  );
}

// ── AllowListedClient ─────────────────────────────────────────────────────────

/// An [http.BaseClient] decorator that rejects requests to any host not
/// present in [allowedHosts] before the bytes leave the machine.
///
/// Per §10.3 and §10.2 this is a defense-in-depth layer supplementary to
/// Ed25519 verification. It cannot be bypassed by manifest content because
/// the manifest is already verified before any artifact URL is opened.
class AllowListedClient extends http.BaseClient {
  AllowListedClient(this._inner, {required this.allowedHosts});

  final http.Client _inner;
  final Set<String> allowedHosts;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final host = request.url.host;
    if (!allowedHosts.contains(host)) {
      throw ArtifactDownloadException(
        message: 'Blocked request to disallowed host.',
        technicalDetail:
            'Host "$host" is not in the updater allow-list. '
            'Allowed: ${allowedHosts.join(', ')}.',
      );
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

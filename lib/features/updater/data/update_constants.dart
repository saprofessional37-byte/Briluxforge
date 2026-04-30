// lib/features/updater/data/update_constants.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §4.3

/// Ed25519 public key (32 bytes) used to verify every signed payload
/// the updater consumes. The corresponding private key is held in the
/// GitHub Actions encrypted secret UPDATE_SIGNING_PRIVATE_KEY.
///
/// Rotating this key requires shipping a new binary.
const String kUpdatePublicKeyBase64 =
    'tpAciNQsmlSwJ9nFxz+85BaL4kAso2NKB/4qvPRO1xM=';

/// URL where the signed manifest lives. Hosted on GitHub Pages.
/// Must be HTTPS. Must be a stable, never-moved path.
const String kUpdateManifestUrl =
    'https://updates.briluxlabs.com/manifest.json';

/// Detached-signature URL for the manifest.
const String kUpdateManifestSignatureUrl =
    'https://updates.briluxlabs.com/manifest.json.sig';

/// How often to recheck the manifest while the app is running.
const Duration kUpdateCheckInterval = Duration(hours: 6);

/// How long to retain a staged binary update on disk after it is ready.
/// If the user does not restart within this window, the updater re-verifies
/// on next launch rather than trusting the on-disk copy indefinitely.
const Duration kStagedUpdateMaxAge = Duration(days: 7);

/// Maximum number of consecutive failed checks before surfacing a subtle
/// indicator in Settings. Network hiccups alone do not trigger this.
const int kConsecutiveFailureThreshold = 5;

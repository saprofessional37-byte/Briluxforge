// lib/features/updater/data/updater_exceptions.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §14.3
//
// ⚠ ALLOW-LIST NOTE (§14.7): This file is a Dart `part` of
// lib/core/errors/app_exception.dart. That is the only way to extend a
// `sealed` class from a separate file in Dart 3 without modifying the sealed
// class's library. The single `part` directive added to app_exception.dart is
// the minimum invasive change required. No existing behaviour in that file is
// altered.

part of '../../../core/errors/app_exception.dart';

// ── Manifest Exceptions ───────────────────────────────────────────────────────

/// Thrown when the HTTP fetch of the manifest or its detached signature fails:
/// network error, non-2xx response, timeout, or connection refused.
final class ManifestFetchException extends AppException {
  const ManifestFetchException({
    required super.message,
    super.technicalDetail,
    super.stackTrace,
  });
}

/// Thrown when Ed25519 verification of the manifest (or its detached
/// signature) fails. Per SIGNED-OR-DIE LAW (§1.2): the manifest bytes are
/// discarded immediately and never parsed.
final class ManifestSignatureException extends AppException {
  const ManifestSignatureException({
    required super.message,
    super.technicalDetail,
    super.stackTrace,
  });
}

/// Thrown when the manifest is syntactically valid JSON but uses an
/// unrecognised `manifest_version`, or when required structural fields are
/// absent or have the wrong type.
final class ManifestSchemaException extends AppException {
  const ManifestSchemaException({
    required super.message,
    super.technicalDetail,
    super.stackTrace,
  });
}

// ── Artifact Exceptions ───────────────────────────────────────────────────────

/// Thrown when the HTTP download of a binary artifact fails after all retries
/// (exponential backoff, max 5 attempts). Not thrown for verification failures
/// — those use [ArtifactVerificationException].
final class ArtifactDownloadException extends AppException {
  const ArtifactDownloadException({
    required super.message,
    super.technicalDetail,
    super.stackTrace,
  });
}

/// Thrown when SHA-256 or Ed25519 verification of a downloaded binary artifact
/// or brain payload fails. Per SIGNED-OR-DIE LAW (§1.2): the payload is
/// deleted from disk immediately. This exception is never retried.
final class ArtifactVerificationException extends AppException {
  const ArtifactVerificationException({
    required super.message,
    super.technicalDetail,
    super.stackTrace,
  });
}

// ── Staging / Install Exceptions ──────────────────────────────────────────────

/// Thrown when file I/O to the staging or pending directories fails (disk
/// full, permissions error, atomic rename failure).
final class StagingException extends AppException {
  const StagingException({
    required super.message,
    super.technicalDetail,
    super.stackTrace,
  });
}

/// Thrown when the platform-specific install-on-restart script cannot be
/// written or launched. See platform_installer_*.dart (§9).
final class PlatformInstallerException extends AppException {
  const PlatformInstallerException({
    required super.message,
    super.technicalDetail,
    super.stackTrace,
  });
}

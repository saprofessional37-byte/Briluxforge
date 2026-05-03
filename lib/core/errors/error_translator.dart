// lib/core/errors/error_translator.dart
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/errors/user_facing_error.dart';
import 'package:briluxforge/core/widgets/app_status_card.dart';

/// Maps every [AppException] subtype to a [UserFacingError].
/// This is the single place where raw exception data becomes user-facing copy.
/// Status codes are never rendered — they are mapped to meaning.
abstract final class ErrorTranslator {
  /// Translates [exception] into a [UserFacingError].
  /// [onAction] is threaded through so callers can attach retry / navigation.
  static UserFacingError translate(
    AppException exception, {
    void Function()? onAction,
    String? actionLabel,
  }) {
    return switch (exception) {
      final ApiKeyNotFoundException e => UserFacingError(
          headline: 'API key not found',
          explanation:
              'No key is saved for ${e.provider}. Add one in Settings → API Keys.',
          actionLabel: actionLabel ?? 'Open API Key Settings',
          onAction: onAction,
          severity: AppStatusVariant.error,
          technicalDetails: _sanitize(e.technicalDetail ?? e.message),
        ),

      final ApiRequestException e => _translateApiRequest(
          e,
          onAction: onAction,
          actionLabel: actionLabel,
        ),

      final DelegationException e => UserFacingError(
          headline: 'Delegation failed',
          explanation: 'The routing engine could not assign a model. '
              'Try rephrasing or sending to a specific model directly.',
          actionLabel: actionLabel ?? 'Retry',
          onAction: onAction,
          severity: AppStatusVariant.warning,
          technicalDetails: _sanitize(e.technicalDetail ?? e.message),
        ),

      SecureStorageException _ => UserFacingError(
          headline: 'Could not access secure storage',
          explanation:
              'Your API keys are stored securely — something blocked that access. '
              'Restarting Briluxforge usually fixes this.',
          actionLabel: actionLabel ?? 'Dismiss',
          onAction: onAction,
          severity: AppStatusVariant.error,
          technicalDetails: _sanitize(exception.technicalDetail),
        ),

      final AuthException e => UserFacingError(
          headline: 'Sign-in failed',
          explanation: e.message.isNotEmpty
              ? e.message
              : 'Check your credentials and try again.',
          actionLabel: actionLabel ?? 'Try again',
          onAction: onAction,
          severity: AppStatusVariant.error,
          technicalDetails: _sanitize(e.technicalDetail),
        ),

      final LicenseValidationException e => UserFacingError(
          headline: 'License could not be verified',
          explanation: e.message.isNotEmpty
              ? e.message
              : 'Make sure you entered the key exactly as received from Gumroad.',
          actionLabel: actionLabel ?? 'Try again',
          onAction: onAction,
          severity: AppStatusVariant.error,
          technicalDetails: _sanitize(e.technicalDetail),
        ),

      DatabaseException _ => UserFacingError(
          headline: 'Database error',
          explanation:
              'Something went wrong reading or writing local data. '
              'If this keeps happening, restart Briluxforge.',
          actionLabel: actionLabel ?? 'Dismiss',
          onAction: onAction,
          severity: AppStatusVariant.error,
          technicalDetails: _sanitize(exception.technicalDetail),
        ),

      // Updater exceptions — informational, not blocking
      ManifestFetchException _ ||
      ManifestSignatureException _ ||
      ManifestSchemaException _ => UserFacingError(
          headline: 'Update check failed',
          explanation:
              'Could not fetch the latest update manifest. '
              "Your current version still works — we'll try again next launch.",
          actionLabel: actionLabel ?? 'Dismiss',
          onAction: onAction,
          severity: AppStatusVariant.warning,
          technicalDetails: _sanitize(exception.technicalDetail),
        ),

      ArtifactDownloadException _ ||
      ArtifactVerificationException _ => UserFacingError(
          headline: 'Update download failed',
          explanation:
              'The update could not be downloaded or verified. '
              'Your current version is unchanged.',
          actionLabel: actionLabel ?? 'Dismiss',
          onAction: onAction,
          severity: AppStatusVariant.warning,
          technicalDetails: _sanitize(exception.technicalDetail),
        ),

      StagingException _ || PlatformInstallerException _ => UserFacingError(
          headline: 'Update could not be installed',
          explanation:
              'The downloaded update failed to stage for install. '
              'Your current version is unchanged. Try again later.',
          actionLabel: actionLabel ?? 'Dismiss',
          onAction: onAction,
          severity: AppStatusVariant.warning,
          technicalDetails: _sanitize(exception.technicalDetail),
        ),
    };
  }

  // ── HTTP status → human meaning ───────────────────────────────────────────

  static UserFacingError _translateApiRequest(
    ApiRequestException e, {
    void Function()? onAction,
    String? actionLabel,
  }) {
    // Unwrap the nullable status code once so that relational guards
    // (>= 500) inside the switch expression operate on a non-nullable int.
    final int? nullableCode = e.statusCode;
    final int code = nullableCode ?? -1;

    final (headline, explanation) = switch (code) {
      401 || 403 => (
          'Your API key was rejected',
          'Check that the ${e.provider} key is correct and has not been revoked.',
        ),
      429 => (
          "You've hit the rate limit",
          'Your ${e.provider} plan has been throttled. '
              'Wait a moment before sending again.',
        ),
      >= 500 => (
          '${e.provider} is having trouble',
          'The provider is returning server errors. '
              'This is on their end — try again in a few minutes.',
        ),
      _ => (
          'Request to ${e.provider} failed',
          e.message.isNotEmpty
              ? e.message
              : 'An unexpected error occurred. Try again.',
        ),
    };

    return UserFacingError(
      headline: headline,
      explanation: explanation,
      actionLabel: actionLabel ??
          (code == 401 || code == 403
              ? 'Open API Key Settings'
              : 'Retry'),
      onAction: onAction,
      severity: code >= 500
          ? AppStatusVariant.warning
          : AppStatusVariant.error,
      technicalDetails: _sanitize(e.technicalDetail),
    );
  }

  // ── Sanitisation ──────────────────────────────────────────────────────────

  static final RegExp _keyPattern = RegExp(
    r'(sk-[A-Za-z0-9\-_]{16,}|Bearer [A-Za-z0-9\-_\.]{8,}|AIza[A-Za-z0-9\-_]{32,})',
  );

  /// Redacts API key patterns from [raw] before exposing in the UI.
  static String? _sanitize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.replaceAll(_keyPattern, '[REDACTED]');
  }
}

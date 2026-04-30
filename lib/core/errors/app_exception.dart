// lib/core/errors/app_exception.dart

// Phase 11 OTA exception subclasses live in a part file so they can extend
// this sealed class while staying co-located with the updater feature.
// See lib/features/updater/data/updater_exceptions.dart and §14.3.
part '../../features/updater/data/updater_exceptions.dart';

sealed class AppException implements Exception {
  const AppException({
    required this.message,
    this.technicalDetail,
    this.stackTrace,
  });

  final String message;
  final String? technicalDetail;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException: $message';
}

final class ApiKeyNotFoundException extends AppException {
  const ApiKeyNotFoundException(this.provider)
      : super(
          message:
              'No API key found for $provider. Please add one in Settings → API Keys.',
        );

  final String provider;
}

final class ApiRequestException extends AppException {
  const ApiRequestException({
    required this.provider,
    this.statusCode,
    required super.message,
    this.rawResponseBody,
  }) : super(
          technicalDetail: rawResponseBody != null
              ? 'HTTP ${statusCode ?? '?'} · $provider\n\n$rawResponseBody'
              : 'HTTP ${statusCode ?? '?'} · $provider',
        );

  final String provider;
  final int? statusCode;

  /// Sanitized raw response body from the API (API key redacted).
  /// Populated whenever the provider returns a non-2xx response.
  final String? rawResponseBody;
}

final class DelegationException extends AppException {
  const DelegationException(String message) : super(message: message);
}

final class SecureStorageException extends AppException {
  const SecureStorageException(String message)
      : super(message: 'Secure storage error: $message');
}

final class AuthException extends AppException {
  const AuthException(String message) : super(message: message);
}

final class LicenseValidationException extends AppException {
  const LicenseValidationException(String message) : super(message: message);
}

final class DatabaseException extends AppException {
  const DatabaseException(String message) : super(message: message);
}

// lib/core/errors/error_handler.dart
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/utils/logger.dart';

abstract final class ErrorHandler {
  static String toUserMessage(Object error) {
    if (error is AppException) return error.message;

    AppLogger.e('ErrorHandler', 'Unhandled error type: ${error.runtimeType}', error);

    // Never leak raw stack traces or HTTP details to the user.
    return 'Something went wrong. Please try again or restart the app.';
  }
}

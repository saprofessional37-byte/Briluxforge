// lib/features/licensing/data/repositories/gumroad_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/utils/logger.dart';

class GumroadRepository {
  Future<GumroadValidationResult> verifyLicense({
    required String productId,
    required String licenseKey,
  }) async {
    AppLogger.i('GumroadRepository', 'Verifying license key (key length: ${licenseKey.length})');

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.gumroadVerifyUrl),
            body: {
              'product_id': productId,
              'license_key': licenseKey.trim(),
            },
          )
          .timeout(const Duration(seconds: 15));

      AppLogger.i('GumroadRepository', 'Gumroad response status: ${response.statusCode}');

      final data = jsonDecode(response.body) as Map<String, Object?>;
      final success = data['success'] as bool? ?? false;

      if (response.statusCode == 200 && success) {
        return const GumroadValidationResult(
          isValid: true,
          message: 'License activated.',
        );
      } else {
        final message = data['message'] as String? ?? 'Invalid license key.';
        return GumroadValidationResult(
          isValid: false,
          message: _userFriendlyError(message),
        );
      }
    } on http.ClientException catch (e) {
      AppLogger.w('GumroadRepository', 'Network error during license validation: $e');
      throw const LicenseValidationException(
        'Could not connect to the licensing server. Check your internet connection and try again.',
      );
    } catch (e) {
      AppLogger.e('GumroadRepository', 'Unexpected error during license validation', e);
      throw const LicenseValidationException(
        'License validation failed. Please try again.',
      );
    }
  }

  String _userFriendlyError(String raw) {
    if (raw.toLowerCase().contains('invalid') ||
        raw.toLowerCase().contains('not found')) {
      return 'This license key wasn\'t recognized. Check that you copied the full key from your Gumroad purchase email.';
    }
    if (raw.toLowerCase().contains('exceeded') ||
        raw.toLowerCase().contains('limit')) {
      return 'This license key has reached its activation limit. Contact support if this is an error.';
    }
    return 'License validation failed. Ensure you\'re using the exact key from your Gumroad purchase email.';
  }
}

class GumroadValidationResult {
  const GumroadValidationResult({
    required this.isValid,
    required this.message,
  });

  final bool isValid;
  final String message;
}

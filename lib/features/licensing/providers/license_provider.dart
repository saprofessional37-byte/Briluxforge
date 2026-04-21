// lib/features/licensing/providers/license_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/licensing/data/models/license_model.dart';
import 'package:briluxforge/features/licensing/data/repositories/gumroad_repository.dart';
import 'package:briluxforge/services/shared_prefs_provider.dart';

part 'license_provider.g.dart';

// Gumroad product ID — replace with actual product ID before shipping.
const String _gumroadProductId = 'REPLACE_WITH_GUMROAD_PRODUCT_ID';

abstract final class _PrefsKeys {
  static const String licenseStatus = 'license_status';
  static const String licenseKey = 'license_key';
  static const String licenseValidatedAt = 'license_validated_at';
  static const String trialStartDate = 'trial_start_date';
}

@riverpod
GumroadRepository gumroadRepository(Ref ref) => GumroadRepository();

@riverpod
class LicenseNotifier extends _$LicenseNotifier {
  @override
  Future<LicenseModel> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return _loadFromPrefs(prefs);
  }

  LicenseModel _loadFromPrefs(SharedPreferences prefs) {
    // If no trial start date, this is first launch — seed it now.
    if (!prefs.containsKey(_PrefsKeys.trialStartDate)) {
      prefs.setString(
        _PrefsKeys.trialStartDate,
        DateTime.now().toIso8601String(),
      );
      prefs.setString(_PrefsKeys.licenseStatus, 'trial');
      AppLogger.i('LicenseProvider', 'First launch — trial started.');
    }

    final model = LicenseModel.fromPrefs(
      statusRaw: prefs.getString(_PrefsKeys.licenseStatus),
      licenseKey: prefs.getString(_PrefsKeys.licenseKey),
      validatedAtRaw: prefs.getString(_PrefsKeys.licenseValidatedAt),
      trialStartRaw: prefs.getString(_PrefsKeys.trialStartDate),
    );

    AppLogger.i('LicenseProvider', 'License status: ${model.status}');

    // Background re-validation if needed (fire and forget).
    if (model.needsRevalidation && model.licenseKey != null) {
      _revalidateInBackground(model.licenseKey!);
    }

    return model;
  }

  Future<void> _revalidateInBackground(String key) async {
    AppLogger.i('LicenseProvider', 'Background re-validation triggered.');
    try {
      final result = await ref.read(gumroadRepositoryProvider).verifyLicense(
            productId: _gumroadProductId,
            licenseKey: key,
          );
      if (result.isValid) {
        await _persistActive(key);
        state = AsyncData(state.value!.copyWith(
          status: LicenseStatus.active,
          validatedAt: DateTime.now(),
        ));
      }
    } catch (e) {
      // Offline or Gumroad error — trust cached status within grace period.
      AppLogger.w('LicenseProvider', 'Background re-validation failed: $e');
    }
  }

  Future<void> activateLicense(String licenseKey) async {
    final oldState = state;
    state = const AsyncLoading();

    try {
      final result = await ref.read(gumroadRepositoryProvider).verifyLicense(
            productId: _gumroadProductId,
            licenseKey: licenseKey,
          );

      if (result.isValid) {
        await _persistActive(licenseKey);
        final current = oldState.valueOrNull;
        state = AsyncData(
          (current ?? LicenseModel.initial()).copyWith(
            status: LicenseStatus.active,
            licenseKey: licenseKey,
            validatedAt: DateTime.now(),
          ),
        );
      } else {
        state = oldState;
        throw Exception(result.message);
      }
    } catch (e) {
      state = oldState;
      rethrow;
    }
  }

  Future<void> _persistActive(String licenseKey) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_PrefsKeys.licenseStatus, 'active');
    await prefs.setString(_PrefsKeys.licenseKey, licenseKey);
    await prefs.setString(
      _PrefsKeys.licenseValidatedAt,
      DateTime.now().toIso8601String(),
    );
  }
}

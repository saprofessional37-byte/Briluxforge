// lib/features/licensing/data/models/license_model.dart
import 'package:flutter/foundation.dart';
import 'package:briluxforge/core/constants/app_constants.dart';

enum LicenseStatus { trial, active, expired, unknown }

@immutable
class LicenseModel {
  const LicenseModel({
    required this.status,
    required this.trialStartDate,
    this.licenseKey,
    this.validatedAt,
  });

  factory LicenseModel.initial() => LicenseModel(
        status: LicenseStatus.trial,
        trialStartDate: DateTime.now(),
      );

  factory LicenseModel.fromPrefs({
    required String? statusRaw,
    required String? licenseKey,
    required String? validatedAtRaw,
    required String? trialStartRaw,
  }) {
    final trialStart =
        trialStartRaw != null ? DateTime.tryParse(trialStartRaw) : null;
    final validatedAt =
        validatedAtRaw != null ? DateTime.tryParse(validatedAtRaw) : null;

    LicenseStatus status;
    if (statusRaw == 'active') {
      // Check offline grace: if validatedAt is older than 7 days, downgrade.
      if (validatedAt != null) {
        final daysSinceValidation =
            DateTime.now().difference(validatedAt).inDays;
        status = daysSinceValidation <= AppConstants.offlineLicenseGraceDays
            ? LicenseStatus.active
            : LicenseStatus.unknown;
      } else {
        status = LicenseStatus.unknown;
      }
    } else if (statusRaw == 'trial') {
      final start = trialStart ?? DateTime.now();
      final daysSinceStart = DateTime.now().difference(start).inDays;
      status = daysSinceStart < AppConstants.trialDurationDays
          ? LicenseStatus.trial
          : LicenseStatus.expired;
    } else if (statusRaw == 'expired') {
      status = LicenseStatus.expired;
    } else {
      status = LicenseStatus.trial;
    }

    return LicenseModel(
      status: status,
      trialStartDate: trialStart ?? DateTime.now(),
      licenseKey: licenseKey,
      validatedAt: validatedAt,
    );
  }

  final LicenseStatus status;
  final DateTime trialStartDate;
  final String? licenseKey;
  final DateTime? validatedAt;

  bool get isAccessAllowed =>
      status == LicenseStatus.trial || status == LicenseStatus.active;

  bool get isTrialActive => status == LicenseStatus.trial;

  bool get isActiveLicense => status == LicenseStatus.active;

  int get trialDaysRemaining {
    final elapsed = DateTime.now().difference(trialStartDate).inDays;
    return (AppConstants.trialDurationDays - elapsed).clamp(0, AppConstants.trialDurationDays);
  }

  bool get needsRevalidation {
    if (status != LicenseStatus.active) return false;
    if (validatedAt == null) return true;
    return DateTime.now().difference(validatedAt!).inHours >=
        AppConstants.licenseRevalidationHours;
  }

  LicenseModel copyWith({
    LicenseStatus? status,
    DateTime? trialStartDate,
    String? licenseKey,
    DateTime? validatedAt,
  }) =>
      LicenseModel(
        status: status ?? this.status,
        trialStartDate: trialStartDate ?? this.trialStartDate,
        licenseKey: licenseKey ?? this.licenseKey,
        validatedAt: validatedAt ?? this.validatedAt,
      );
}

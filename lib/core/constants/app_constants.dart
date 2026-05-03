// lib/core/constants/app_constants.dart

abstract final class AppConstants {
  static const String appName = 'Briluxforge';
  static const String appVersion = '1.0.0';

  static const double minWindowWidth = 900;
  // Phase 13: raised from 600 to 640 to give the Wrap-based use-case grid
  // enough headroom without scroll at minimum window size.
  static const double minWindowHeight = 640;

  static const double sidebarWidth = 260;
  static const double maxChatContentWidth = 760;

  static const int trialDurationDays = 7;
  static const int licenseRevalidationHours = 24;
  static const int offlineLicenseGraceDays = 7;

  // Phase 13: recalibrated for normalized [0.0, 1.0] scoring. The old 0.70 raw-
  // sum threshold is impossible to reach with 20+ keywords per category. 0.05
  // means "at least 5 % of the category's total weight was matched."
  static const double delegationConfidenceThreshold = 0.05;
  static const double apiTiageConfidenceThreshold = 0.50;
  static const int longContextTokenThreshold = 30000;
  static const int hugeContextTokenThreshold = 100000;
  static const int apiTriageMaxPromptChars = 500;

  static const String gumroadVerifyUrl =
      'https://api.gumroad.com/v2/licenses/verify';
  static const String gumroadCheckoutUrl = 'https://briluxlabs.com/buy';

  static const double subscriptionMonthlyEquivalent = 20.0;

  // ── Phase 13 — Admin Brain Management ────────────────────────────────────

  /// Admin email. Paired with the admin secret held in flutter_secure_storage
  /// to compute the SHA-256 gate hash that unlocks the Delegation Inspector.
  static const String kAdminEmail = 'saprofessional37@gmail.com';

  /// SHA-256 of `kAdminEmail:adminSecret` (lowercase email, ':' delimiter).
  /// Default secret: briluxadmin2026. Regenerate with:
  ///   echo -n 'email:secret' | sha256sum
  static const String kAdminGateHash =
      '1ca94ba0ab79f7cc6a209bb4d33785ee089cb733aa1a5f598ec18c86bc539900';

  /// Maximum number of delegation decision log entries kept in memory.
  static const int kDecisionLogCap = 100;
}

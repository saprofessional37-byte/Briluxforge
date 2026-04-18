// lib/core/constants/app_constants.dart

abstract final class AppConstants {
  static const String appName = 'Briluxforge';
  static const String appVersion = '1.0.0';

  static const double minWindowWidth = 900;
  static const double minWindowHeight = 600;

  static const double sidebarWidth = 260;
  static const double maxChatContentWidth = 760;

  static const int trialDurationDays = 7;
  static const int licenseRevalidationHours = 24;
  static const int offlineLicenseGraceDays = 7;

  static const double delegationConfidenceThreshold = 0.70;
  static const double apiTiageConfidenceThreshold = 0.50;
  static const int longContextTokenThreshold = 30000;
  static const int hugeContextTokenThreshold = 100000;
  static const int apiTriageMaxPromptChars = 500;

  static const String gumroadVerifyUrl = 'https://api.gumroad.com/v2/licenses/verify';
  static const String gumroadCheckoutUrl = 'https://briluxforge.app/buy';

  static const double subscriptionMonthlyEquivalent = 20.0;
}

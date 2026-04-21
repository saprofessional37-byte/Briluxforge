// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDim = Color(0xFF4B44CC);
  static const Color accent = Color(0xFF00D4AA);

  // Dark theme surfaces
  static const Color backgroundDark = Color(0xFF0F0F12);
  static const Color surfaceDark = Color(0xFF16161A);
  static const Color surfaceElevatedDark = Color(0xFF1C1C22);
  static const Color sidebarDark = Color(0xFF13131A);
  static const Color borderDark = Color(0xFF2A2A35);
  static const Color dividerDark = Color(0xFF1E1E28);

  // Light theme surfaces
  static const Color backgroundLight = Color(0xFFF8F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF0F0F8);
  static const Color sidebarLight = Color(0xFFF2F2F8);
  static const Color borderLight = Color(0xFFE2E2ED);
  static const Color dividerLight = Color(0xFFECECF4);

  // Text — dark theme
  static const Color textPrimaryDark = Color(0xFFF2F2F7);
  static const Color textSecondaryDark = Color(0xFF8E8EA0);
  static const Color textTertiaryDark = Color(0xFF5C5C70);
  static const Color textDisabledDark = Color(0xFF3A3A4A);

  // Text — light theme
  static const Color textPrimaryLight = Color(0xFF0F0F1A);
  static const Color textSecondaryLight = Color(0xFF6B6B80);
  static const Color textTertiaryLight = Color(0xFF9A9AB0);
  static const Color textDisabledLight = Color(0xFFBBBBCC);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Code block
  static const Color codeBlockBackgroundDark = Color(0xFF0D0D12);
  static const Color codeBlockBackgroundLight = Color(0xFFF0F0F8);

  // Delegation badge
  static const Color delegationBadgeBg = Color(0xFF1A1A28);
  static const Color delegationBadgeText = Color(0xFF8E8EA0);

  // Savings
  static const Color savingsGreen = Color(0xFF00D4AA);
  static const Color savingsGreenDim = Color(0xFF00A882);

  // ── Input field contrast helpers (WCAG AA/AAA verified) ──────────────────
  //
  // Dark fill:  0xFF1E1E2A — lum ≈ 0.013 (very dark)
  // Dark hint:  0xFF9898B0 — lum ≈ 0.34  → contrast ≈ 6.2:1 (AA ✓)
  // Dark body:  textPrimaryDark (0xFFF2F2F7) — contrast ≈ 15:1 (AAA ✓)
  //
  // Light fill: 0xFFEAEAF5 — lum ≈ 0.84  (slightly darker than scaffold)
  // Light hint: 0xFF5E5E78 — lum ≈ 0.126 → contrast ≈ 5.0:1 (AA ✓)
  // Light body: textPrimaryLight (0xFF0F0F1A) — contrast ≈ 17:1 (AAA ✓)

  static Color inputFill(bool isDark) =>
      isDark ? const Color(0xFF1E1E2A) : const Color(0xFFEAEAF5);

  static Color inputHint(bool isDark) =>
      isDark ? const Color(0xFF9898B0) : const Color(0xFF5E5E78);

  static Color inputLabel(bool isDark) =>
      isDark ? const Color(0xFFB0B0C8) : const Color(0xFF4A4A60);

  static Color inputBorder(bool isDark) =>
      isDark ? const Color(0xFF2E2E42) : const Color(0xFFCCCCDC);

  static Color onSurface(bool isDark) =>
      isDark ? textPrimaryDark : textPrimaryLight;

  static Color outline(bool isDark) =>
      isDark ? const Color(0xFF3A3A50) : const Color(0xFFB8B8CC);
}

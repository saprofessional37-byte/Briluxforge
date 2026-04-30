// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Raw palette (kept for legacy references during migration) ─────────────

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

  // Semantic raw hues (prefer role tokens for status UI)
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

  // ── Phase 12 — Semantic role tokens ──────────────────────────────────────

  // Surface hierarchy
  static const Color surfaceBase    = Color(0xFF0E0E10); // scaffold
  static const Color surfaceRaised  = Color(0xFF17171A); // cards, panels
  static const Color surfaceOverlay = Color(0xFF1E1E22); // dialogs, popovers

  // Borders
  static const Color borderSubtle = Color(0x0FFFFFFF); // white @ 6%
  static const Color borderStrong = Color(0x24FFFFFF); // white @ 14%

  // Text roles (dark theme semantic aliases; suffixed variants above for light)
  static const Color textPrimary    = Color(0xEBF2F2F7); // white @ 92%
  static const Color textSecondary  = Color(0xA3F2F2F7); // white @ 64%
  static const Color textTertiary   = Color(0x61F2F2F7); // white @ 38%

  // Brand roles
  /// Brand colour at 85% saturation — accents, focus rings, active states.
  static const Color brandPrimary      = Color(0xFF6660E0);

  /// Muted brand for primary button fills — avoids neon-on-dark vibration.
  static const Color brandPrimaryMuted = Color(0xFF4E49C8);

  // Status triads — background / foreground / border
  static const Color statusSuccessBg     = Color(0x1F22C55E); // 12% opacity
  static const Color statusSuccessFg     = Color(0xFF4ADE80);
  static const Color statusSuccessBorder = Color(0x3D22C55E); // 24% opacity

  static const Color statusErrorBg     = Color(0x1FEF4444);
  static const Color statusErrorFg     = Color(0xFFF87171);
  static const Color statusErrorBorder = Color(0x3DEF4444);

  static const Color statusWarnBg     = Color(0x1FF59E0B);
  static const Color statusWarnFg     = Color(0xFFFBBF24);
  static const Color statusWarnBorder = Color(0x3DF59E0B);

  static const Color statusInfoBg     = Color(0x1F3B82F6);
  static const Color statusInfoFg     = Color(0xFF60A5FA);
  static const Color statusInfoBorder = Color(0x3D3B82F6);

  // ── Input field contrast helpers (WCAG AA/AAA verified) ──────────────────
  //
  // Dark fill:  0xFF1E1E2A — contrast ≈ 6.2:1 (AA ✓)
  // Light fill: 0xFFEAEAF5 — contrast ≈ 5.0:1 (AA ✓)

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

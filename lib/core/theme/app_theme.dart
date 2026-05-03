// lib/core/theme/app_theme.dart
// Phase 13 §13.6: lightTheme getter removed — app is locked to dark mode
// pending a per-screen light-theme audit. The isDark-parameterised AppColors
// getters (app_colors.dart) are retained so light mode can be re-enabled with
// ~30 lines of changes when a dedicated audit phase runs.
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.brandPrimary,
        scaffoldBackgroundColor: AppColors.surfaceBase,
        textTheme: AppTypography.textTheme,
        cardTheme: const CardThemeData(
          color: AppColors.surfaceRaised,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
            side: BorderSide(color: AppColors.borderSubtle),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderSubtle,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill(true),
          hintStyle: TextStyle(color: AppColors.inputHint(true)),
          labelStyle: TextStyle(color: AppColors.inputLabel(true)),
          floatingLabelStyle: const TextStyle(color: AppColors.brandPrimary),
          border: const OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide:
                BorderSide(color: AppColors.brandPrimary, width: 1.5),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.statusErrorFg),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide:
                BorderSide(color: AppColors.statusErrorFg, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimaryMuted,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandPrimaryMuted,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.borderSubtle),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandPrimary,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: 20,
        ),
        tooltipTheme: const TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.surfaceOverlay,
            borderRadius: AppRadii.borderSm,
            border: Border.fromBorderSide(BorderSide(color: AppColors.borderSubtle)),
          ),
          textStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: AppColors.surfaceOverlay,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
            side: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.surfaceOverlay,
          contentTextStyle: TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
          behavior: SnackBarBehavior.floating,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.textTertiaryDark;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.brandPrimary;
            }
            return AppColors.surfaceOverlay;
          }),
        ),
      );
}

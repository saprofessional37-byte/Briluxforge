// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_typography.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: AppTypography.textTheme,
        cardTheme: CardThemeData(
          color: AppColors.surfaceElevatedDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderDark),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.dividerDark,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill(true),
          hintStyle: TextStyle(color: AppColors.inputHint(true)),
          labelStyle: TextStyle(color: AppColors.inputLabel(true)),
          floatingLabelStyle: const TextStyle(color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.inputBorder(true)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.inputBorder(true)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface(true),
            side: BorderSide(color: AppColors.outline(true)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondaryDark,
          size: 20,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderDark),
          ),
          textStyle: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 12,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderDark),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceElevatedDark,
          contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return AppColors.textTertiaryDark;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary.withValues(alpha: 0.3);
            }
            return AppColors.surfaceElevatedDark;
          }),
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: AppTypography.textTheme,
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.dividerLight,
          thickness: 1,
          space: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputFill(false),
          hintStyle: TextStyle(color: AppColors.inputHint(false)),
          labelStyle: TextStyle(color: AppColors.inputLabel(false)),
          floatingLabelStyle: const TextStyle(color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.inputBorder(false)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.inputBorder(false)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface(false),
            side: BorderSide(color: AppColors.outline(false)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondaryLight,
          size: 20,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          textStyle: const TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 12,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderLight),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          contentTextStyle: const TextStyle(color: AppColors.textPrimaryLight),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return AppColors.textTertiaryLight;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary.withValues(alpha: 0.3);
            }
            return AppColors.surfaceElevatedLight;
          }),
        ),
      );
}

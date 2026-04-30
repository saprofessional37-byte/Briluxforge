// lib/core/theme/app_theme.dart
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
        cardTheme: CardThemeData(
          color: AppColors.surfaceRaised,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
            side: const BorderSide(color: AppColors.borderSubtle),
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
          border: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.inputBorder(true)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.inputBorder(true)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide:
                const BorderSide(color: AppColors.brandPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: const BorderSide(color: AppColors.statusErrorFg),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide:
                const BorderSide(color: AppColors.statusErrorFg, width: 1.5),
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
            shape:
                RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
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
            shape:
                RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.borderSubtle),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
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
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.surfaceOverlay,
            borderRadius: AppRadii.borderSm,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surfaceOverlay,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
            side: const BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceOverlay,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape:
              RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
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

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppColors.brandPrimary,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: AppTypography.textTheme,
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.borderMd,
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
          floatingLabelStyle: const TextStyle(color: AppColors.brandPrimary),
          border: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.inputBorder(false)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.inputBorder(false)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide:
                const BorderSide(color: AppColors.brandPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
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
            shape:
                RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
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
            shape:
                RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.onSurface(false),
            side: BorderSide(color: AppColors.outline(false)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
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
          color: AppColors.textSecondaryLight,
          size: 20,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadii.borderSm,
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
            borderRadius: AppRadii.borderMd,
            side: const BorderSide(color: AppColors.borderLight),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          contentTextStyle: const TextStyle(color: AppColors.textPrimaryLight),
          shape:
              RoundedRectangleBorder(borderRadius: AppRadii.borderSm),
          behavior: SnackBarBehavior.floating,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.textTertiaryLight;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.brandPrimary;
            }
            return AppColors.surfaceElevatedLight;
          }),
        ),
      );
}

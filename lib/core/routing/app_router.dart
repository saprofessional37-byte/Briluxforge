// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';

import 'package:briluxforge/features/api_keys/presentation/api_key_screen.dart';
import 'package:briluxforge/features/auth/presentation/login_screen.dart';
import 'package:briluxforge/features/auth/presentation/signup_screen.dart';
import 'package:briluxforge/features/home/home_screen.dart';
import 'package:briluxforge/features/licensing/presentation/license_key_input_screen.dart';
import 'package:briluxforge/features/onboarding/presentation/onboarding_screen.dart';
import 'package:briluxforge/features/settings/presentation/settings_screen.dart';
import 'package:briluxforge/features/skills/presentation/skill_editor_screen.dart';
import 'package:briluxforge/features/skills/presentation/skills_screen.dart';

abstract final class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String licenseKeyInput = '/license-key-input';
  static const String apiKeys = '/api-keys';
  static const String settings = '/settings';
  static const String skills = '/skills';
  static const String skillEditor = '/skill-editor';
}

Route<Object?> onGenerateRoute(RouteSettings settings) {
  return switch (settings.name) {
    AppRoutes.login => _fade(const LoginScreen()),
    AppRoutes.signup => _fade(const SignupScreen()),
    AppRoutes.onboarding => _fade(const OnboardingScreen()),
    AppRoutes.home => _fade(const HomeScreen()),
    AppRoutes.licenseKeyInput =>
      _fade(_buildLicenseKeyInput(settings.arguments)),
    AppRoutes.apiKeys => _slide(const ApiKeyScreen()),
    AppRoutes.settings => _slide(const SettingsScreen()),
    AppRoutes.skills => _slide(const SkillsScreen()),
    AppRoutes.skillEditor =>
      _slide(_buildSkillEditor(settings.arguments)),
    _ => _fade(const LoginScreen()),
  };
}

Widget _buildLicenseKeyInput(Object? args) {
  final isDismissable =
      args is LicenseKeyInputArgs ? args.isDismissable : true;
  return LicenseKeyInputScreen(isDismissable: isDismissable);
}

Widget _buildSkillEditor(Object? args) {
  final skill = args is SkillEditorArgs ? args.skill : null;
  return SkillEditorScreen(skill: skill);
}

PageRoute<T> _fade<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 200),
    );

/// Slide-from-right transition for detail screens.
PageRoute<T> _slide<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );

// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_theme.dart';
import 'package:briluxforge/features/auth/data/models/user_model.dart';
import 'package:briluxforge/features/auth/presentation/login_screen.dart';
import 'package:briluxforge/features/auth/providers/auth_provider.dart';
import 'package:briluxforge/features/chat/providers/chat_provider.dart';
import 'package:briluxforge/features/home/home_screen.dart';
import 'package:briluxforge/features/licensing/presentation/license_key_input_screen.dart';
import 'package:briluxforge/features/licensing/providers/license_provider.dart';
import 'package:briluxforge/features/onboarding/presentation/onboarding_screen.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';
import 'package:briluxforge/features/settings/providers/settings_provider.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When auth transitions from null → user (signup / login), pop any routes
    // that were pushed on top of the AuthGate root.
    ref.listen<AsyncValue<UserModel?>>(authStateProvider, (previous, next) {
      final hadUser = previous?.valueOrNull != null;
      final hasUser = next.valueOrNull != null;
      if (!hadUser && hasUser) {
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });

    final isDark =
        ref.watch(settingsNotifierProvider).valueOrNull?.isDarkTheme ?? true;

    // Build the window title from the active conversation.
    final conversationTitle = ref
        .watch(chatNotifierProvider.select((s) => s.conversation?.title));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      navigatorKey: _navigatorKey,
      onGenerateTitle: (_) => conversationTitle != null
          ? 'Briluxforge — $conversationTitle'
          : 'Briluxforge',
      home: const _AuthGate(),
      onGenerateRoute: onGenerateRoute,
    );
  }
}

/// Declarative root — watches auth, onboarding, and license state and
/// returns the correct screen. AuthGate is never pushed as a named route.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (user == null) return const LoginScreen();

        final onboardingAsync = ref.watch(onboardingNotifierProvider);
        return onboardingAsync.when(
          loading: () => const _SplashScreen(),
          error: (_, __) => const HomeScreen(),
          data: (onboarding) {
            if (!onboarding.hasCompleted) return const OnboardingScreen();

            final licenseAsync = ref.watch(licenseNotifierProvider);
            return licenseAsync.when(
              loading: () => const _SplashScreen(),
              error: (_, __) => const HomeScreen(),
              data: (license) {
                if (!license.isAccessAllowed) {
                  return const LicenseKeyInputScreen(isDismissable: false);
                }

                // Run the DefaultModelReconciler before allowing chat access.
                // Never blocks on error — a reconciler failure must not prevent
                // the user from reaching the home screen.
                final reconcilerAsync =
                    ref.watch(defaultModelReconcilerProvider);
                return reconcilerAsync.when(
                  loading: () => const _SplashScreen(),
                  error: (_, __) => const HomeScreen(),
                  data: (_) => const HomeScreen(),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

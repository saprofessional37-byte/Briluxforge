// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/auth/presentation/widgets/auth_form.dart';
import 'package:briluxforge/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
      _resetEmailSent = false;
    });
    try {
      await ref.read(authRepositoryProvider).logIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // AuthGate will redirect automatically via stream.
    } catch (e) {
      AppLogger.e('LoginScreen', 'Login failed', e);
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email above, then tap Forgot Password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (mounted) {
        setState(() {
          _resetEmailSent = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Row(
        children: [
          const _BrandPanel(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _FormPanel(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    loading: _loading,
                    error: _error,
                    resetEmailSent: _resetEmailSent,
                    onLogin: _logIn,
                    onForgotPassword: _sendPasswordReset,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      decoration: const BoxDecoration(
        color: AppColors.sidebarDark,
        border: Border(right: BorderSide(color: AppColors.borderDark)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Route every prompt to the right model.\nAutomatically.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.6,
                  ),
            ),
          ),
          const SizedBox(height: 56),
          const _FeaturePill(icon: Icons.auto_awesome_outlined, label: 'Smart delegation'),
          const SizedBox(height: 10),
          const _FeaturePill(icon: Icons.savings_outlined, label: 'Tracks your savings'),
          const SizedBox(height: 10),
          const _FeaturePill(icon: Icons.psychology_outlined, label: 'Customisable skills'),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
        ],
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.loading,
    required this.error,
    required this.resetEmailSent,
    required this.onLogin,
    required this.onForgotPassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool loading;
  final String? error;
  final bool resetEmailSent;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Log in to your Briluxforge account.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 36),
          BriluxTextField(
            controller: emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autofocus: true,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!v.contains('@')) return 'Enter a valid email address.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          BriluxPasswordField(
            controller: passwordController,
            label: 'Password',
            hint: '••••••••',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => onLogin(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required.';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading ? null : onForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            AuthErrorCard(message: error!),
          ],
          if (resetEmailSent) ...[
            const SizedBox(height: 16),
            const AuthSuccessCard(
              message: 'Password reset email sent. Check your inbox.',
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: loading ? null : onLogin,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Log In'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account?",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signup),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Start free trial',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

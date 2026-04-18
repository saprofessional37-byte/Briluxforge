// lib/features/auth/presentation/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/auth/presentation/widgets/auth_form.dart';
import 'package:briluxforge/features/auth/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // AuthGate will redirect automatically via stream.
    } catch (e) {
      AppLogger.e('SignupScreen', 'Signup failed', e);
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
                  child: _SignupForm(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmController: _confirmController,
                    loading: _loading,
                    error: _error,
                    onSignUp: _signUp,
                    onLogIn: () => Navigator.of(context).pop(),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 28),
            Text(
              'Start your free trial.',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'No credit card required.\n7 days full access, then decide.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 48),
            const _IncludedItem(
              icon: Icons.check_circle_outline,
              label: 'Full access to all features',
            ),
            const SizedBox(height: 12),
            const _IncludedItem(
              icon: Icons.check_circle_outline,
              label: 'Connect your own API keys',
            ),
            const SizedBox(height: 12),
            const _IncludedItem(
              icon: Icons.check_circle_outline,
              label: 'Everything stored locally',
            ),
            const SizedBox(height: 12),
            const _IncludedItem(
              icon: Icons.check_circle_outline,
              label: 'Cancel anytime — no commitment',
            ),
          ],
        ),
      ),
    );
  }
}

class _IncludedItem extends StatelessWidget {
  const _IncludedItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.success),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
        ),
      ],
    );
  }
}

class _SignupForm extends StatelessWidget {
  const _SignupForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.loading,
    required this.error,
    required this.onSignUp,
    required this.onLogIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool loading;
  final String? error;
  final VoidCallback onSignUp;
  final VoidCallback onLogIn;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create account',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start your 7-day free trial today.',
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
            autofillHints: const [AutofillHints.newUsername],
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
            hint: 'At least 6 characters',
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required.';
              if (v.length < 6) return 'Password must be at least 6 characters.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          BriluxPasswordField(
            controller: confirmController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => onSignUp(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password.';
              if (v != passwordController.text) return 'Passwords do not match.';
              return null;
            },
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            AuthErrorCard(message: error!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: loading ? null : onSignUp,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Account — Free Trial'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No credit card required.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),
              TextButton(
                onPressed: onLogIn,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Log in',
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

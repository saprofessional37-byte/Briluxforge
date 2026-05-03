// FILE: lib/features/licensing/presentation/license_key_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/errors/error_translator.dart';
import 'package:briluxforge/core/errors/user_facing_error.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/core/widgets/app_button.dart';
import 'package:briluxforge/core/widgets/app_error_display.dart';
import 'package:briluxforge/core/widgets/app_status_card.dart';
import 'package:briluxforge/features/licensing/providers/license_provider.dart';

/// Route argument — always pass via Navigator args.
class LicenseKeyInputArgs {
  const LicenseKeyInputArgs({required this.isDismissable});

  final bool isDismissable;
}

class LicenseKeyInputScreen extends ConsumerStatefulWidget {
  const LicenseKeyInputScreen({required this.isDismissable, super.key});

  final bool isDismissable;

  @override
  ConsumerState<LicenseKeyInputScreen> createState() =>
      _LicenseKeyInputScreenState();
}

class _LicenseKeyInputScreenState
    extends ConsumerState<LicenseKeyInputScreen> {
  final _keyController = TextEditingController();
  bool _loading = false;

  /// Non-null when an activation attempt failed.
  UserFacingError? _error;

  bool _success = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _error = const UserFacingError(
          headline: 'License key required',
          explanation: 'Please paste your Gumroad license key before activating.',
          actionLabel: 'Dismiss',
          severity: AppStatusVariant.warning,
        );
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = false;
    });

    try {
      await ref.read(licenseNotifierProvider.notifier).activateLicense(key);
      if (mounted) {
        setState(() {
          _loading = false;
          _success = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        if (mounted && widget.isDismissable) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      AppLogger.e('LicenseKeyInputScreen', 'License activation failed', e);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e is AppException
              ? ErrorTranslator.translate(
                  e,
                  onAction: _activate,
                  actionLabel: 'Try again',
                )
              : UserFacingError(
                  headline: 'License activation failed',
                  explanation:
                      'Could not verify your license key. Make sure it is entered exactly as received from Gumroad.',
                  actionLabel: 'Try again',
                  onAction: _activate,
                  severity: AppStatusVariant.error,
                );
        });
      }
    }
  }

  Future<void> _openPurchasePage() async {
    final uri = Uri.parse(AppConstants.gumroadCheckoutUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: widget.isDismissable
          ? AppBar(
              backgroundColor: AppColors.surfaceBase,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppColors.textSecondary,
                tooltip: 'Back',
              ),
              title: Text(
                'License',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                if (!widget.isDismissable) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.statusWarnBg,
                      borderRadius: AppRadii.borderMd,
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.statusWarnFg,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Trial Expired',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your free trial has ended. Activate a license to continue using Briluxforge.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ] else ...[
                  Text(
                    'Activate License',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Paste your Gumroad license key below.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // ── Input card ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceRaised
                        : AppColors.surfaceLight,
                    borderRadius: AppRadii.borderMd,
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderSubtle
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paste your Gumroad License Key',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _keyController,
                        enabled: !_loading && !_success,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontFamily: 'JetBrains Mono',
                            ),
                        decoration: InputDecoration(
                          hintText: 'XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX',
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontFamily: 'JetBrains Mono',
                                  ),
                        ),
                        onSubmitted: (_) => _activate(),
                      ),

                      // Error display
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppErrorDisplay(error: _error!),
                      ],

                      // Success banner
                      if (_success) ...[
                        const SizedBox(height: AppSpacing.md),
                        const AppStatusCard(
                          variant: AppStatusVariant.success,
                          title: 'License activated',
                          body: 'Welcome to Briluxforge!',
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // Primary action button
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: _success ? 'Activated' : 'Activate License',
                          onPressed: (_loading || _success) ? null : _activate,
                          isLoading: _loading,
                          size: AppButtonSize.large,
                          leadingIcon: _success
                              ? Icons.check_circle_outline
                              : null,
                        ),
                      ),

                      // Secondary action — dismiss to free trial
                      if (widget.isDismissable) ...[
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Continue Free Trial',
                            onPressed:
                                _loading ? null : () => Navigator.of(context).pop(),
                            variant: AppButtonVariant.secondary,
                            size: AppButtonSize.large,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Purchase link ────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _openPurchasePage,
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have a license? ",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        children: [
                          TextSpan(
                            text: 'Purchase at briluxlabs.com/buy →',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

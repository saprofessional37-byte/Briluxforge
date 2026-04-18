// lib/features/licensing/presentation/license_key_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/auth/presentation/widgets/auth_form.dart';
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

class _LicenseKeyInputScreenState extends ConsumerState<LicenseKeyInputScreen> {
  final _keyController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Please paste your license key.');
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
          _error = e.toString().replaceFirst('Exception: ', '');
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: widget.isDismissable
          ? AppBar(
              backgroundColor: AppColors.backgroundDark,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppColors.textSecondaryDark,
                tooltip: 'Back',
              ),
              title: Text(
                'License',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
              ),
            )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isDismissable) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Trial Expired',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.textPrimaryDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your free trial has ended. Activate a license to continue using Briluxforge.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryDark,
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 36),
                ] else ...[
                  Text(
                    'Activate License',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimaryDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Paste your Gumroad license key below.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryDark,
                        ),
                  ),
                  const SizedBox(height: 28),
                ],
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paste your Gumroad License Key',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keyController,
                        enabled: !_loading && !_success,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimaryDark,
                              fontFamily: 'monospace',
                            ),
                        decoration: InputDecoration(
                          hintText: 'XXXXXXXX-XXXXXXXX-XXXXXXXX-XXXXXXXX',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textTertiaryDark,
                                fontFamily: 'monospace',
                              ),
                        ),
                        onSubmitted: (_) => _activate(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        AuthErrorCard(message: _error!),
                      ],
                      if (_success) ...[
                        const SizedBox(height: 14),
                        const AuthSuccessCard(
                          message: 'License activated. Welcome to Briluxforge!',
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton(
                          onPressed: _loading || _success ? null : _activate,
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : _success
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_outline, size: 16),
                                        SizedBox(width: 8),
                                        Text('Activated'),
                                      ],
                                    )
                                  : const Text('Activate License'),
                        ),
                      ),
                      if (widget.isDismissable) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: _loading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Continue Free Trial'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: _openPurchasePage,
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have a license? ",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryDark,
                            ),
                        children: [
                          TextSpan(
                            text: 'Purchase at briluxforge.app/buy →',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
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

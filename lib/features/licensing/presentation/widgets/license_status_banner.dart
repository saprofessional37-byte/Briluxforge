// lib/features/licensing/presentation/widgets/license_status_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/licensing/presentation/license_key_input_screen.dart';
import 'package:briluxforge/features/licensing/providers/license_provider.dart';

/// Shows a subtle dismissable banner at the top of the chat area during trial.
/// Hidden when license is active or status is unknown.
class LicenseStatusBanner extends ConsumerWidget {
  const LicenseStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseAsync = ref.watch(licenseNotifierProvider);

    return licenseAsync.when(
      data: (license) {
        if (!license.isTrialActive) return const SizedBox.shrink();
        return _TrialBanner(daysRemaining: license.trialDaysRemaining);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TrialBanner extends StatefulWidget {
  const _TrialBanner({required this.daysRemaining});

  final int daysRemaining;

  @override
  State<_TrialBanner> createState() => _TrialBannerState();
}

class _TrialBannerState extends State<_TrialBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final urgencyColor = widget.daysRemaining <= 2
        ? AppColors.warning
        : AppColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: urgencyColor.withValues(alpha: 0.08),
          border: Border(
            bottom: BorderSide(color: urgencyColor.withValues(alpha: 0.25)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            Icon(
              Icons.access_time_outlined,
              size: 14,
              color: urgencyColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.daysRemaining == 0
                    ? 'Your free trial ends today.'
                    : 'Your free trial expires in ${widget.daysRemaining} day${widget.daysRemaining == 1 ? '' : 's'}.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: urgencyColor,
                    ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.licenseKeyInput,
                arguments: const LicenseKeyInputArgs(isDismissable: true),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: urgencyColor,
              ),
              child: Text(
                'Upgrade →',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: urgencyColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => setState(() => _dismissed = true),
              icon: const Icon(Icons.close, size: 14),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(4),
                minimumSize: Size.zero,
                foregroundColor: urgencyColor,
              ),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}

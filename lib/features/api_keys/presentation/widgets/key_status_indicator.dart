// lib/features/api_keys/presentation/widgets/key_status_indicator.dart
import 'package:flutter/material.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';

/// Pill-shaped status badge for an API key. Shown inside [ApiKeyCard] and
/// the onboarding add-key panel.
class KeyStatusIndicator extends StatelessWidget {
  const KeyStatusIndicator({
    required this.status,
    this.showLabel = true,
    super.key,
  });

  final VerificationStatus status;

  /// When false, only the icon/spinner is shown (compact mode).
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      VerificationStatus.verified => _Chip(
          icon: Icons.check_circle_outline_rounded,
          label: 'Connected',
          color: AppColors.success,
          showLabel: showLabel,
        ),
      VerificationStatus.failed => _Chip(
          icon: Icons.error_outline_rounded,
          label: 'Failed',
          color: AppColors.error,
          showLabel: showLabel,
        ),
      VerificationStatus.verifying => _Chip(
          icon: null,
          label: 'Verifying…',
          color: AppColors.info,
          showLabel: showLabel,
          isLoading: true,
        ),
      VerificationStatus.unverified => _Chip(
          icon: Icons.radio_button_unchecked_rounded,
          label: 'Not verified',
          color: AppColors.textTertiaryDark,
          showLabel: showLabel,
        ),
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.showLabel,
    this.isLoading = false,
  });

  final IconData? icon;
  final String label;
  final Color color;
  final bool showLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 10 : 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else if (icon != null)
            Icon(icon, size: 12, color: color),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

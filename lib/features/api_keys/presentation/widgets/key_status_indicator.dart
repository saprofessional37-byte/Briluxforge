// lib/features/api_keys/presentation/widgets/key_status_indicator.dart
import 'package:flutter/material.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';

/// Pill-shaped status badge for an API key.
class KeyStatusIndicator extends StatelessWidget {
  const KeyStatusIndicator({
    required this.status,
    this.showLabel = true,
    super.key,
  });

  final VerificationStatus status;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      VerificationStatus.verified => _Chip(
          icon: Icons.check_circle_outline_rounded,
          label: 'Connected',
          fg: AppColors.statusSuccessFg,
          bg: AppColors.statusSuccessBg,
          border: AppColors.statusSuccessBorder,
          showLabel: showLabel,
        ),
      VerificationStatus.failed => _Chip(
          icon: Icons.error_outline_rounded,
          label: 'Failed',
          fg: AppColors.statusErrorFg,
          bg: AppColors.statusErrorBg,
          border: AppColors.statusErrorBorder,
          showLabel: showLabel,
        ),
      VerificationStatus.verifying => _Chip(
          icon: null,
          label: 'Verifying…',
          fg: AppColors.statusInfoFg,
          bg: AppColors.statusInfoBg,
          border: AppColors.statusInfoBorder,
          showLabel: showLabel,
          isLoading: true,
        ),
      VerificationStatus.unverified => _Chip(
          icon: Icons.radio_button_unchecked_rounded,
          label: 'Not verified',
          fg: AppColors.textTertiaryDark,
          bg: Colors.transparent,
          border: AppColors.borderSubtle,
          showLabel: showLabel,
        ),
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    required this.border,
    required this.showLabel,
    this.isLoading = false,
  });

  final IconData? icon;
  final String label;
  final Color fg;
  final Color bg;
  final Color border;
  final bool showLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? AppSpacing.sm + 2 : AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.borderXs,
        border: Border.all(color: border),
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
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            )
          else if (icon != null)
            Icon(icon, size: 12, color: fg),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

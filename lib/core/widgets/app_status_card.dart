// lib/core/widgets/app_status_card.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';

enum AppStatusVariant { success, error, warning, info }

/// Tinted status banner — hue wash background + muted foreground text.
/// Replaces inline neon-border error containers throughout the codebase.
class AppStatusCard extends StatelessWidget {
  const AppStatusCard({
    required this.variant,
    required this.title,
    this.body,
    super.key,
  });

  final AppStatusVariant variant;
  final String title;
  final String? body;

  Color get _bg => switch (variant) {
        AppStatusVariant.success => AppColors.statusSuccessBg,
        AppStatusVariant.error   => AppColors.statusErrorBg,
        AppStatusVariant.warning => AppColors.statusWarnBg,
        AppStatusVariant.info    => AppColors.statusInfoBg,
      };

  Color get _border => switch (variant) {
        AppStatusVariant.success => AppColors.statusSuccessBorder,
        AppStatusVariant.error   => AppColors.statusErrorBorder,
        AppStatusVariant.warning => AppColors.statusWarnBorder,
        AppStatusVariant.info    => AppColors.statusInfoBorder,
      };

  Color get _fg => switch (variant) {
        AppStatusVariant.success => AppColors.statusSuccessFg,
        AppStatusVariant.error   => AppColors.statusErrorFg,
        AppStatusVariant.warning => AppColors.statusWarnFg,
        AppStatusVariant.info    => AppColors.statusInfoFg,
      };

  IconData get _icon => switch (variant) {
        AppStatusVariant.success => Icons.check_circle_outline_rounded,
        AppStatusVariant.error   => Icons.error_outline_rounded,
        AppStatusVariant.warning => Icons.warning_amber_rounded,
        AppStatusVariant.info    => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 16, color: _fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    body!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryDark,
                          height: 1.5,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

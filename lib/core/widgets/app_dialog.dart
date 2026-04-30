// lib/core/widgets/app_dialog.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_button.dart';

/// Universal dialog shell. Max 560px wide, max 80% screen height, scrollable body.
///
/// Every [showDialog] call in the codebase must use [showAppDialog] — raw
/// [AlertDialog] and [Dialog] are banned in feature code.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.body,
    this.primaryAction,
    this.secondaryAction,
    this.maxWidth = 560,
    this.maxHeightFactor = 0.8,
    super.key,
  });

  final String title;
  final Widget body;
  final _DialogAction? primaryAction;
  final _DialogAction? secondaryAction;
  final double maxWidth;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceOverlay : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderSubtle : AppColors.borderLight;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.borderMd,
        side: BorderSide(color: border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: screenHeight * maxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            // Scrollable body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: body,
              ),
            ),
            // Footer actions
            if (primaryAction != null || secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (secondaryAction != null) ...[
                      AppButton(
                        label: secondaryAction!.label,
                        onPressed: secondaryAction!.onPressed,
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.compact,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (primaryAction != null)
                      AppButton(
                        label: primaryAction!.label,
                        onPressed: primaryAction!.onPressed,
                        variant: primaryAction!.isDestructive
                            ? AppButtonVariant.primary
                            : AppButtonVariant.primary,
                        size: AppButtonSize.compact,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogAction {
  const _DialogAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;
}

/// Shows an [AppDialog]. Use this instead of raw [showDialog] everywhere.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget body,
  String? primaryLabel,
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  bool barrierDismissible = true,
  double maxWidth = 560,
  double maxHeightFactor = 0.8,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => AppDialog(
      title: title,
      body: body,
      maxWidth: maxWidth,
      maxHeightFactor: maxHeightFactor,
      primaryAction: primaryLabel != null
          ? _DialogAction(label: primaryLabel, onPressed: onPrimary)
          : null,
      secondaryAction: secondaryLabel != null
          ? _DialogAction(label: secondaryLabel, onPressed: onSecondary)
          : null,
    ),
  );
}

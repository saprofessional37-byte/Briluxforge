// FILE: lib/features/delegation/presentation/widgets/delegation_failure_dialog.dart
import 'package:flutter/material.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_dialog.dart';

/// The two possible choices from [DelegationFailureDialog].
enum DelegationFailureChoice { useDefault, useAI }

/// Result record returned when the dialog closes.
typedef DelegationDialogResult = ({
  DelegationFailureChoice choice,
  bool remember,
});

/// Namespace for the delegation-failure dialog.
///
/// Shown when the delegation engine's confidence is below threshold and it
/// cannot automatically decide which model to use.  Gives the user two
/// options:
///   1. Use Default — instant, zero extra cost.
///   2. Let AI Decide — sends a short meta-prompt to the best connected model.
///
/// Also offers a "Remember this choice" checkbox so power users can suppress
/// the dialog for future similar prompts.
abstract final class DelegationFailureDialog {
  const DelegationFailureDialog._();

  /// Shows the dialog and returns the user's choice, or null if dismissed.
  static Future<DelegationDialogResult?> show(
    BuildContext context, {
    required String defaultModelName,
    required String bestModelName,
  }) {
    return showAppDialog<DelegationDialogResult>(
      context: context,
      title: 'Not sure which model is best',
      barrierDismissible: false,
      maxWidth: 440,
      body: _DelegationDialogBody(
        defaultModelName: defaultModelName,
        bestModelName: bestModelName,
      ),
    );
  }
}

// ── Dialog body — stateful so it can manage the remember checkbox ─────────────

class _DelegationDialogBody extends StatefulWidget {
  const _DelegationDialogBody({
    required this.defaultModelName,
    required this.bestModelName,
  });

  final String defaultModelName;
  final String bestModelName;

  @override
  State<_DelegationDialogBody> createState() => _DelegationDialogBodyState();
}

class _DelegationDialogBodyState extends State<_DelegationDialogBody> {
  bool _remember = false;

  void _close(DelegationFailureChoice choice) {
    Navigator.of(context)
        .pop<DelegationDialogResult>((choice: choice, remember: _remember));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.borderSubtle : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Explanation text with inline warning indicator
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: AppColors.statusWarnFg,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                "I couldn't determine the best model for this prompt with "
                'enough confidence. Choose how to proceed:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textSecondary,
                      height: 1.5,
                    ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Choice cards ─────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.accent,
                title: 'Use Default',
                subtitle: widget.defaultModelName,
                badge: 'Free · instant',
                badgeColor: AppColors.accent,
                onTap: () => _close(DelegationFailureChoice.useDefault),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ChoiceCard(
                icon: Icons.auto_awesome_rounded,
                iconColor: AppColors.brandPrimary,
                title: 'Let AI Decide',
                subtitle: widget.bestModelName,
                badge: 'Few tokens',
                badgeColor: AppColors.brandPrimary,
                onTap: () => _close(DelegationFailureChoice.useAI),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Remember checkbox ─────────────────────────────────────────────────
        InkWell(
          onTap: () => setState(() => _remember = !_remember),
          borderRadius: AppRadii.borderSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _remember,
                    onChanged: (v) =>
                        setState(() => _remember = v ?? false),
                    activeColor: AppColors.brandPrimary,
                    side: BorderSide(color: borderColor, width: 1.5),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadii.borderXs,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Remember this choice for similar prompts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ),

        // Spacer so footer padding in AppDialog looks correct
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}

// ── Choice card widget ─────────────────────────────────────────────────────────

class _ChoiceCard extends StatefulWidget {
  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.borderSubtle : AppColors.borderLight;
    final bgColor = isDark ? AppColors.surfaceOverlay : AppColors.surfaceElevatedLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.iconColor.withValues(alpha: 0.08)
              : bgColor,
          borderRadius: AppRadii.borderMd,
          border: Border.all(
            color: _hovered
                ? widget.iconColor.withValues(alpha: 0.5)
                : borderColor,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadii.borderMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 18),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: widget.badgeColor.withValues(alpha: 0.12),
                        // Chip badge: use borderLg so it reads as a rounded
                        // label chip without being a full pill.
                        borderRadius: AppRadii.borderLg,
                      ),
                      child: Text(
                        widget.badge,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: widget.badgeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// lib/features/delegation/presentation/widgets/delegation_failure_dialog.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';

/// The two possible choices from [DelegationFailureDialog].
enum DelegationFailureChoice { useDefault, useAI }

/// Result record returned when the dialog closes.
typedef DelegationDialogResult = ({
  DelegationFailureChoice choice,
  bool remember,
});

/// Shown when the delegation engine's confidence is below the threshold and
/// it cannot automatically decide which model to use.
///
/// Gives the user two options:
///   1. Use Default — instant, zero extra cost.
///   2. Let AI Decide — sends a short meta-prompt to the best connected model.
///
/// Also offers a "Remember this choice" checkbox so power users can suppress
/// the dialog for future similar prompts.
class DelegationFailureDialog extends StatefulWidget {
  const DelegationFailureDialog({
    super.key,
    required this.defaultModelName,
    required this.bestModelName,
  });

  final String defaultModelName;
  final String bestModelName;

  /// Shows the dialog and returns the user's choice, or null if dismissed.
  static Future<DelegationDialogResult?> show(
    BuildContext context, {
    required String defaultModelName,
    required String bestModelName,
  }) {
    return showDialog<DelegationDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DelegationFailureDialog(
        defaultModelName: defaultModelName,
        bestModelName: bestModelName,
      ),
    );
  }

  @override
  State<DelegationFailureDialog> createState() =>
      _DelegationFailureDialogState();
}

class _DelegationFailureDialogState extends State<DelegationFailureDialog> {
  bool _remember = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Dialog(
      backgroundColor: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Not sure which model is best',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "I couldn't determine the best model for this prompt with enough "
                'confidence. Choose how to proceed:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // ── Choice buttons ───────────────────────────────────────────────
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceCard(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: AppColors.primary,
                      title: 'Let AI Decide',
                      subtitle: widget.bestModelName,
                      badge: 'Few tokens',
                      badgeColor: AppColors.primary,
                      onTap: () => _close(DelegationFailureChoice.useAI),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Remember checkbox ───────────────────────────────────────────
              InkWell(
                onTap: () => setState(() => _remember = !_remember),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _remember,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                          activeColor: AppColors.primary,
                          side: BorderSide(color: borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Remember this choice for similar prompts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _close(DelegationFailureChoice choice) {
    Navigator.of(context).pop((choice: choice, remember: _remember));
  }
}

// ── Choice card widget ─────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final bgColor = isDark
        ? AppColors.surfaceElevatedDark
        : AppColors.surfaceElevatedLight;
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered ? widget.iconColor.withValues(alpha: 0.5) : borderColor,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 18),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: widget.badgeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
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

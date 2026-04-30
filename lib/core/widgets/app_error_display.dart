// lib/core/widgets/app_error_display.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:briluxforge/core/errors/user_facing_error.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_button.dart';
import 'package:briluxforge/core/widgets/app_status_card.dart';

/// Structured error presentation.
/// Three-part schema: headline / explanation / action button.
/// Optional collapsed technical-details disclosure (monospace, selectable, copyable).
class AppErrorDisplay extends StatefulWidget {
  const AppErrorDisplay({
    required this.error,
    super.key,
  });

  final UserFacingError error;

  @override
  State<AppErrorDisplay> createState() => _AppErrorDisplayState();
}

class _AppErrorDisplayState extends State<AppErrorDisplay> {
  bool _detailsExpanded = false;
  bool _copied = false;

  Color get _fgColor => switch (widget.error.severity) {
        AppStatusVariant.success => AppColors.statusSuccessFg,
        AppStatusVariant.error   => AppColors.statusErrorFg,
        AppStatusVariant.warning => AppColors.statusWarnFg,
        AppStatusVariant.info    => AppColors.statusInfoFg,
      };

  Color get _bgColor => switch (widget.error.severity) {
        AppStatusVariant.success => AppColors.statusSuccessBg,
        AppStatusVariant.error   => AppColors.statusErrorBg,
        AppStatusVariant.warning => AppColors.statusWarnBg,
        AppStatusVariant.info    => AppColors.statusInfoBg,
      };

  Color get _borderColor => switch (widget.error.severity) {
        AppStatusVariant.success => AppColors.statusSuccessBorder,
        AppStatusVariant.error   => AppColors.statusErrorBorder,
        AppStatusVariant.warning => AppColors.statusWarnBorder,
        AppStatusVariant.info    => AppColors.statusInfoBorder,
      };

  IconData get _icon => switch (widget.error.severity) {
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
        color: _bgColor,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row — icon + headline
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, size: 16, color: _fgColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.error.headline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Explanation
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              widget.error.explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.5,
                  ),
            ),
          ),

          // Action button
          if (widget.error.onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: AppButton(
                label: widget.error.actionLabel,
                onPressed: widget.error.onAction,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.compact,
              ),
            ),
          ],

          // Technical details disclosure
          if (widget.error.technicalDetails != null) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () =>
                  setState(() => _detailsExpanded = !_detailsExpanded),
              child: Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _detailsExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: AppColors.textTertiaryDark,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      _detailsExpanded
                          ? 'Hide technical details'
                          : 'View technical details',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiaryDark,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _detailsExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(
                          left: 24, top: AppSpacing.sm),
                      child: _TechDetailsBlock(
                        details: widget.error.technicalDetails!,
                        copied: _copied,
                        onCopy: _handleCopy,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(
        ClipboardData(text: widget.error.technicalDetails!));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }
}

// ── Technical details block ────────────────────────────────────────────────

class _TechDetailsBlock extends StatelessWidget {
  const _TechDetailsBlock({
    required this.details,
    required this.copied,
    required this.onCopy,
  });

  final String details;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Technical details',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                          fontFamily: 'JetBrains Mono',
                        ),
                  ),
                ),
                GestureDetector(
                  onTap: onCopy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      copied
                          ? Icons.check_rounded
                          : Icons.copy_outlined,
                      key: ValueKey(copied),
                      size: 14,
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          // Scrollable monospace content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: SelectableText(
                details,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontFamily: 'JetBrains Mono',
                      color: AppColors.textSecondaryDark,
                      height: 1.6,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

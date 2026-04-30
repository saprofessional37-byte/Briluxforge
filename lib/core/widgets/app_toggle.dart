// lib/core/widgets/app_toggle.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';

/// Compact desktop toggle — 36×20px track, 16px thumb, 150ms ease-out.
/// Replaces every [Switch] widget in the codebase.
class AppToggle extends StatelessWidget {
  const AppToggle({
    required this.value,
    required this.onChanged,
    this.label,
    this.description,
    super.key,
  });

  final bool value;
  final void Function(bool) onChanged;

  /// When provided, renders a two-line label row to the left of the track.
  final String? label;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = _ToggleTrack(value: value, isDark: isDark);

    if (label == null) {
      return GestureDetector(
        onTap: () => onChanged(!value),
        child: track,
      );
    }

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadii.borderSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              onTap: () => onChanged(!value),
              child: track,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTrack extends StatelessWidget {
  const _ToggleTrack({required this.value, required this.isDark});

  final bool value;
  final bool isDark;

  static const double _trackWidth = 36;
  static const double _trackHeight = 20;
  static const double _thumbSize = 16;
  static const double _thumbPadding = 2;

  @override
  Widget build(BuildContext context) {
    final trackOn = AppColors.brandPrimary.withValues(alpha: 0.85);
    final trackOff =
        isDark ? AppColors.surfaceOverlay : AppColors.surfaceElevatedLight;
    final borderOff = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: _trackWidth,
      height: _trackHeight,
      decoration: BoxDecoration(
        color: value ? trackOn : trackOff,
        borderRadius:
            const BorderRadius.all(Radius.circular(_trackHeight / 2)),
        border: value ? null : Border.all(color: borderOff),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(_thumbPadding),
          child: Container(
            width: _thumbSize,
            height: _thumbSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: AppElevation.subtle,
            ),
          ),
        ),
      ),
    );
  }
}

// lib/features/updater/presentation/widgets/update_progress_bar.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §8.5

import 'package:flutter/material.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';

/// Themed animated progress bar for the updater UI.
///
/// Pass [progress] as a 0.0–1.0 double for the determinate variant.
/// Pass `null` for the indeterminate (sweeping) variant.
///
/// Width fills the available space. Height is fixed at [AppSpacing.sm] (8 px).
/// The determinate fill interpolates via [AnimatedContainer] — no custom paint.
class UpdateProgressBar extends StatelessWidget {
  const UpdateProgressBar({
    super.key,
    this.progress,
  });

  /// 0.0–1.0 for determinate; null for indeterminate.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      // Indeterminate — delegate to Material's LinearProgressIndicator.
      return const LinearProgressIndicator(
        backgroundColor: AppColors.borderDark,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
        minHeight: AppSpacing.sm,
        borderRadius: AppRadii.borderXs,
      );
    }

    final clamped = progress!.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = totalWidth * clamped;

        return Container(
          height: AppSpacing.sm,
          width: totalWidth,
          decoration: const BoxDecoration(
            color: AppColors.borderDark,
            borderRadius: AppRadii.borderXs,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: AppSpacing.sm,
              width: filledWidth,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                borderRadius: AppRadii.borderXs,
              ),
            ),
          ),
        );
      },
    );
  }
}

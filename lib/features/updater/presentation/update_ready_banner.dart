// lib/features/updater/presentation/update_ready_banner.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §8.1

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/features/updater/data/models/update_state.dart';
import 'package:briluxforge/features/updater/presentation/update_modal.dart';
import 'package:briluxforge/features/updater/presentation/widgets/update_status_dot.dart';
import 'package:briluxforge/features/updater/providers/updater_provider.dart';

/// Sidebar-footer composite: status dot + optional single-row banner.
///
/// Placement: in the sidebar footer, immediately to the left of
/// `SavingsTrackerWidget` (see home screen sidebar — outside Phase 11.9
/// scope; the sidebar must include this widget at that position).
///
/// Visibility:
/// - Hidden (zero-size) when state is [UpdateIdle] or [UpdateFailed].
/// - Dot only (no text banner) while [UpdateDownloading] / [UpdateVerifying].
///   A tooltip on hover shows "Downloading update… 47%".
/// - Full banner when [UpdateReady]: dot + title + subtitle + chevron.
///   Tapping opens [showUpdateModal].
///
/// All transitions use [AnimatedSwitcher] (200 ms, easeOutCubic) per §8.5.
class UpdateReadyBanner extends ConsumerWidget {
  const UpdateReadyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(updaterProvider);
    final state = stateAsync.valueOrNull;

    final visible = state is UpdateDownloading ||
        state is UpdateVerifying ||
        state is UpdateReady;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: visible
          ? _BannerContent(key: const ValueKey('banner'), state: state!)
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BannerContent extends ConsumerWidget {
  const _BannerContent({super.key, required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = state is UpdateReady;

    final tooltipMessage = switch (state) {
      UpdateDownloading(:final progress) =>
        'Downloading update… ${(progress * 100).round()}%',
      UpdateVerifying() => 'Verifying update…',
      UpdateReady() => 'Update ready to install',
      _ => '',
    };

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltipMessage,
        child: InkWell(
          onTap: isReady
              ? () => showUpdateModal(context, state as UpdateReady)
              : null,
          borderRadius: AppRadii.borderSm,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: AppRadii.borderSm,
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UpdateStatusDot(isReady: isReady),
                const SizedBox(width: AppSpacing.sm),
                if (isReady) ...[
                  _ReadyText(version: (state as UpdateReady).targetVersion),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textTertiaryDark,
                  ),
                ] else
                  _DownloadingText(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Text sub-widgets ──────────────────────────────────────────────────────────

class _ReadyText extends StatelessWidget {
  const _ReadyText({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Update ready — v$version',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'Restart to install',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
        ),
      ],
    );
  }
}

class _DownloadingText extends StatelessWidget {
  const _DownloadingText({required this.state});

  final UpdateState state;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      UpdateDownloading(:final progress) =>
        'Downloading update… ${(progress * 100).round()}%',
      UpdateVerifying() => 'Verifying…',
      _ => 'Preparing…',
    };

    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiaryDark,
          ),
    );
  }
}

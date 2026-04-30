// lib/features/updater/presentation/update_modal.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §8.1

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_spacing.dart';
import 'package:briluxforge/features/updater/data/models/update_state.dart';
import 'package:briluxforge/features/updater/presentation/widgets/release_notes_view.dart';
import 'package:briluxforge/features/updater/providers/updater_provider.dart';

/// Shows the update-ready modal as a themed dialog.
///
/// Strings per §8.6. Width 480 px, elevation-2 shadow, 12 px border radius.
/// "Later" dismisses the dialog (banner stays visible). "Restart & Install"
/// triggers [updaterProvider.notifier.startInstall] then closes the dialog.
Future<void> showUpdateModal(
  BuildContext context,
  UpdateReady state,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _UpdateModal(state: state),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _UpdateModal extends ConsumerWidget {
  const _UpdateModal({required this.state});

  final UpdateReady state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Derive the installed version for the subtitle from the updater state.
    // At the time this modal is shown the state is UpdateReady; fall back to
    // the compile-time AppConstants.appVersion (which is the binary's version
    // — i.e., the version we're about to replace).
    final updaterState = ref.watch(updaterProvider).valueOrNull;
    final installedVersion = updaterState is UpdateIdle
        ? updaterState.installedVersion
        : AppConstants.appVersion;

    return Dialog(
      backgroundColor: AppColors.surfaceElevatedDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderDark),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──────────────────────────────────────────────────────
              Text(
                'Briluxforge ${state.targetVersion} is ready',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimaryDark,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Subtitle ───────────────────────────────────────────────────
              Text(
                "You're on $installedVersion. Restart to install.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              const Divider(color: AppColors.dividerDark, height: 1),
              const SizedBox(height: AppSpacing.md),

              // ── Release notes ──────────────────────────────────────────────
              ReleaseNotesView(markdown: state.releaseNotesMarkdown),

              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.dividerDark, height: 1),
              const SizedBox(height: AppSpacing.lg),

              // ── Footer buttons ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryDark,
                    ),
                    child: const Text('Later'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref
                          .read(updaterProvider.notifier)
                          .startInstall();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Restart & Install'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

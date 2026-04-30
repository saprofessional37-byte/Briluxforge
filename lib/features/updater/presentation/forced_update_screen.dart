// lib/features/updater/presentation/forced_update_screen.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §8.3

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_spacing.dart';
import 'package:briluxforge/features/updater/data/models/update_state.dart';
import 'package:briluxforge/features/updater/presentation/widgets/release_notes_view.dart';
import 'package:briluxforge/features/updater/presentation/widgets/update_progress_bar.dart';
import 'package:briluxforge/features/updater/providers/updater_provider.dart';

// ── UpdateGate ────────────────────────────────────────────────────────────────

/// Wraps the app's home content and enforces forced-update blocking (§8.3).
///
/// Once [UpdateForced] is detected on the [updaterProvider] stream, this
/// widget permanently replaces its [child] with [_ForcedUpdateScreen] for the
/// lifetime of the process. Forced mode is a one-way latch — it never reverts
/// short of an app restart initiated by the platform installer.
///
/// Additionally, when [UpdateInstalling] is active (from either a normal or
/// forced update), the widget shows [_InstallingOverlay] — the full-screen
/// "Installing update…" overlay described in §8.1 step 5.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  /// One-way latch: once true, stays true until process exit.
  bool _inForcedMode = false;

  @override
  Widget build(BuildContext context) {
    // Listen for UpdateForced — the state may be brief before transitioning
    // to UpdateDownloading, so ref.listen catches it even if watch misses it.
    ref.listen<AsyncValue<UpdateState>>(updaterProvider, (_, next) {
      final state = next.valueOrNull;
      if (state is UpdateForced && !_inForcedMode) {
        setState(() => _inForcedMode = true);
      }
    });

    final state = ref.watch(updaterProvider).valueOrNull;

    // Also check current value in case we are resuming after a hot-restart
    // where the stream already emitted UpdateForced.
    if (state is UpdateForced && !_inForcedMode) {
      _inForcedMode = true;
    }

    // Installing overlay — shown for both normal and forced installs.
    if (state is UpdateInstalling) {
      return _InstallingOverlay(targetVersion: state.targetVersion);
    }

    // Forced update screen — once latched, never returns to child.
    if (_inForcedMode) {
      return const _ForcedUpdateScreen();
    }

    return widget.child;
  }
}

// ── _InstallingOverlay ────────────────────────────────────────────────────────

/// Full-screen overlay shown while the platform installer is taking over.
///
/// §8.1 step 5: solid scaffold-background colour, centred column, no
/// close button, no cancel. The process exits within 1–3 s.
class _InstallingOverlay extends StatelessWidget {
  const _InstallingOverlay({required this.targetVersion});

  final String targetVersion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.bolt, color: Colors.white, size: 32),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Title
            Text(
              'Installing update\u2026',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Indeterminate progress bar
            SizedBox(
              width: 280,
              child: const UpdateProgressBar(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Subtitle
            Text(
              'This will take a few seconds.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ForcedUpdateScreen ───────────────────────────────────────────────────────

/// Full-screen blocker shown for forced updates (§8.3).
///
/// No sidebar. No dismiss button. No close X. No keyboard escape.
/// Download starts automatically via the service when [UpdateForced] fires.
/// The user either clicks "Restart & Install" when ready, or kills the app.
class _ForcedUpdateScreen extends ConsumerWidget {
  const _ForcedUpdateScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updaterProvider).valueOrNull;

    // Derive display fields from whatever state we're in — forced mode
    // progresses through UpdateForced → UpdateDownloading → UpdateVerifying
    // → UpdateReady while this screen remains visible.
    final targetVersion = switch (state) {
      UpdateForced(:final targetVersion) => targetVersion,
      UpdateDownloading(:final targetVersion) => targetVersion,
      UpdateVerifying(:final targetVersion) => targetVersion,
      UpdateReady(:final targetVersion) => targetVersion,
      UpdateInstalling(:final targetVersion) => targetVersion,
      _ => '',
    };

    final releaseNotesMarkdown = switch (state) {
      UpdateForced(:final releaseNotesMarkdown) => releaseNotesMarkdown,
      UpdateReady(:final releaseNotesMarkdown) => releaseNotesMarkdown,
      _ => '',
    };

    final isReady = state is UpdateReady;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxxl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── App logo ─────────────────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child:
                      const Icon(Icons.bolt, color: Colors.white, size: 32),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Title ─────────────────────────────────────────────────────
                Text(
                  'A required update is available',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Body ──────────────────────────────────────────────────────
                Text(
                  targetVersion.isNotEmpty
                      ? "We've released a critical fix for Briluxforge "
                          "$targetVersion. To keep your data and API keys "
                          'safe, this update must be installed before you '
                          'can continue.'
                      : 'A critical update must be installed before you '
                          'can continue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryDark,
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Progress bar / install button (animated swap) ─────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: isReady
                      ? _InstallButton(
                          key: const ValueKey('install_btn'),
                        )
                      : _DownloadProgress(
                          key: const ValueKey('dl_progress'),
                          state: state,
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── "Why is this required?" footer link ───────────────────────
                if (releaseNotesMarkdown.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showWhyModal(
                      context,
                      releaseNotesMarkdown,
                    ),
                    child: Text(
                      'Why is this required?',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiaryDark,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.textTertiaryDark,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the release-notes modal. Never hides the forced screen beneath.
  void _showWhyModal(BuildContext context, String markdown) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
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
                Text(
                  'Why is this required?',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                ReleaseNotesView(markdown: markdown),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondaryDark,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({super.key, required this.state});

  final UpdateState? state;

  @override
  Widget build(BuildContext context) {
    final progress = switch (state) {
      UpdateDownloading(:final progress) => progress,
      _ => null, // indeterminate
    };

    final label = switch (state) {
      UpdateDownloading(:final progress) =>
        'Downloading\u2026 ${(progress * 100).round()}%',
      UpdateVerifying() => 'Verifying update\u2026',
      UpdateForced() => 'Preparing download\u2026',
      UpdateChecking() => 'Checking for updates\u2026',
      _ => 'Preparing\u2026',
    };

    return Column(
      children: [
        SizedBox(
          width: 320,
          child: UpdateProgressBar(progress: progress),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
        ),
      ],
    );
  }
}

class _InstallButton extends ConsumerWidget {
  const _InstallButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () => ref.read(updaterProvider.notifier).startInstall(),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
      ),
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text('Restart & Install'),
    );
  }
}

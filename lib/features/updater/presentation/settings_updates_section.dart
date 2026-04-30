// lib/features/updater/presentation/settings_updates_section.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §8.2

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_spacing.dart';
import 'package:briluxforge/features/updater/data/models/update_state.dart';
import 'package:briluxforge/features/updater/data/update_constants.dart';
import 'package:briluxforge/features/updater/domain/updater_service.dart';
import 'package:briluxforge/features/updater/providers/updater_provider.dart';

/// Settings card for the OTA update system (§8.2).
///
/// Inserted into [SettingsScreen] between "Appearance" and "Features" (see
/// settings_screen.dart §5.2 allow-list modification).
///
/// Replicates the visual language of the adjacent settings cards — same
/// section header, card border, row dividers, and padding — so it blends
/// seamlessly without touching the private helpers in settings_screen.dart.
class SettingsUpdatesSection extends ConsumerStatefulWidget {
  const SettingsUpdatesSection({super.key});

  @override
  ConsumerState<SettingsUpdatesSection> createState() =>
      _SettingsUpdatesSectionState();
}

class _SettingsUpdatesSectionState
    extends ConsumerState<SettingsUpdatesSection> {
  bool _autoInstall = true;
  bool _prefsLoaded = false;
  bool _checkBusy = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _autoInstall = prefs.getBool('auto_install_updates') ?? true;
        _prefsLoaded = true;
      });
    }
  }

  Future<void> _setAutoInstall(bool value) async {
    setState(() => _autoInstall = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_install_updates', value);
  }

  Future<void> _checkNow() async {
    if (_checkBusy) return;
    setState(() => _checkBusy = true);

    try {
      await ref.read(updaterProvider.notifier).checkNow();

      // Yield one event-loop turn so any immediate download-progress emission
      // from the service reaches the stream before we read the state.
      await Future<void>.delayed(Duration.zero);

      if (!mounted) return;

      final state = ref.read(updaterProvider).valueOrNull;
      final message = _snackMessageFor(state);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.surfaceElevatedDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkBusy = false);
    }
  }

  String _snackMessageFor(UpdateState? state) => switch (state) {
        UpdateDownloading(:final targetVersion) =>
          'Update $targetVersion is downloading\u2026',
        UpdateReady(:final targetVersion) =>
          'Update $targetVersion is downloading\u2026',
        UpdateFailed(:final userMessage) => userMessage,
        _ => "You're up to date",
      };

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(updaterProvider);
    final state = stateAsync.valueOrNull;

    // Installed version: prefer the value baked into UpdateIdle (set from
    // PackageInfo at bootstrap); fall back to the compile-time constant.
    final installedVersion = switch (state) {
      UpdateIdle(:final installedVersion) => installedVersion,
      _ => AppConstants.appVersion,
    };

    final lastChecked = switch (state) {
      UpdateIdle(:final lastCheckAt) => lastCheckAt,
      _ => null,
    };

    final consecutiveFailures = UpdaterService.instance.consecutiveFailures;
    final showNetworkWarning =
        consecutiveFailures >= kConsecutiveFailureThreshold;

    final showDiskFullError = switch (state) {
      UpdateFailed(:final userMessage) =>
        userMessage.contains('disk space'),
      _ => false,
    };

    return _UpdatesSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Current version ───────────────────────────────────────────────
          _Row(
            child: Row(
              children: [
                Text(
                  'Current version',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                Text(
                  installedVersion,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ),
              ],
            ),
          ),

          // ── Last checked ──────────────────────────────────────────────────
          _Row(
            child: Row(
              children: [
                Text(
                  'Last checked',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                _LastCheckedLabel(lastCheckAt: lastChecked),
              ],
            ),
          ),

          // ── Auto-install toggle ───────────────────────────────────────────
          _Row(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Auto-install updates',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (_prefsLoaded)
                  Switch(
                    value: _autoInstall,
                    onChanged: _setAutoInstall,
                    activeColor: AppColors.primary,
                  )
                else
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),

          // ── Check button + disclosure ─────────────────────────────────────
          _Row(
            isLast: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: FilledButton.tonal(
                    onPressed: _checkBusy ? null : _checkNow,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: _checkBusy
                          ? const _CheckingLabel(key: ValueKey('busy'))
                          : const Text(
                              'Check for updates',
                              key: ValueKey('idle'),
                            ),
                    ),
                  ),
                ),

                // Network failure indicator (§8.4)
                if (showNetworkWarning) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "Couldn't reach the update server in the last 30 hours. "
                    "We'll keep trying.",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                          height: 1.5,
                        ),
                  ),
                ],

                // Disk-full error (§8.4)
                if (showDiskFullError) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "We couldn't make room for the update. Please free up "
                    'some disk space and try again.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.error,
                          height: 1.5,
                        ),
                  ),
                ],

                // Security disclosure (§8.6)
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Updates are signed and verified. Briluxforge never sends '
                  'your prompts, keys, or chat data to update servers.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiaryDark,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper: "Checking…" button label ─────────────────────────────────────────

class _CheckingLabel extends StatelessWidget {
  const _CheckingLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text('Checking\u2026'),
      ],
    );
  }
}

// ── Helper: last-checked relative time ───────────────────────────────────────

class _LastCheckedLabel extends StatelessWidget {
  const _LastCheckedLabel({super.key, required this.lastCheckAt});

  final DateTime? lastCheckAt;

  @override
  Widget build(BuildContext context) {
    final label =
        lastCheckAt != null ? _relative(lastCheckAt!) : 'Never';

    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryDark,
          ),
    );
  }

  static String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    final d = diff.inDays;
    return '$d day${d == 1 ? '' : 's'} ago';
  }
}

// ── Section card shell (mirrors _Section / _SectionRow in settings_screen) ───
//
// These private helpers replicate the visual pattern of the adjacent cards.
// They are NOT shared — the originals in settings_screen.dart are private.

class _UpdatesSectionCard extends StatelessWidget {
  const _UpdatesSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
          child: Text(
            'UPDATES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.child, this.isLast = false});

  final Widget child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: child,
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppColors.dividerDark,
          ),
      ],
    );
  }
}

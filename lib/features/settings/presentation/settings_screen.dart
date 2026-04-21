// lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';
import 'package:briluxforge/features/auth/providers/auth_provider.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';
import 'package:briluxforge/features/licensing/data/models/license_model.dart';
import 'package:briluxforge/features/licensing/providers/license_provider.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';
import 'package:briluxforge/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          const _SettingsHeader(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                  children: [
                    const SizedBox(height: 24),
                    const _AccountSection(),
                    const SizedBox(height: 4),
                    const _LicenseSection(),
                    const SizedBox(height: 4),
                    const _DefaultModelSection(),
                    const SizedBox(height: 4),
                    const _UseCaseSection(),
                    const SizedBox(height: 4),
                    const _AppearanceSection(),
                    const SizedBox(height: 4),
                    const _FeaturesSection(),
                    const SizedBox(height: 4),
                    const _HelpSection(),
                    const SizedBox(height: 4),
                    const _AboutSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondaryDark,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Section container ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
          child: Text(
            label.toUpperCase(),
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

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.child,
    this.onTap,
    this.isLast = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: child,
    );

    return Column(
      children: [
        if (onTap != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: isLast
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : BorderRadius.zero,
              child: content,
            ),
          )
        else
          content,
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

// ── Account section ───────────────────────────────────────────────────────────

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return _Section(
      label: 'Account',
      child: Column(
        children: [
          _SectionRow(
            child: authAsync.when(
              loading: () => const _RowLoadingPlaceholder(),
              error: (_, __) => const _RowErrorPlaceholder(
                message: 'Could not load account info.',
              ),
              data: (user) => Row(
                children: [
                  _Avatar(email: user?.email ?? ''),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Not signed in',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textPrimaryDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        Text(
                          'Signed in with email',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiaryDark,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SectionRow(
            isLast: true,
            onTap: () => _confirmLogout(context, ref),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevatedDark,
        title: Text(
          'Sign out?',
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimaryDark,
              ),
        ),
        content: Text(
          'Your API keys, chat history, and skills stay on this device.',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).logOut();
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final initial =
        email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ── License section ───────────────────────────────────────────────────────────

class _LicenseSection extends ConsumerWidget {
  const _LicenseSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseAsync = ref.watch(licenseNotifierProvider);

    return _Section(
      label: 'License',
      child: Column(
        children: [
          _SectionRow(
            child: licenseAsync.when(
              loading: () => const _RowLoadingPlaceholder(),
              error: (_, __) => const _RowErrorPlaceholder(
                message: 'Could not load license status.',
              ),
              data: (license) => Row(
                children: [
                  _LicenseStatusBadge(license: license),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _licenseTitle(license),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          _licenseSubtitle(license),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textTertiaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SectionRow(
            isLast: true,
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.licenseKeyInput),
            child: Row(
              children: [
                const Icon(
                  Icons.vpn_key_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Enter / Update License Key',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiaryDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _licenseTitle(LicenseModel license) => switch (license.status) {
        LicenseStatus.trial =>
          'Free Trial · ${license.trialDaysRemaining} day${license.trialDaysRemaining == 1 ? '' : 's'} remaining',
        LicenseStatus.active => 'Licensed · Full Access',
        LicenseStatus.expired => 'Trial Expired',
        LicenseStatus.unknown => 'Status Unknown',
      };

  String _licenseSubtitle(LicenseModel license) => switch (license.status) {
        LicenseStatus.trial =>
          'No credit card required during trial',
        LicenseStatus.active =>
          license.licenseKey != null
              ? 'Activated with Gumroad license key'
              : 'License active',
        LicenseStatus.expired => 'Activate a license key to continue',
        LicenseStatus.unknown =>
          'Re-validate when connected to the internet',
      };
}

class _LicenseStatusBadge extends StatelessWidget {
  const _LicenseStatusBadge({required this.license});

  final LicenseModel license;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (license.status) {
      LicenseStatus.trial => (AppColors.warning, Icons.hourglass_top_rounded),
      LicenseStatus.active => (AppColors.success, Icons.verified_rounded),
      LicenseStatus.expired => (AppColors.error, Icons.block_rounded),
      LicenseStatus.unknown => (AppColors.textTertiaryDark, Icons.help_outline),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ── Default model section ─────────────────────────────────────────────────────

class _DefaultModelSection extends ConsumerWidget {
  const _DefaultModelSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(modelProfilesProvider);
    final keysAsync = ref.watch(apiKeyNotifierProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return _Section(
      label: 'Default Model',
      child: _SectionRow(
        isLast: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fallback when delegation cannot decide',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
            ),
            const SizedBox(height: 10),
            profilesAsync.when(
              loading: () => const _RowLoadingPlaceholder(),
              error: (_, __) => const _RowErrorPlaceholder(
                message: 'Could not load model list.',
              ),
              data: (profiles) => keysAsync.when(
                loading: () => const _RowLoadingPlaceholder(),
                error: (_, __) => const _RowErrorPlaceholder(
                  message: 'Could not load API keys.',
                ),
                data: (keys) {
                  final verifiedProviders = keys
                      .where((k) => k.status == VerificationStatus.verified)
                      .map((k) => k.provider)
                      .toSet();

                  final availableModels = profiles.routeableModels
                      .where((m) => verifiedProviders.contains(m.provider))
                      .toList();

                  if (availableModels.isEmpty) {
                    return _NoModelsHint(
                      onAddKeys: () =>
                          Navigator.pushNamed(context, AppRoutes.apiKeys),
                    );
                  }

                  final currentId =
                      settingsAsync.valueOrNull?.defaultModelId ??
                          'deepseek-chat';

                  return _ModelDropdown(
                    models: availableModels,
                    currentId: currentId,
                    onChanged: (id) => ref
                        .read(settingsNotifierProvider.notifier)
                        .setDefaultModelId(id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelDropdown extends StatelessWidget {
  const _ModelDropdown({
    required this.models,
    required this.currentId,
    required this.onChanged,
  });

  final List<ModelProfile> models;
  final String currentId;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveId =
        models.any((m) => m.id == currentId) ? currentId : models.first.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveId,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevatedDark,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimaryDark,
              ),
          icon: const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.textSecondaryDark,
          ),
          items: models
              .map(
                (m) => DropdownMenuItem(
                  value: m.id,
                  child: Row(
                    children: [
                      _ProviderDot(provider: m.provider),
                      const SizedBox(width: 8),
                      Text(m.displayName),
                      const SizedBox(width: 8),
                      if (m.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _ProviderDot extends StatelessWidget {
  const _ProviderDot({required this.provider});

  final String provider;

  @override
  Widget build(BuildContext context) {
    final color = switch (provider) {
      'anthropic' => const Color(0xFFD97706),
      'openai' => const Color(0xFF10B981),
      'deepseek' => const Color(0xFF3B82F6),
      'google' => const Color(0xFF6366F1),
      'groq' => const Color(0xFFF59E0B),
      _ => AppColors.textTertiaryDark,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NoModelsHint extends StatelessWidget {
  const _NoModelsHint({required this.onAddKeys});

  final VoidCallback onAddKeys;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No API keys connected. Add keys to select a default model.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onAddKeys,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Add API Keys'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Use case section ──────────────────────────────────────────────────────────

class _UseCaseSection extends ConsumerWidget {
  const _UseCaseSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingNotifierProvider);

    return _Section(
      label: 'Use Case',
      child: onboardingAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: _RowLoadingPlaceholder(),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.all(16),
          child: _RowErrorPlaceholder(
            message: 'Could not load use case settings.',
          ),
        ),
        data: (onboarding) {
          final selected = onboarding.selectedUseCase;
          const cases = UseCaseType.values;

          return Column(
            children: cases.mapIndexed((i, useCase) {
              final isSelected = useCase == selected;
              final isLast = i == cases.length - 1;

              return _SectionRow(
                isLast: isLast,
                onTap: () {
                  ref
                      .read(onboardingNotifierProvider.notifier)
                      .selectUseCase(useCase);
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setDefaultModelId(useCase.defaultModelId);
                },
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.borderDark,
                          width: isSelected ? 5 : 2,
                        ),
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _useCaseIcon(useCase),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            useCase.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isSelected
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textSecondaryDark,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                          ),
                          Text(
                            useCase.description,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.textTertiaryDark,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _useCaseIcon(UseCaseType useCase) => switch (useCase) {
        UseCaseType.coding => '🖥️',
        UseCaseType.research => '🔬',
        UseCaseType.writing => '✍️',
        UseCaseType.building => '🏗️',
        UseCaseType.general => '🌐',
      };
}

// ── Appearance section ────────────────────────────────────────────────────────

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currentMode =
        settingsAsync.valueOrNull?.themeMode ?? ThemeMode.dark;

    return _Section(
      label: 'Appearance',
      child: _SectionRow(
        isLast: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.brightness_6_outlined,
                  size: 18,
                  color: AppColors.textSecondaryDark,
                ),
                const SizedBox(width: 12),
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined, size: 14),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined, size: 14),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined, size: 14),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: settingsAsync.isLoading
                  ? null
                  : (Set<ThemeMode> selection) => ref
                      .read(settingsNotifierProvider.notifier)
                      .setThemeMode(selection.first),
              style: ButtonStyle(
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Features section ──────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'Features',
      child: Column(
        children: [
          _SectionRow(
            onTap: () => Navigator.pushNamed(context, AppRoutes.skills),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  size: 18,
                  color: AppColors.textSecondaryDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skills',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      Text(
                        'Manage custom system prompt skills',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiaryDark,
                ),
              ],
            ),
          ),
          _SectionRow(
            isLast: true,
            onTap: () => Navigator.pushNamed(context, AppRoutes.apiKeys),
            child: Row(
              children: [
                const Icon(
                  Icons.key_rounded,
                  size: 18,
                  color: AppColors.textSecondaryDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Keys',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      Text(
                        'Add and manage your API provider keys',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiaryDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Help & tutorials section ──────────────────────────────────────────────────

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  // Placeholder URL — replace with actual tutorial URL when available.
  static const String _tutorialUrlPlaceholder = 'https://briluxforge.app/tutorials';

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'Help & Tutorials',
      child: Column(
        children: [
          _SectionRow(
            onTap: () => _openUrl(_tutorialUrlPlaceholder),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Tutorials',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      Text(
                        'Founder-recorded guides on setup and usage',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.textTertiaryDark,
                ),
              ],
            ),
          ),
          _SectionRow(
            isLast: true,
            onTap: () => _openUrl('https://briluxforge.app/docs'),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.article_outlined,
                    size: 20,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documentation',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      Text(
                        'Coming soon — placeholder for docs link',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.textTertiaryDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── About section ─────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'About',
      child: Column(
        children: [
          _SectionRow(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _SectionRow(
            isLast: true,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Multi-API AI router · Local-first · Zero backend prompt processing',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                          height: 1.5,
                        ),
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

// ── Shared placeholder widgets ────────────────────────────────────────────────

class _RowLoadingPlaceholder extends StatelessWidget {
  const _RowLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading…',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowErrorPlaceholder extends StatelessWidget {
  const _RowErrorPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline,
          size: 16,
          color: AppColors.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ),
      ],
    );
  }
}

// ── Iterable extension ────────────────────────────────────────────────────────

extension _IndexedMap<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) transform) {
    final result = <R>[];
    for (var i = 0; i < length; i++) {
      result.add(transform(i, this[i]));
    }
    return result;
  }
}

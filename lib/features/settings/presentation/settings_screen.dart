// FILE: lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_button.dart';
import 'package:briluxforge/core/widgets/app_dialog.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';
import 'package:briluxforge/features/auth/providers/auth_provider.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';
import 'package:briluxforge/features/licensing/data/models/license_model.dart';
import 'package:briluxforge/features/licensing/providers/license_provider.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';
import 'package:briluxforge/features/admin/providers/admin_provider.dart';
import 'package:briluxforge/features/settings/providers/settings_provider.dart';
import 'package:briluxforge/features/updater/presentation/settings_updates_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: Column(
        children: [
          const _SettingsHeader(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    const _AccountSection(),
                    const SizedBox(height: AppSpacing.xs),
                    const _LicenseSection(),
                    const SizedBox(height: AppSpacing.xs),
                    const _DefaultModelSection(),
                    const SizedBox(height: AppSpacing.xs),
                    const _UseCaseSection(),
                    const SizedBox(height: AppSpacing.xs),
                    const SettingsUpdatesSection(),
                    const SizedBox(height: AppSpacing.xs),
                    const _FeaturesSection(),
                    const SizedBox(height: AppSpacing.xs),
                    const _DeveloperSection(),
                    const SizedBox(height: AppSpacing.xs),
                    const _HelpSection(),
                    const SizedBox(height: AppSpacing.xs),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderSubtle : AppColors.borderLight,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(AppSpacing.sm),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Back',
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.sm),
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceRaised : AppColors.surfaceLight,
            borderRadius: AppRadii.borderMd,
            border: Border.all(
              color: isDark ? AppColors.borderSubtle : AppColors.borderLight,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor =
        isDark ? AppColors.borderSubtle : AppColors.borderLight;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
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
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadii.md),
                    )
                  : BorderRadius.zero,
              child: content,
            ),
          )
        else
          content,
        if (!isLast)
          Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: dividerColor,
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Not signed in',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          'Signed in with email',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textTertiary),
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
                  color: AppColors.statusErrorFg,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Sign Out',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.statusErrorFg,
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
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Sign out?',
      body: Text(
        'Your API keys, chat history, and skills stay on this device.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.pop(context, false),
      primaryLabel: 'Sign Out',
      onPrimary: () => Navigator.pop(context, true),
      maxWidth: 400,
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
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Container(
      width: 36,
      height: 36,
      // Avatar: fully-rounded containers are explicitly exempt per §12.4.2.
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.brandPrimary,
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
                  const SizedBox(width: AppSpacing.md),
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
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          _licenseSubtitle(license),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textTertiary),
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
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Enter / Update License Key',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiary,
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
        LicenseStatus.trial => 'No credit card required during trial',
        LicenseStatus.active => license.licenseKey != null
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
      LicenseStatus.trial =>
        (AppColors.statusWarnFg, Icons.hourglass_top_rounded),
      LicenseStatus.active =>
        (AppColors.statusSuccessFg, Icons.verified_rounded),
      LicenseStatus.expired =>
        (AppColors.statusErrorFg, Icons.block_rounded),
      LicenseStatus.unknown =>
        (AppColors.textTertiary, Icons.help_outline),
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderMd,
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
                    color: AppColors.textTertiary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
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
                      .where(
                          (m) => verifiedProviders.contains(m.provider))
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveId =
        models.any((m) => m.id == currentId) ? currentId : models.first.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceOverlay : AppColors.surfaceElevatedLight,
        borderRadius: AppRadii.borderMd,
        border: Border.all(
          color: isDark ? AppColors.borderSubtle : AppColors.borderLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveId,
          isExpanded: true,
          dropdownColor: isDark
              ? AppColors.surfaceOverlay
              : AppColors.surfaceElevatedLight,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
          icon: const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.textSecondary,
          ),
          items: models
              .map(
                (m) => DropdownMenuItem(
                  value: m.id,
                  child: Row(
                    children: [
                      _ProviderDot(provider: m.provider),
                      const SizedBox(width: AppSpacing.sm),
                      Text(m.displayName),
                      const SizedBox(width: AppSpacing.sm),
                      if (m.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.12),
                            borderRadius: AppRadii.borderXs,
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.brandPrimary,
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
      'anthropic' => AppColors.providerAnthropicDot,
      'openai'    => AppColors.providerOpenAiDot,
      'deepseek'  => AppColors.providerDeepSeekDot,
      'google'    => AppColors.providerGoogleDot,
      'groq'      => AppColors.providerGroqDot,
      _           => AppColors.textTertiary,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                color: AppColors.textTertiary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Add API Keys',
          onPressed: onAddKeys,
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.compact,
          leadingIcon: Icons.add,
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
          padding: EdgeInsets.all(AppSpacing.xl),
          child: _RowLoadingPlaceholder(),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
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
                              ? AppColors.brandPrimary
                              : AppColors.borderSubtle,
                          width: isSelected ? 5 : 2,
                        ),
                        color: isSelected
                            ? AppColors.brandPrimary
                            : Colors.transparent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      _useCaseIcon(useCase),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: AppSpacing.md),
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
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
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
                                  color: AppColors.textTertiary,
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
        UseCaseType.coding   => '🖥️',
        UseCaseType.research => '🔬',
        UseCaseType.writing  => '✍️',
        UseCaseType.building => '🏗️',
        UseCaseType.general  => '🌐',
      };
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
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skills',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Manage custom system prompt skills',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiary,
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
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Keys',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Add and manage your API provider keys',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Developer section (admin-gated) ───────────────────────────────────────────

class _DeveloperSection extends ConsumerStatefulWidget {
  const _DeveloperSection();

  @override
  ConsumerState<_DeveloperSection> createState() => _DeveloperSectionState();
}

class _DeveloperSectionState extends ConsumerState<_DeveloperSection> {
  final _secretController = TextEditingController();
  bool _unlocking = false;
  String? _error;

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _tryUnlock() async {
    setState(() {
      _unlocking = true;
      _error = null;
    });
    final success = await ref.read(adminGateNotifierProvider.notifier).unlock(
          email: AppConstants.kAdminEmail,
          secret: _secretController.text,
        );
    if (mounted) {
      setState(() {
        _unlocking = false;
        if (!success) { _error = 'Incorrect secret.'; }
        else { _secretController.clear(); }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gateAsync = ref.watch(adminGateNotifierProvider);
    final isUnlocked = gateAsync.valueOrNull?.isUnlocked ?? false;

    // Completely absent from the widget tree when not unlocked.
    if (!isUnlocked) {
      return _Section(
        label: 'Developer',
        child: _SectionRow(
          isLast: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter admin secret to unlock developer tools.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _secretController,
                      obscureText: true,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Secret',
                        errorText: _error,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _tryUnlock(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: 'Unlock',
                    onPressed: _unlocking ? null : _tryUnlock,
                    size: AppButtonSize.compact,
                    isLoading: _unlocking,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Unlocked: show inspector entry + lock option.
    return _Section(
      label: 'Developer',
      child: Column(
        children: [
          _SectionRow(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adminInspector),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 18,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open Delegation Inspector',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Live routing preview, decision log, brain diff',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          _SectionRow(
            isLast: true,
            onTap: () async {
              await ref.read(adminGateNotifierProvider.notifier).lock();
            },
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColors.statusErrorFg,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Lock Developer Access',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.statusErrorFg,
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
}

// ── Help & tutorials section ──────────────────────────────────────────────────

class _HelpSection extends StatelessWidget {
  const _HelpSection();

  static const String _tutorialUrl = 'https://briluxlabs.com/tutorials';
  static const String _docsUrl     = 'https://briluxlabs.com/docs';

  @override
  Widget build(BuildContext context) {
    return _Section(
      label: 'Help & Tutorials',
      child: Column(
        children: [
          _SectionRow(
            onTap: () => _openUrl(_tutorialUrl),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.statusErrorBg,
                    borderRadius: AppRadii.borderMd,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 20,
                    color: AppColors.statusErrorFg,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Tutorials',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Founder-recorded guides on setup and usage',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          _SectionRow(
            isLast: true,
            onTap: () => _openUrl(_docsUrl),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.statusInfoBg,
                    borderRadius: AppRadii.borderMd,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.article_outlined,
                    size: 20,
                    color: AppColors.statusInfoFg,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documentation',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      Text(
                        'Coming soon — placeholder for docs link',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.textTertiary,
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
                  decoration: const BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: AppRadii.borderMd,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.textTertiary),
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
                          color: AppColors.textTertiary,
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
              color: AppColors.brandPrimary,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            'Loading…',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
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
          color: AppColors.statusErrorFg,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.statusErrorFg,
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

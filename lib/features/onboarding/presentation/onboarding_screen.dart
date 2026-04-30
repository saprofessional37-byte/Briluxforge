// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_button.dart';
import 'package:briluxforge/core/widgets/app_status_card.dart';
import 'package:briluxforge/core/widgets/app_success_graphic.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';
import 'package:briluxforge/features/onboarding/presentation/use_case_screen.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    await ref.read(onboardingNotifierProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: Row(
        children: [
          _LeftPanel(currentPage: _currentPage),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  showSkip: _currentPage >= 2,
                  onSkip: _complete,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    children: [
                      _WelcomePage(onNext: _next),
                      UseCaseScreen(onNext: _next),
                      _ApiGuidePage(
                        useCase: ref
                            .watch(onboardingNotifierProvider)
                            .valueOrNull
                            ?.selectedUseCase,
                        onNext: _next,
                        onBack: _prev,
                      ),
                      _AddKeyPage(onNext: _next, onBack: _prev),
                      _DonePage(onComplete: _complete),
                    ],
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

// ──────────────────────────────────────────────────────────
// Left panel
// ──────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.currentPage});

  final int currentPage;

  static const _steps = [
    'Welcome',
    'Your use case',
    'API guide',
    'Add your first key',
    'All set',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppColors.sidebarDark,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandPrimaryMuted,
              borderRadius: AppRadii.borderMd,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 26),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Setup',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
          ...List.generate(_steps.length, (i) {
            final isDone = i < currentPage;
            final isCurrent = i == currentPage;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Row(
                children: [
                  _StepDot(
                      isDone: isDone, isCurrent: isCurrent, index: i),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _steps[i],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCurrent
                              ? AppColors.textPrimaryDark
                              : isDone
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textTertiaryDark,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          Text(
            '© 2026 Briluxforge',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.isDone,
    required this.isCurrent,
    required this.index,
  });

  final bool isDone;
  final bool isCurrent;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.statusSuccessBg
            : isCurrent
                ? AppColors.brandPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone
              ? AppColors.statusSuccessFg
              : isCurrent
                  ? AppColors.brandPrimary
                  : AppColors.borderSubtle,
          width: 1.5,
        ),
      ),
      child: isDone
          ? Icon(Icons.check, size: 12, color: AppColors.statusSuccessFg)
          : isCurrent
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                          fontSize: 10,
                        ),
                  ),
                ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Top bar
// ──────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentPage,
    required this.totalPages,
    required this.showSkip,
    required this.onSkip,
  });

  final int currentPage;
  final int totalPages;
  final bool showSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadii.borderXs,
              child: LinearProgressIndicator(
                value: (currentPage + 1) / totalPages,
                backgroundColor: AppColors.surfaceOverlay,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.brandPrimary),
                minHeight: 3,
              ),
            ),
          ),
          if (showSkip) ...[
            const SizedBox(width: AppSpacing.xl),
            AppButton(
              label: 'Skip setup',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.compact,
              onPressed: onSkip,
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Page 0: Welcome
// ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl + 28, 64, AppSpacing.xxl + 28, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: AppRadii.borderXs,
              border: Border.all(
                  color: AppColors.brandPrimary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Welcome to Briluxforge',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'The AI router that\npays for itself.',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.lg + 2),
          Text(
            'Briluxforge routes every prompt to the right model automatically — '
            'DeepSeek for code, Gemini for long documents, Claude for nuanced writing. '
            'You get the best model for every task at a fraction of subscription cost.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.65,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _HighlightRow(
            icon: Icons.auto_awesome_outlined,
            color: AppColors.brandPrimary,
            title: 'Automatic delegation',
            subtitle:
                'Picks the best model for every task — locally, in < 5ms.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _HighlightRow(
            icon: Icons.savings_outlined,
            color: AppColors.savingsGreen,
            title: 'Real-time savings tracker',
            subtitle:
                'Tracks exactly how much you save vs. a flagship subscription.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _HighlightRow(
            icon: Icons.psychology_outlined,
            color: Color(0xFFA78BFA),
            title: 'Skills system',
            subtitle:
                'Reusable system prompts that follow you across every conversation.',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Get started',
              leadingIcon: Icons.arrow_forward_rounded,
              onPressed: onNext,
              size: AppButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppRadii.borderSm,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Page 2: API buying guide
// ──────────────────────────────────────────────────────────

class _ApiGuidePage extends StatelessWidget {
  const _ApiGuidePage({
    required this.useCase,
    required this.onNext,
    required this.onBack,
  });

  final UseCaseType? useCase;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl + 28, AppSpacing.xxl, AppSpacing.xxl + 28, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Which APIs should I get?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start with these two. They cover 95% of tasks at the best price-per-token.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _ApiRecommendationCard(
            rank: 1,
            name: 'DeepSeek',
            tagline: 'Best for code, reasoning, and everyday tasks',
            price: '\$0.14 / 1M input tokens',
            highlight: 'Best value',
            highlightColor: AppColors.savingsGreen,
            url: 'platform.deepseek.com',
            icon: Icons.code_rounded,
            iconColor: Color(0xFF60A5FA),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ApiRecommendationCard(
            rank: 2,
            name: 'Google Gemini',
            tagline: 'Best for long documents, research, and summarization',
            price: '\$0.04 / 1M input tokens',
            highlight: 'Cheapest',
            highlightColor: AppColors.brandPrimary,
            url: 'aistudio.google.com',
            icon: Icons.science_outlined,
            iconColor: Color(0xFF34D399),
          ),
          if (useCase == UseCaseType.writing) ...[
            const SizedBox(height: AppSpacing.md),
            const _ApiRecommendationCard(
              rank: 3,
              name: 'Anthropic Claude',
              tagline:
                  'Best for nuanced writing, analysis, and instruction-following',
              price: '\$3.00 / 1M input tokens',
              highlight: 'Recommended for writing',
              highlightColor: Color(0xFFA78BFA),
              url: 'console.anthropic.com',
              icon: Icons.edit_note_rounded,
              iconColor: Color(0xFFA78BFA),
            ),
          ],
          const Spacer(),
          _NavButtons(
              onBack: onBack, onNext: onNext, nextLabel: 'Continue'),
        ],
      ),
    );
  }
}

class _ApiRecommendationCard extends StatelessWidget {
  const _ApiRecommendationCard({
    required this.rank,
    required this.name,
    required this.tagline,
    required this.price,
    required this.highlight,
    required this.highlightColor,
    required this.url,
    required this.icon,
    required this.iconColor,
  });

  final int rank;
  final String name;
  final String tagline;
  final String price;
  final String highlight;
  final Color highlightColor;
  final String url;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: AppRadii.borderMd,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: highlightColor.withValues(alpha: 0.12),
                        borderRadius: AppRadii.borderXs,
                      ),
                      child: Text(
                        highlight,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: highlightColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs + 1),
                Text(
                  tagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  price,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiaryDark,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            url,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Page 3: Add first key
// ──────────────────────────────────────────────────────────

class _AddKeyPage extends ConsumerStatefulWidget {
  const _AddKeyPage({required this.onNext, required this.onBack});

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<_AddKeyPage> createState() => _AddKeyPageState();
}

class _AddKeyPageState extends ConsumerState<_AddKeyPage> {
  String _selectedProvider = kSupportedProviders.first.id;
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _isAdding = false;
  AppStatusVariant? _feedbackVariant;
  String? _feedbackMessage;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  ProviderConfig get _selectedConfig =>
      kSupportedProviders.firstWhere((p) => p.id == _selectedProvider);

  @override
  Widget build(BuildContext context) {
    final keysAsync = ref.watch(apiKeyNotifierProvider);
    final connectedKeys = keysAsync.valueOrNull
            ?.where((k) => k.status == VerificationStatus.verified)
            .toList() ??
        [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl + 28, AppSpacing.xl, AppSpacing.xxl + 28, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add your first API key',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Start with DeepSeek — it handles 90% of tasks at the best price. '
            'You can add more keys at any time via the sidebar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: kSupportedProviders.map((p) {
              final selected = _selectedProvider == p.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedProvider = p.id;
                  _feedbackVariant = null;
                  _feedbackMessage = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? p.color.withValues(alpha: 0.14)
                        : AppColors.surfaceBase,
                    borderRadius: AppRadii.borderSm,
                    border: Border.all(
                      color: selected
                          ? p.color.withValues(alpha: 0.55)
                          : AppColors.borderSubtle,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.iconData,
                        size: 13,
                        color: selected
                            ? p.color
                            : AppColors.textTertiaryDark,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        p.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selected
                              ? p.color
                              : AppColors.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _keyController,
            obscureText: _obscureKey,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              color: AppColors.textPrimaryDark,
            ),
            decoration: InputDecoration(
              hintText:
                  'Paste your ${_selectedConfig.displayName} API key…',
              hintStyle: const TextStyle(
                color: AppColors.textTertiaryDark,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
              filled: true,
              fillColor: AppColors.surfaceBase,
              border: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: const BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: const BorderSide(
                    color: AppColors.brandPrimary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 13),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureKey = !_obscureKey),
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 17,
                  color: AppColors.textTertiaryDark,
                ),
              ),
            ),
            onSubmitted: (_) => _handleAdd(),
          ),
          if (_feedbackMessage != null && _feedbackVariant != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppStatusCard(
              variant: _feedbackVariant!,
              title: _feedbackMessage!,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppButton(
                label: _isAdding ? 'Verifying…' : 'Add & Verify',
                leadingIcon: _isAdding ? null : Icons.check_rounded,
                onPressed: _isAdding ? null : _handleAdd,
                isLoading: _isAdding,
              ),
              if (connectedKeys.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.statusSuccessFg),
                    const SizedBox(width: 5),
                    Text(
                      '${connectedKeys.length} key${connectedKeys.length == 1 ? '' : 's'} connected',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.statusSuccessFg,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.statusInfoBg,
              borderRadius: AppRadii.borderSm,
              border: Border.all(color: AppColors.statusInfoBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline,
                    color: AppColors.statusInfoFg, size: 15),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Keys are stored in platform-native secure storage '
                    '(Windows Credential Manager / macOS Keychain). '
                    'They never leave your device.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryDark,
                          height: 1.5,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _NavButtons(
            onBack: widget.onBack,
            onNext: widget.onNext,
            nextLabel: connectedKeys.isNotEmpty
                ? 'Continue →'
                : "I'll add keys later →",
          ),
        ],
      ),
    );
  }

  Future<void> _handleAdd() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _feedbackVariant = AppStatusVariant.warning;
        _feedbackMessage = 'Please paste your API key first.';
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _feedbackVariant = null;
      _feedbackMessage = null;
    });

    try {
      await ref.read(apiKeyNotifierProvider.notifier).addKey(
            provider: _selectedProvider,
            rawKey: key,
          );
      if (mounted) {
        setState(() {
          _feedbackVariant = AppStatusVariant.success;
          _feedbackMessage = '${_selectedConfig.displayName} connected!';
          _keyController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackVariant = AppStatusVariant.error;
          _feedbackMessage =
              e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
        });
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}

// ──────────────────────────────────────────────────────────
// Page 4: Done — uses AppSuccessGraphic
// ──────────────────────────────────────────────────────────

class _DonePage extends StatelessWidget {
  const _DonePage({required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl + 28, 64, AppSpacing.xxl + 28, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSuccessGraphic(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            "You're all set.",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Briluxforge is ready. Add your API keys from the sidebar, '
            'enable skills to customise every conversation, '
            'and watch your savings grow with every prompt.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.65,
                ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const _DoneItem(
            icon: Icons.key_rounded,
            color: AppColors.brandPrimary,
            label: 'Add API keys',
            detail: 'Settings → API Keys',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _DoneItem(
            icon: Icons.psychology_outlined,
            color: Color(0xFFA78BFA),
            label: 'Enable skills',
            detail: 'Sidebar → Skills',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _DoneItem(
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.savingsGreen,
            label: 'Start your first conversation',
            detail: 'Ctrl/Cmd + N',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Open Briluxforge',
              leadingIcon: Icons.arrow_forward_rounded,
              onPressed: onComplete,
              size: AppButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneItem extends StatelessWidget {
  const _DoneItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: AppRadii.borderSm,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              detail,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────
// Shared nav buttons
// ──────────────────────────────────────────────────────────

class _NavButtons extends StatelessWidget {
  const _NavButtons({
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppButton(
          label: 'Back',
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.large,
          onPressed: onBack,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            label: nextLabel,
            size: AppButtonSize.large,
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}

// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
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
    // AuthGate reactively routes to HomeScreen.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
                    onPageChanged: (i) => setState(() => _currentPage = i),
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
// Left panel — branding + step list
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
        border: Border(right: BorderSide(color: AppColors.borderDark)),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 20),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Setup',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 48),
          // Steps
          ...List.generate(_steps.length, (i) {
            final isDone = i < currentPage;
            final isCurrent = i == currentPage;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  _StepDot(isDone: isDone, isCurrent: isCurrent, index: i),
                  const SizedBox(width: 14),
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
            ? AppColors.success.withValues(alpha: 0.15)
            : isCurrent
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone
              ? AppColors.success
              : isCurrent
                  ? AppColors.primary
                  : AppColors.borderDark,
          width: 1.5,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check, size: 12, color: AppColors.success)
          : isCurrent
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
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
// Top bar — progress + skip
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
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (currentPage + 1) / totalPages,
                backgroundColor: AppColors.surfaceElevatedDark,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 3,
              ),
            ),
          ),
          if (showSkip) ...[
            const SizedBox(width: 20),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Skip setup',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
              ),
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
      padding: const EdgeInsets.fromLTRB(60, 64, 60, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Welcome to Briluxforge',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'The AI router that\npays for itself.',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            'Briluxforge routes every prompt to the right model automatically — '
            'DeepSeek for code, Gemini for long documents, Claude for nuanced writing. '
            'You get the best model for every task at a fraction of subscription cost.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.65,
                ),
          ),
          const SizedBox(height: 48),
          const _HighlightRow(
            icon: Icons.auto_awesome_outlined,
            color: AppColors.primary,
            title: 'Automatic delegation',
            subtitle: 'Picks the best model for every task — locally, in < 5ms.',
          ),
          const SizedBox(height: 16),
          const _HighlightRow(
            icon: Icons.savings_outlined,
            color: AppColors.savingsGreen,
            title: 'Real-time savings tracker',
            subtitle: 'Tracks exactly how much you save vs. a flagship subscription.',
          ),
          const SizedBox(height: 16),
          const _HighlightRow(
            icon: Icons.psychology_outlined,
            color: Color(0xFFA78BFA),
            title: 'Skills system',
            subtitle: 'Reusable system prompts that follow you across every conversation.',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onNext,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Get started'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
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
              const SizedBox(height: 2),
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
      padding: const EdgeInsets.fromLTRB(60, 48, 60, 40),
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
          const SizedBox(height: 10),
          Text(
            'Start with these two. They cover 95% of tasks at the best price-per-token on the market.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 28),
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
          const SizedBox(height: 14),
          const _ApiRecommendationCard(
            rank: 2,
            name: 'Google Gemini',
            tagline: 'Best for long documents, research, and summarization',
            price: '\$0.04 / 1M input tokens',
            highlight: 'Cheapest',
            highlightColor: AppColors.primary,
            url: 'aistudio.google.com',
            icon: Icons.science_outlined,
            iconColor: Color(0xFF34D399),
          ),
          const SizedBox(height: 14),
          if (useCase == UseCaseType.writing)
            const _ApiRecommendationCard(
              rank: 3,
              name: 'Anthropic Claude',
              tagline: 'Best for nuanced writing, analysis, and instruction-following',
              price: '\$3.00 / 1M input tokens',
              highlight: 'Recommended for writing',
              highlightColor: Color(0xFFA78BFA),
              url: 'console.anthropic.com',
              icon: Icons.edit_note_rounded,
              iconColor: Color(0xFFA78BFA),
            ),
          const Spacer(),
          _NavButtons(onBack: onBack, onNext: onNext, nextLabel: 'Continue'),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: highlightColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
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
                const SizedBox(height: 3),
                Text(
                  tagline,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiaryDark,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(
                url,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
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
  String? _errorMessage;
  String? _successMessage;

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
      padding: const EdgeInsets.fromLTRB(60, 40, 60, 40),
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
          const SizedBox(height: 8),
          Text(
            'Start with DeepSeek — it handles 90% of tasks at the best price. '
            'You can add more keys at any time via the sidebar.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: 24),

          // ── Provider chips ─────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSupportedProviders.map((p) {
              final selected = _selectedProvider == p.id;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedProvider = p.id;
                  _errorMessage = null;
                  _successMessage = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? p.color.withValues(alpha: 0.14)
                        : AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? p.color.withValues(alpha: 0.55)
                          : AppColors.borderDark,
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
                      const SizedBox(width: 6),
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

          const SizedBox(height: 16),

          // ── Key field ──────────────────────────────────
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
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
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

          // ── Feedback ───────────────────────────────────
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            _OnboardingFeedback(message: _errorMessage!, isError: true),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 10),
            _OnboardingFeedback(message: _successMessage!, isError: false),
          ],

          const SizedBox(height: 12),

          // ── Add button ─────────────────────────────────
          Row(
            children: [
              SizedBox(
                height: 42,
                child: FilledButton.icon(
                  onPressed: _isAdding ? null : _handleAdd,
                  icon: _isAdding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                      _isAdding ? 'Verifying…' : 'Add & Verify'),
                ),
              ),
              if (connectedKeys.isNotEmpty) ...[
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 5),
                    Text(
                      '${connectedKeys.length} key${connectedKeys.length == 1 ? '' : 's'} connected',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ],
          ),

          // ── Security note ─────────────────────────────
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.savingsGreen.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.savingsGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_outline,
                    color: AppColors.savingsGreen, size: 15),
                const SizedBox(width: 10),
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
        _errorMessage = 'Please paste your API key first.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(apiKeyNotifierProvider.notifier).addKey(
            provider: _selectedProvider,
            rawKey: key,
          );
      if (mounted) {
        setState(() {
          _successMessage =
              '${_selectedConfig.displayName} connected!';
          _keyController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              e.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
        });
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}

class _OnboardingFeedback extends StatelessWidget {
  const _OnboardingFeedback({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    final icon =
        isError ? Icons.error_outline_rounded : Icons.check_circle_outline;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Page 4: Done
// ──────────────────────────────────────────────────────────

class _DonePage extends StatelessWidget {
  const _DonePage({required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 64, 60, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 32),
          ),
          const SizedBox(height: 28),
          Text(
            "You're all set.",
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            'Briluxforge is ready. Add your API keys from the sidebar, enable skills to customise every conversation, '
            'and watch your savings grow with every prompt.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.65,
                ),
          ),
          const SizedBox(height: 40),
          const _DoneItem(
            icon: Icons.key_rounded,
            color: AppColors.primary,
            label: 'Add API keys',
            detail: 'Settings → API Keys',
          ),
          const SizedBox(height: 16),
          const _DoneItem(
            icon: Icons.psychology_outlined,
            color: Color(0xFFA78BFA),
            label: 'Enable skills',
            detail: 'Sidebar → Skills',
          ),
          const SizedBox(height: 16),
          const _DoneItem(
            icon: Icons.chat_bubble_outline_rounded,
            color: AppColors.savingsGreen,
            label: 'Start your first conversation',
            detail: 'Ctrl/Cmd + N',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onComplete,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Open Briluxforge'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
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
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              side: const BorderSide(color: AppColors.borderDark),
            ),
            child: const Text('Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: onNext,
              child: Text(nextLabel),
            ),
          ),
        ),
      ],
    );
  }
}

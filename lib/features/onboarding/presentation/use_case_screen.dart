// lib/features/onboarding/presentation/use_case_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_button.dart';
import 'package:briluxforge/features/onboarding/presentation/widgets/use_case_card.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';

// Layout constants: 3 cards per row × 200px + 2 gaps × 16px = 632px < 720 max.
// Two rows: 2 × 200px + 1 gap × 16px = 416px.
// Header ~100px + spacing 24px + grid 416px + spacing 24px + button 52px ≈ 616px.
// Min window height raised to 640px (app_constants.dart) for headroom.
const double _kCardSize = 200;
const double _kCardGap = 16;

class UseCaseScreen extends ConsumerWidget {
  const UseCaseScreen({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(onboardingNotifierProvider).valueOrNull?.selectedUseCase;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Text(
                'What will you use\nBriluxforge for?',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimaryDark,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "We'll set your default model and recommend the best APIs based on your choice.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Use-case card grid ────────────────────────────────────
              // Wrap places five 200×200 cards in a 3+2 layout automatically.
              // No SingleChildScrollView — the layout is designed to fit in
              // the minimum 900×640 window without scrolling.
              Wrap(
                spacing: _kCardGap,
                runSpacing: _kCardGap,
                alignment: WrapAlignment.center,
                children: UseCaseType.values.map((useCase) {
                  return SizedBox(
                    width: _kCardSize,
                    height: _kCardSize,
                    child: UseCaseCard(
                      useCase: useCase,
                      isSelected: selected == useCase,
                      onTap: () => ref
                          .read(onboardingNotifierProvider.notifier)
                          .selectUseCase(useCase),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Continue button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Continue',
                  onPressed: selected != null ? onNext : null,
                  size: AppButtonSize.large,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/onboarding/presentation/use_case_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_button.dart';
import 'package:briluxforge/features/onboarding/presentation/widgets/use_case_card.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: UseCaseType.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final useCase = UseCaseType.values[i];
                    return UseCaseCard(
                      useCase: useCase,
                      isSelected: selected == useCase,
                      onTap: () => ref
                          .read(onboardingNotifierProvider.notifier)
                          .selectUseCase(useCase),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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

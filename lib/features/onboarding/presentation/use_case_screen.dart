// lib/features/onboarding/presentation/use_case_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/onboarding/presentation/widgets/use_case_card.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';

class UseCaseScreen extends ConsumerWidget {
  const UseCaseScreen({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(onboardingNotifierProvider).valueOrNull?.selectedUseCase;

    return Padding(
      padding: const EdgeInsets.fromLTRB(60, 48, 60, 40),
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
          const SizedBox(height: 10),
          Text(
            "We'll set your default model and recommend the best APIs based on your choice.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: UseCaseType.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: selected != null ? onNext : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

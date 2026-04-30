// lib/features/onboarding/presentation/widgets/use_case_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_card.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';

class UseCaseCard extends StatelessWidget {
  const UseCaseCard({
    required this.useCase,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final UseCaseType useCase;
  final bool isSelected;
  final VoidCallback onTap;

  String get _svgAsset => switch (useCase) {
        UseCaseType.coding   => 'assets/images/onboarding/coding.svg',
        UseCaseType.research => 'assets/images/onboarding/research.svg',
        UseCaseType.writing  => 'assets/images/onboarding/writing.svg',
        UseCaseType.building => 'assets/images/onboarding/building.svg',
        UseCaseType.general  => 'assets/images/onboarding/general.svg',
      };

  Color get _accentColor => switch (useCase) {
        UseCaseType.coding   => const Color(0xFF60A5FA),
        UseCaseType.research => const Color(0xFF34D399),
        UseCaseType.writing  => const Color(0xFFA78BFA),
        UseCaseType.building => const Color(0xFFFBBF24),
        UseCaseType.general  => const Color(0xFFF472B6),
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: isSelected
          ? AppColors.brandPrimary.withValues(alpha: 0.08)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: AppRadii.borderMd,
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary.withValues(alpha: 0.40)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              // 96×96 illustration — no dark container box
              SvgPicture.asset(
                _svgAsset,
                width: 96,
                height: 96,
                colorFilter: ColorFilter.mode(
                  _accentColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      useCase.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      useCase.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryDark,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 160),
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/onboarding/presentation/widgets/use_case_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_card.dart';
import 'package:briluxforge/features/onboarding/providers/onboarding_provider.dart';

// Phase 13 §13.7.2: card is 200×200 (constrained by parent SizedBox in the
// Wrap). Illustration shrunk to 80px so the card reads as square.
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
        UseCaseType.coding => 'assets/images/onboarding/coding.svg',
        UseCaseType.research => 'assets/images/onboarding/research.svg',
        UseCaseType.writing => 'assets/images/onboarding/writing.svg',
        UseCaseType.building => 'assets/images/onboarding/building.svg',
        UseCaseType.general => 'assets/images/onboarding/general.svg',
      };

  Color get _accentColor => switch (useCase) {
        UseCaseType.coding => AppColors.accentBlue,
        UseCaseType.research => AppColors.accentGreen,
        UseCaseType.writing => AppColors.accentViolet,
        UseCaseType.building => AppColors.accentAmber,
        UseCaseType.general => AppColors.accentPink,
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
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 80px illustration — down from 96px so the card is square.
              SvgPicture.asset(
                _svgAsset,
                width: 80,
                height: 80,
                colorFilter: ColorFilter.mode(
                  _accentColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                useCase.displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                useCase.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                      height: 1.4,
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 160),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.brandPrimary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/features/onboarding/presentation/widgets/use_case_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
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
        UseCaseType.coding => 'assets/images/onboarding/coding.svg',
        UseCaseType.research => 'assets/images/onboarding/research.svg',
        UseCaseType.writing => 'assets/images/onboarding/writing.svg',
        UseCaseType.building => 'assets/images/onboarding/building.svg',
        UseCaseType.general => 'assets/images/onboarding/general.svg',
      };

  Color get _iconColor => switch (useCase) {
        UseCaseType.coding => const Color(0xFF60A5FA),
        UseCaseType.research => const Color(0xFF34D399),
        UseCaseType.writing => const Color(0xFFA78BFA),
        UseCaseType.building => const Color(0xFFFBBF24),
        UseCaseType.general => const Color(0xFFF472B6),
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.borderDark,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: SvgPicture.asset(
                    _svgAsset,
                    colorFilter: ColorFilter.mode(_iconColor, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        useCase.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        useCase.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryDark,
                            ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

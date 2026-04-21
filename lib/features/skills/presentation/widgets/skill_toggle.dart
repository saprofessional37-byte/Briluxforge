// lib/features/skills/presentation/widgets/skill_toggle.dart
import 'package:flutter/material.dart';

import 'package:briluxforge/core/theme/app_colors.dart';

/// Styled switch toggle for skill enabled/disabled state.
/// Wraps a label + subtitle alongside a Material 3 Switch.
class SkillToggle extends StatelessWidget {
  const SkillToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final String label;
  final bool value;
  final void Function(bool) onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiaryDark,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

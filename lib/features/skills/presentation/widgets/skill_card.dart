// lib/features/skills/presentation/widgets/skill_card.dart
import 'package:flutter/material.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/skills/data/models/skill_model.dart';

const _providerLabels = <String, String>{
  'anthropic': 'Claude',
  'deepseek': 'DeepSeek',
  'google': 'Gemini',
  'openai': 'OpenAI',
  'groq': 'Groq',
};

class SkillCard extends StatelessWidget {
  const SkillCard({
    required this.skill,
    required this.onToggle,
    required this.onEdit,
    this.onDelete,
    super.key,
  });

  final SkillModel skill;
  final void Function(bool) onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = skill.isEnabled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.borderDark,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkillIcon(isActive: isActive),
              const SizedBox(width: 12),
              Expanded(
                child: _SkillContent(
                  skill: skill,
                  isActive: isActive,
                ),
              ),
              const SizedBox(width: 6),
              _SkillActions(
                skill: skill,
                onToggle: onToggle,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillIcon extends StatelessWidget {
  const _SkillIcon({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        Icons.psychology_outlined,
        size: 18,
        color: isActive ? AppColors.primary : AppColors.textTertiaryDark,
      ),
    );
  }
}

class _SkillContent extends StatelessWidget {
  const _SkillContent({required this.skill, required this.isActive});

  final SkillModel skill;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                skill.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (skill.isBuiltIn) ...[
              const SizedBox(width: 6),
              const _Chip(
                label: 'Built-in',
                color: AppColors.textTertiaryDark,
                bg: AppColors.surfaceElevatedDark,
              ),
            ],
          ],
        ),
        if (skill.description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            skill.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (skill.pinnedProviders != null &&
            skill.pinnedProviders!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: skill.pinnedProviders!
                .map((p) => _Chip(
                      label: _providerLabels[p] ?? p,
                      color: AppColors.primary,
                      bg: AppColors.primary.withValues(alpha: 0.1),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _SkillActions extends StatelessWidget {
  const _SkillActions({
    required this.skill,
    required this.onToggle,
    required this.onDelete,
  });

  final SkillModel skill;
  final void Function(bool) onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Switch(
          value: skill.isEnabled,
          onChanged: onToggle,
          activeThumbColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        if (onDelete != null) ...[
          const SizedBox(height: 2),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: AppColors.textTertiaryDark,
            onPressed: onDelete,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Delete skill',
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

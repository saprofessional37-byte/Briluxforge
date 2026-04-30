// lib/features/skills/presentation/skills_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_button.dart';
import 'package:briluxforge/core/widgets/app_card.dart';
import 'package:briluxforge/core/widgets/app_dialog.dart';
import 'package:briluxforge/features/skills/data/models/skill_model.dart';
import 'package:briluxforge/features/skills/presentation/skill_editor_screen.dart';
import 'package:briluxforge/features/skills/presentation/widgets/skill_card.dart';
import 'package:briluxforge/features/skills/providers/skills_provider.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSkillsAsync = ref.watch(allSkillsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBase,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 20,
            color: AppColors.textSecondaryDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Skills',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: AppButton(
              label: 'New Skill',
              leadingIcon: Icons.add,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.skillEditor),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderSubtle),
        ),
      ),
      body: allSkillsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.brandPrimary,
            strokeWidth: 2,
          ),
        ),
        error: (_, __) => const _ErrorState(),
        data: (skills) => _SkillsList(skills: skills),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.textTertiaryDark,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Could not load skills.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Skills list ───────────────────────────────────────────────────────────────

class _SkillsList extends ConsumerWidget {
  const _SkillsList({required this.skills});

  final List<SkillModel> skills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builtIns = skills.where((s) => s.isBuiltIn).toList();
    final userSkills = skills.where((s) => !s.isBuiltIn).toList();

    if (skills.isEmpty) return const _EmptyState();

    return ListView(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      children: [
        if (builtIns.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Built-in Skills',
            subtitle: 'Shipped with Briluxforge — cannot be deleted.',
          ),
          const SizedBox(height: AppSpacing.sm),
          ...builtIns.map((skill) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SkillCard(
                  skill: skill,
                  onToggle: (enabled) => ref
                      .read(skillsNotifierProvider.notifier)
                      .toggle(skill.id, enabled: enabled),
                  onEdit: () => Navigator.pushNamed(
                    context,
                    AppRoutes.skillEditor,
                    arguments: SkillEditorArgs(skill: skill),
                  ),
                ),
              )),
        ],
        if (userSkills.isNotEmpty) ...[
          SizedBox(height: builtIns.isNotEmpty ? AppSpacing.xl : 0),
          const _SectionHeader(title: 'My Skills'),
          const SizedBox(height: AppSpacing.sm),
          ...userSkills.map((skill) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SkillCard(
                  skill: skill,
                  onToggle: (enabled) => ref
                      .read(skillsNotifierProvider.notifier)
                      .toggle(skill.id, enabled: enabled),
                  onEdit: () => Navigator.pushNamed(
                    context,
                    AppRoutes.skillEditor,
                    arguments: SkillEditorArgs(skill: skill),
                  ),
                  onDelete: () => _confirmDelete(context, ref, skill),
                ),
              )),
        ],
        if (userSkills.isEmpty && builtIns.isNotEmpty)
          const _CreateHint(),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SkillModel skill,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Delete "${skill.name}"?',
      body: Text(
        'This skill will be permanently removed.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
      ),
      primaryLabel: 'Delete',
      onPrimary: () => Navigator.pop(context, true),
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.pop(context, false),
    );
    if (confirmed == true) {
      await ref
          .read(skillsNotifierProvider.notifier)
          .deleteSkill(skill.id);
    }
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.psychology_outlined,
            size: 32,
            color: AppColors.textTertiaryDark,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No skills yet.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create a skill to customise AI behaviour.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryDark,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                ),
          ),
        ],
      ],
    );
  }
}

// ── Create hint ───────────────────────────────────────────────────────────────

class _CreateHint extends StatelessWidget {
  const _CreateHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Create your own skills to give the AI a custom persona '
                'or expertise tailored to your workflows.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

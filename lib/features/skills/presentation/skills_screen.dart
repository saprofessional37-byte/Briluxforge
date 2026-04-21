// lib/features/skills/presentation/skills_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
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
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
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
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.skillEditor,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Skill'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderDark),
        ),
      ),
      body: allSkillsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
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
            size: 40,
          ),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      children: [
        if (builtIns.isNotEmpty) ...[
          const _SectionHeader(
            title: 'Built-in Skills',
            subtitle: 'Shipped with Briluxforge — cannot be deleted.',
          ),
          const SizedBox(height: 8),
          ...builtIns.map((skill) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
          SizedBox(height: builtIns.isNotEmpty ? 20 : 0),
          const _SectionHeader(title: 'My Skills'),
          const SizedBox(height: 8),
          ...userSkills.map((skill) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevatedDark,
        title: Text(
          'Delete "${skill.name}"?',
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimaryDark,
              ),
        ),
        content: Text(
          'This skill will be permanently removed.',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryDark,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
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
            size: 48,
            color: AppColors.textTertiaryDark,
          ),
          const SizedBox(height: 12),
          Text(
            'No skills yet.',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 4),
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
          const SizedBox(height: 2),
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

// ── Create hint (shown when user has no custom skills yet) ────────────────────

class _CreateHint extends StatelessWidget {
  const _CreateHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Create your own skills to give the AI a custom persona or expertise tailored to your workflows.',
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

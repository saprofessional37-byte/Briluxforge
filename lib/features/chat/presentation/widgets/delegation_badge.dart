// lib/features/chat/presentation/widgets/delegation_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/delegation/data/engine/response_stitcher.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/data/models/sub_task.dart';
import 'package:briluxforge/features/delegation/data/models/task_plan.dart';
import 'package:briluxforge/features/delegation/providers/delegation_provider.dart';

/// Shows which model delegation chose and why. Tapping opens the
/// ModelSelector for manual override (single-model) or a routing detail
/// modal (multi-model plan). Shown in the chat input bar.
class DelegationBadge extends ConsumerWidget {
  const DelegationBadge({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(delegationNotifierProvider);

    if (result == null) {
      return _AutoBadge(onTap: onTap);
    }

    if (result.plan != null) {
      return _MultiRouteBadge(result: result);
    }

    return _ActiveBadge(result: result, onTap: onTap);
  }
}

// ── Auto badge (no result yet) ────────────────────────────────────────────────

class _AutoBadge extends StatelessWidget {
  const _AutoBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BadgeShell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Auto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                  fontSize: 11,
                ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 12,
            color: AppColors.textTertiaryDark,
          ),
        ],
      ),
    );
  }
}

// ── Active badge (single-model result) ───────────────────────────────────────

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.result, required this.onTap});

  final DelegationResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final modelName = _shortName(result.selectedModelId);
    final isOverridden = result.wasOverridden;
    final color = isOverridden ? AppColors.warning : AppColors.accent;

    return _BadgeShell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverridden ? Icons.edit_outlined : Icons.auto_awesome,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '→ $modelName',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                  fontSize: 11,
                ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 12,
            color: AppColors.textTertiaryDark,
          ),
        ],
      ),
    );
  }

  String _shortName(String modelId) => switch (modelId) {
        'deepseek-chat' => 'DeepSeek V3',
        'gemini-2.0-flash' => 'Gemini Flash',
        'claude-sonnet-4-20250514' => 'Claude Sonnet',
        'gpt-4o' => 'GPT-4o',
        _ => modelId.split('-').take(2).join(' '),
      };
}

// ── Multi-route badge (plan result) ──────────────────────────────────────────

class _MultiRouteBadge extends StatelessWidget {
  const _MultiRouteBadge({required this.result});

  final DelegationResult result;

  @override
  Widget build(BuildContext context) {
    final plan = result.plan!;
    final summary = _buildSummary(plan);

    return _BadgeShell(
      onTap: () => _showRoutingModal(context, plan),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 11,
            color: AppColors.accent,
          ),
          const SizedBox(width: 5),
          Text(
            summary,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                  fontSize: 11,
                ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.info_outline,
            size: 11,
            color: AppColors.textTertiaryDark,
          ),
        ],
      ),
    );
  }

  String _buildSummary(TaskPlan plan) {
    final parts = plan.subTasks
        .where((t) => t.selectedModelId != null)
        .map((t) {
          final display = kCategoryDisplayNames[t.category] ?? t.category;
          final model = _shortProvider(t.selectedProvider ?? '');
          return '$display ($model)';
        })
        .take(3)
        .join(' → ');
    return 'Multi-route: $parts';
  }

  String _shortProvider(String provider) => switch (provider) {
        'deepseek' => 'DeepSeek',
        'google' => 'Gemini',
        'anthropic' => 'Claude',
        'openai' => 'GPT',
        'groq' => 'Groq',
        _ => provider,
      };

  void _showRoutingModal(BuildContext context, TaskPlan plan) {
    showDialog<void>(
      context: context,
      builder: (_) => _RoutingDetailDialog(plan: plan),
    );
  }
}

// ── Routing detail modal ──────────────────────────────────────────────────────

class _RoutingDetailDialog extends StatelessWidget {
  const _RoutingDetailDialog({required this.plan});

  final TaskPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_tree_outlined,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Multi-Route Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${plan.subTasks.length} sub-tasks routed to specialised models.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.dividerDark, height: 1),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: plan.subTasks
                        .map((t) => _SubTaskRow(task: t))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubTaskRow extends StatelessWidget {
  const _SubTaskRow({required this.task});

  final SubTask task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = kCategoryDisplayNames[task.category] ?? task.category;
    final isFailed = task.status == SubTaskStatus.failed;
    final statusColor = isFailed ? AppColors.error : AppColors.success;
    final statusIcon = isFailed ? Icons.error_outline : Icons.check_circle_outline;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.selectedModelId != null)
                  Text(
                    '${task.selectedModelId} · ${task.selectedProvider} · '
                    '${(task.categoryConfidence * 100).toStringAsFixed(0)}% confidence',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                  ),
                if (isFailed && task.errorMessage != null)
                  Text(
                    task.errorMessage!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared shell ──────────────────────────────────────────────────────────────

class _BadgeShell extends StatelessWidget {
  const _BadgeShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Routing info',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.delegationBadgeBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: child,
        ),
      ),
    );
  }
}

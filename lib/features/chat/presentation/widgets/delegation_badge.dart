// lib/features/chat/presentation/widgets/delegation_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/providers/delegation_provider.dart';

/// Shows which model delegation chose and why. Tapping opens the
/// ModelSelector for manual override. Shown in the chat input bar.
class DelegationBadge extends ConsumerWidget {
  const DelegationBadge({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(delegationNotifierProvider);

    if (result == null) {
      return _AutoBadge(onTap: onTap);
    }
    return _ActiveBadge(result: result, onTap: onTap);
  }
}

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

class _BadgeShell extends StatelessWidget {
  const _BadgeShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Change model',
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

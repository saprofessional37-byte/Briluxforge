// lib/features/chat/presentation/widgets/model_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/providers/delegation_provider.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';

/// Popup that lets the user manually select an AI model, overriding delegation.
class ModelSelectorPopup extends ConsumerWidget {
  const ModelSelectorPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(modelProfilesProvider);
    final keysAsync = ref.watch(apiKeyNotifierProvider);
    final current = ref.watch(delegationNotifierProvider);

    final profiles =
        profilesAsync.valueOrNull?.routeableModels ?? const [];
    final keys = keysAsync.valueOrNull ?? const [];

    final verifiedProviders = keys
        .where((k) => k.status == VerificationStatus.verified)
        .map((k) => k.provider)
        .toSet();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        constraints: const BoxConstraints(maxHeight: 380),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Text(
                'Select Model',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textTertiaryDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
              ),
            ),
            const Divider(color: AppColors.borderDark, height: 1),
            // Auto-delegate option
            _ModelOption(
              icon: Icons.auto_awesome,
              label: 'Auto — Smart Delegation',
              subtitle: 'Briluxforge picks the best model',
              isSelected: current == null,
              isAvailable: true,
              onTap: () {
                ref
                    .read(delegationNotifierProvider.notifier)
                    .clearResult();
                Navigator.of(context).pop();
              },
            ),
            const Divider(color: AppColors.borderDark, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: profiles.length,
                itemBuilder: (ctx, i) {
                  final model = profiles[i];
                  final isAvailable =
                      verifiedProviders.contains(model.provider);
                  final isSelected =
                      current?.selectedModelId == model.id;

                  return _ModelOption(
                    icon: _iconForProvider(model.provider),
                    label: model.displayName,
                    subtitle: isAvailable
                        ? _tierLabel(model)
                        : 'No API key connected',
                    isSelected: isSelected,
                    isAvailable: isAvailable,
                    onTap: isAvailable
                        ? () => _select(context, ref, model, current)
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _select(
    BuildContext context,
    WidgetRef ref,
    ModelProfile model,
    DelegationResult? current,
  ) {
    // When there is no prior delegation result, synthesise a minimal one so
    // applyManualOverride has something to base the override on.
    final base = current ??
        DelegationResult(
          selectedModelId: model.id,
          selectedProvider: model.provider,
          layerUsed: 3,
          confidence: 1.0,
          reasoning: 'Manual selection.',
        );

    ref.read(delegationNotifierProvider.notifier).applyManualOverride(
          original: base,
          chosenModel: model,
        );
    Navigator.of(context).pop();
  }

  IconData _iconForProvider(String provider) => switch (provider) {
        'deepseek' => Icons.memory_outlined,
        'google' => Icons.lightbulb_outline,
        'anthropic' => Icons.psychology_outlined,
        'openai' => Icons.circle_outlined,
        'groq' => Icons.bolt_outlined,
        _ => Icons.smart_toy_outlined,
      };

  String _tierLabel(ModelProfile model) => model.isWorkhorse
      ? 'Workhorse · \$${model.costPer1kInput.toStringAsFixed(5)}/1K in'
      : 'Premium · \$${model.costPer1kInput.toStringAsFixed(4)}/1K in';
}

// ── Option row ───────────────────────────────────────────────────────────────

class _ModelOption extends StatelessWidget {
  const _ModelOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.isAvailable,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isAvailable
        ? AppColors.textPrimaryDark
        : AppColors.textDisabledDark;
    final iconColor = isAvailable
        ? (isSelected ? AppColors.primary : AppColors.textSecondaryDark)
        : AppColors.textDisabledDark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                  ),
                  Text(
                    subtitle,
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiaryDark,
                              fontSize: 10,
                            ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                size: 14,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Show helper ───────────────────────────────────────────────────────────────

/// Shows a [ModelSelectorPopup] anchored above [anchorKey].
Future<void> showModelSelector(
  BuildContext context,
  GlobalKey anchorKey,
) async {
  final box =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null) return;

  final offset = box.localToGlobal(Offset.zero);
  final screenHeight = MediaQuery.of(context).size.height;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (dialogContext) => Stack(
      children: [
        // Dismiss on outside tap.
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(dialogContext).pop(),
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Positioned(
          left: offset.dx,
          bottom: screenHeight - offset.dy + 8,
          child: const ModelSelectorPopup(),
        ),
      ],
    ),
  );
}

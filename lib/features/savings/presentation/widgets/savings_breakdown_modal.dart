// lib/features/savings/presentation/widgets/savings_breakdown_modal.dart

import 'package:flutter/material.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/features/savings/data/models/savings_model.dart';

void showSavingsBreakdownModal(
  BuildContext context,
  SavingsSnapshot snapshot,
) {
  showDialog<void>(
    context: context,
    builder: (_) => _SavingsBreakdownDialog(snapshot: snapshot),
  );
}

class _SavingsBreakdownDialog extends StatelessWidget {
  const _SavingsBreakdownDialog({required this.snapshot});

  final SavingsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogHeader(theme: theme),
              const SizedBox(height: 20),
              _SummaryRow(snapshot: snapshot, theme: theme),
              const SizedBox(height: 20),
              const Divider(color: AppColors.dividerDark, height: 1),
              const SizedBox(height: 16),
              _BreakdownLabel(theme: theme),
              const SizedBox(height: 8),
              if (snapshot.perModelBreakdown.isEmpty)
                _EmptyState(theme: theme)
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: snapshot.perModelBreakdown
                          .map((b) => _ModelBreakdownRow(
                                breakdown: b,
                                theme: theme,
                              ))
                          .toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.dividerDark, height: 1),
              const SizedBox(height: 16),
              _MathExplanation(snapshot: snapshot, theme: theme),
              const SizedBox(height: 20),
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

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.savings_outlined,
          color: AppColors.savingsGreen,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          'Savings Breakdown',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.snapshot, required this.theme});

  final SavingsSnapshot snapshot;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.savingsGreen.withValues(alpha: 0.08),
        borderRadius: AppRadii.borderMd,
        border: Border.all(
          color: AppColors.savingsGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryStat(
            label: 'Total Saved',
            value: '\$${snapshot.totalSaved.toStringAsFixed(2)}',
            highlight: true,
            theme: theme,
          ),
          _SummaryStat(
            label: 'Total Calls',
            value: snapshot.totalCalls.toString(),
            theme: theme,
          ),
          _SummaryStat(
            label: 'Actual Cost',
            value: '\$${snapshot.totalActualCost.toStringAsFixed(4)}',
            theme: theme,
          ),
          _SummaryStat(
            label: 'vs. Opus Cost',
            value: '\$${snapshot.totalBenchmarkCost.toStringAsFixed(4)}',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.theme,
    this.highlight = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiaryDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: highlight ? AppColors.savingsGreen : AppColors.textPrimaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BreakdownLabel extends StatelessWidget {
  const _BreakdownLabel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Model',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryDark,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Calls / Tokens',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryDark,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Actual',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryDark,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Saved',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.savingsGreen,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ModelBreakdownRow extends StatelessWidget {
  const _ModelBreakdownRow({
    required this.breakdown,
    required this.theme,
  });

  final ModelSavingsBreakdown breakdown;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final int totalTokens = breakdown.inputTokens + breakdown.outputTokens;
    final String tokenDisplay = totalTokens >= 1000
        ? '${(totalTokens / 1000).toStringAsFixed(1)}K'
        : totalTokens.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              breakdown.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryDark,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${breakdown.callCount} / $tokenDisplay',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${breakdown.actualCost.toStringAsFixed(4)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              breakdown.savings > 0
                  ? '+\$${breakdown.savings.toStringAsFixed(4)}'
                  : '\$0.00',
              style: theme.textTheme.labelSmall?.copyWith(
                color: breakdown.savings > 0
                    ? AppColors.savingsGreen
                    : AppColors.textTertiaryDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No API calls recorded yet.\nSend your first message to start tracking!',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiaryDark,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MathExplanation extends StatelessWidget {
  const _MathExplanation({required this.snapshot, required this.theme});

  final SavingsSnapshot snapshot;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: AppRadii.borderSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.textTertiaryDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'We compare every prompt you send to what it would have cost on '
              '${snapshot.benchmarkDisplayName} (\$5/\$25 per 1M input/output tokens) — '
              "the industry's premium flagship. Savings = benchmark cost − actual cost, "
              'clamped to \$0 minimum.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

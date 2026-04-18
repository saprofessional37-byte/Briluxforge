// lib/features/savings/data/repositories/savings_calculator.dart

import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/savings/data/models/savings_model.dart';

/// Hard-coded fallback used when model_profiles.json has no isBenchmark entry.
const double _fallbackBenchmarkInput = 0.005;   // $5.00 per 1M tokens
const double _fallbackBenchmarkOutput = 0.025;  // $25.00 per 1M tokens
const String _fallbackBenchmarkName = 'Claude Opus 4.6';

/// Pure utility class. No state, no side effects. Deterministic and unit-testable.
class SavingsCalculator {
  const SavingsCalculator();

  /// Computes a [SavingsSnapshot] from stored token data and current pricing.
  ///
  /// Uses [benchmarkModel] pricing if non-null; falls back to hard-coded
  /// Opus 4.6 constants if null (corrupted/pre-update model_profiles.json).
  ///
  /// Per-model savings are clamped to ≥ 0, so the cumulative total never
  /// decreases even when a model costs more than the benchmark on a given call.
  SavingsSnapshot compute({
    required SavingsModel model,
    required List<ModelProfile> allProfiles,
    required ModelProfile? benchmarkModel,
  }) {
    final double benchmarkInput =
        benchmarkModel?.costPer1kInput ?? _fallbackBenchmarkInput;
    final double benchmarkOutput =
        benchmarkModel?.costPer1kOutput ?? _fallbackBenchmarkOutput;
    final String benchmarkName =
        benchmarkModel?.displayName ?? _fallbackBenchmarkName;

    final Map<String, ModelProfile> profileById = {
      for (final p in allProfiles) p.id: p,
    };

    double totalActualCost = 0;
    double totalBenchmarkCost = 0;
    double totalSaved = 0;
    int totalCalls = 0;
    int totalInputTokens = 0;
    int totalOutputTokens = 0;
    final List<ModelSavingsBreakdown> breakdown = [];

    for (final usage in model.usageByModel.values) {
      final ModelProfile? profile = profileById[usage.modelId];
      if (profile == null) continue; // removed by Smart Brain Update

      final double actualCost =
          (usage.cumulativeInputTokens * profile.costPer1kInput / 1000) +
              (usage.cumulativeOutputTokens * profile.costPer1kOutput / 1000);

      final double benchCost =
          (usage.cumulativeInputTokens * benchmarkInput / 1000) +
              (usage.cumulativeOutputTokens * benchmarkOutput / 1000);

      // Per-model clamp (equivalent to per-call clamp for fixed pricing).
      final double modelSavings =
          (benchCost - actualCost).clamp(0.0, double.infinity);

      totalActualCost += actualCost;
      totalBenchmarkCost += benchCost;
      totalSaved += modelSavings;
      totalCalls += usage.callCount;
      totalInputTokens += usage.cumulativeInputTokens;
      totalOutputTokens += usage.cumulativeOutputTokens;

      breakdown.add(ModelSavingsBreakdown(
        modelId: usage.modelId,
        displayName: profile.displayName,
        callCount: usage.callCount,
        inputTokens: usage.cumulativeInputTokens,
        outputTokens: usage.cumulativeOutputTokens,
        actualCost: actualCost,
        benchmarkCost: benchCost,
        savings: modelSavings,
      ));
    }

    // Sort breakdown by savings descending (highest savers first).
    breakdown.sort((a, b) => b.savings.compareTo(a.savings));

    final double savingsMultiple =
        totalActualCost > 0 ? totalBenchmarkCost / totalActualCost : 0;

    return SavingsSnapshot(
      totalActualCost: totalActualCost,
      totalBenchmarkCost: totalBenchmarkCost,
      totalSaved: totalSaved,
      totalCalls: totalCalls,
      totalInputTokens: totalInputTokens,
      totalOutputTokens: totalOutputTokens,
      savingsMultiple: savingsMultiple,
      benchmarkDisplayName: benchmarkName,
      perModelBreakdown: breakdown,
    );
  }
}

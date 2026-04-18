// lib/features/savings/data/models/savings_model.dart

import 'package:flutter/foundation.dart';

@immutable
class ModelUsage {
  const ModelUsage({
    required this.modelId,
    required this.cumulativeInputTokens,
    required this.cumulativeOutputTokens,
    required this.callCount,
  });

  factory ModelUsage.fromJson(Map<String, Object?> json) => ModelUsage(
        modelId: json['modelId'] as String,
        cumulativeInputTokens: json['cumulativeInputTokens'] as int,
        cumulativeOutputTokens: json['cumulativeOutputTokens'] as int,
        callCount: json['callCount'] as int,
      );

  final String modelId;
  final int cumulativeInputTokens;
  final int cumulativeOutputTokens;
  final int callCount;

  Map<String, Object?> toJson() => {
        'modelId': modelId,
        'cumulativeInputTokens': cumulativeInputTokens,
        'cumulativeOutputTokens': cumulativeOutputTokens,
        'callCount': callCount,
      };

  ModelUsage addCall({
    required int inputTokens,
    required int outputTokens,
  }) =>
      ModelUsage(
        modelId: modelId,
        cumulativeInputTokens: cumulativeInputTokens + inputTokens,
        cumulativeOutputTokens: cumulativeOutputTokens + outputTokens,
        callCount: callCount + 1,
      );
}

@immutable
class SavingsModel {
  const SavingsModel({
    required this.usageByModel,
    this.firstUsageAt,
  });

  factory SavingsModel.empty() => const SavingsModel(usageByModel: {});

  factory SavingsModel.fromJson(Map<String, Object?> json) {
    final usageMap = <String, ModelUsage>{};
    final raw = json['usageByModel'] as Map<String, Object?>? ?? {};
    for (final entry in raw.entries) {
      usageMap[entry.key] =
          ModelUsage.fromJson(entry.value as Map<String, Object?>);
    }
    final firstUsageRaw = json['firstUsageAt'] as String?;
    return SavingsModel(
      usageByModel: usageMap,
      firstUsageAt:
          firstUsageRaw != null ? DateTime.parse(firstUsageRaw) : null,
    );
  }

  /// Key: modelId. Value: cumulative usage for that model.
  final Map<String, ModelUsage> usageByModel;

  /// Timestamp of the first-ever successful API call.
  final DateTime? firstUsageAt;

  Map<String, Object?> toJson() => {
        'usageByModel': {
          for (final e in usageByModel.entries) e.key: e.value.toJson(),
        },
        if (firstUsageAt != null)
          'firstUsageAt': firstUsageAt!.toIso8601String(),
      };

  SavingsModel addCall({
    required String modelId,
    required int inputTokens,
    required int outputTokens,
  }) {
    final existing = usageByModel[modelId] ??
        ModelUsage(
          modelId: modelId,
          cumulativeInputTokens: 0,
          cumulativeOutputTokens: 0,
          callCount: 0,
        );
    return SavingsModel(
      usageByModel: {
        ...usageByModel,
        modelId: existing.addCall(
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        ),
      },
      firstUsageAt: firstUsageAt ?? DateTime.now(),
    );
  }
}

/// Per-model breakdown entry for [SavingsSnapshot.perModelBreakdown].
@immutable
class ModelSavingsBreakdown {
  const ModelSavingsBreakdown({
    required this.modelId,
    required this.displayName,
    required this.callCount,
    required this.inputTokens,
    required this.outputTokens,
    required this.actualCost,
    required this.benchmarkCost,
    required this.savings,
  });

  final String modelId;
  final String displayName;
  final int callCount;
  final int inputTokens;
  final int outputTokens;
  final double actualCost;
  final double benchmarkCost;
  final double savings;
}

/// Computed derived value — NOT persisted. Recalculated on every read from
/// current model_profiles.json + stored per-model token counts.
@immutable
class SavingsSnapshot {
  const SavingsSnapshot({
    required this.totalActualCost,
    required this.totalBenchmarkCost,
    required this.totalSaved,
    required this.totalCalls,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.savingsMultiple,
    required this.benchmarkDisplayName,
    required this.perModelBreakdown,
  });

  static const SavingsSnapshot zero = SavingsSnapshot(
    totalActualCost: 0,
    totalBenchmarkCost: 0,
    totalSaved: 0,
    totalCalls: 0,
    totalInputTokens: 0,
    totalOutputTokens: 0,
    savingsMultiple: 0,
    benchmarkDisplayName: 'Claude Opus 4.6',
    perModelBreakdown: [],
  );

  final double totalActualCost;
  final double totalBenchmarkCost;

  /// benchmark − actual, clamped per-model to ≥ 0. Never decreases.
  final double totalSaved;

  final int totalCalls;
  final int totalInputTokens;
  final int totalOutputTokens;

  /// totalBenchmarkCost / totalActualCost (e.g. 47.3). 0 when no usage yet.
  final double savingsMultiple;

  final String benchmarkDisplayName;
  final List<ModelSavingsBreakdown> perModelBreakdown;
}

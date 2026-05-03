// lib/features/delegation/data/engine/delegation_engine.dart
import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/admin/data/decision_log.dart';
import 'package:briluxforge/features/delegation/data/engine/context_analyzer.dart';
import 'package:briluxforge/features/delegation/data/engine/keyword_category.dart';
import 'package:briluxforge/features/delegation/data/engine/keyword_matrix.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/data/models/sub_task.dart';

/// Layer 1 — local rule engine.
///
/// Runs entirely on-device in < 5 ms. No network call, no ML model.
/// Returns null when confidence is below [AppConstants.delegationConfidenceThreshold],
/// which triggers the Delegation Failure Dialog in the UI layer.
class DelegationEngine {
  const DelegationEngine({
    this.contextAnalyzer = const ContextAnalyzer(),
  });

  final ContextAnalyzer contextAnalyzer;

  /// Tier-aware tiebreak margin — if the top two normalized scores are within
  /// this distance, the tier preference decides the winner.
  static const double _tiebreakerMargin = 0.10;

  /// Core delegation method.
  ///
  /// [availableModels] — the full list from model_profiles.json (may include benchmark).
  /// [connectedProviders] — provider IDs with verified API keys.
  /// [disabledModelIds] — model IDs from the manifest kill-switches.
  /// [decisionLog] — optional ring buffer; when provided, every result is recorded.
  ///
  /// Returns null when no model can be chosen with sufficient confidence.
  DelegationResult? delegate({
    required String prompt,
    required List<ModelProfile> availableModels,
    required List<String> connectedProviders,
    List<String> disabledModelIds = const [],
    DelegationDecisionLog? decisionLog,
  }) {
    final connected = availableModels
        .where((m) =>
            !m.isBenchmark &&
            connectedProviders.contains(m.provider) &&
            !disabledModelIds.contains(m.id))
        .toList();

    if (connected.isEmpty) {
      AppLogger.d('DelegationEngine', 'No connected models — cannot delegate.');
      return null;
    }

    // Single model shortcut: skip scoring, confidence 1.0.
    if (connected.length == 1) {
      final model = connected.first;
      AppLogger.d('DelegationEngine',
          'Single model connected — routing to ${model.displayName}.');
      final result = DelegationResult(
        selectedModelId: model.id,
        selectedProvider: model.provider,
        layerUsed: 1,
        confidence: 1.0,
        reasoning: 'Only one model connected — routing to ${model.displayName}.',
      );
      _record(decisionLog, prompt, KeywordCategory.general, 1.0, result,
          tieBreakerApplied: false);
      return result;
    }

    // ── Context-length check (runs before keyword scoring) ─────────────────
    final context = contextAnalyzer.analyze(prompt);

    if (context.isHugeContext) {
      final candidate = _findByMinContextWindow(connected, 1000000);
      if (candidate != null) {
        AppLogger.d('DelegationEngine',
            'Huge context (${context.estimatedTokens} tokens) → ${candidate.displayName}.');
        final result = DelegationResult(
          selectedModelId: candidate.id,
          selectedProvider: candidate.provider,
          layerUsed: 1,
          confidence: 1.0,
          reasoning: 'Huge context (${context.estimatedTokens} est. tokens) — '
              'forced to ${candidate.displayName} for its massive context window.',
        );
        _record(decisionLog, prompt, KeywordCategory.longContext, 1.0, result,
            tieBreakerApplied: false);
        return result;
      }
      AppLogger.w('DelegationEngine',
          'No connected model with a context window ≥ 1 000 000. Returning null.');
      return null;
    }

    if (context.isLongContext) {
      final candidate = _findByMinContextWindow(connected, 200000);
      if (candidate != null) {
        AppLogger.d('DelegationEngine',
            'Long context (${context.estimatedTokens} tokens) → ${candidate.displayName}.');
        final result = DelegationResult(
          selectedModelId: candidate.id,
          selectedProvider: candidate.provider,
          layerUsed: 1,
          confidence: 1.0,
          reasoning: 'Long context (${context.estimatedTokens} est. tokens) — '
              'routing to ${candidate.displayName} for its large context window.',
        );
        _record(decisionLog, prompt, KeywordCategory.longContext, 1.0, result,
            tieBreakerApplied: false);
        return result;
      }
      // Fall through to keyword scoring.
    }

    // ── Normalized keyword scoring ─────────────────────────────────────────
    final normalizedScores = _computeNormalizedScores(prompt.toLowerCase());

    if (normalizedScores.isEmpty) {
      AppLogger.d('DelegationEngine', 'No keyword matches — returning null.');
      return null;
    }

    // Sort by normalized score descending.
    final sorted = normalizedScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = sorted.first.key;
    final topScore = sorted.first.value;

    AppLogger.d(
        'DelegationEngine',
        'Top category: ${topCategory.jsonKey}  '
        'normalized: ${topScore.toStringAsFixed(3)}');

    if (topScore < AppConstants.delegationConfidenceThreshold) {
      AppLogger.d('DelegationEngine',
          'Normalized score $topScore below threshold — no Layer 1 result.');
      return null;
    }

    // ── Tiebreak check ────────────────────────────────────────────────────
    final secondScore = sorted.length > 1 ? sorted[1].value : 0.0;
    final tiebreaker = (topScore - secondScore) < _tiebreakerMargin;
    final secondCategory = tiebreaker && sorted.length > 1 ? sorted[1].key : null;

    // ── Candidate selection ────────────────────────────────────────────────
    final chosen = _selectModel(
      connected: connected,
      primaryCategory: topCategory,
      secondaryCategory: secondCategory,
      tieBreakerApplied: tiebreaker,
    );

    if (chosen == null) {
      final fallback = _bestConnected(connected);
      AppLogger.d('DelegationEngine',
          'No model for ${topCategory.jsonKey} — using ${fallback.displayName}.');
      final result = DelegationResult(
        selectedModelId: fallback.id,
        selectedProvider: fallback.provider,
        layerUsed: 1,
        confidence: topScore,
        normalizedScores: normalizedScores,
        tieBreakerApplied: tiebreaker,
        reasoning:
            'No connected model specialises in ${topCategory.jsonKey} — '
            'routing to ${fallback.displayName}.',
      );
      _record(decisionLog, prompt, topCategory, topScore, result,
          tieBreakerApplied: tiebreaker);
      return result;
    }

    AppLogger.d(
        'DelegationEngine',
        'Delegating to ${chosen.displayName} '
        '(category: ${topCategory.jsonKey}, '
        'confidence: ${topScore.toStringAsFixed(2)}, '
        'tiebreak: $tiebreaker).');

    final result = DelegationResult(
      selectedModelId: chosen.id,
      selectedProvider: chosen.provider,
      layerUsed: 1,
      confidence: topScore,
      normalizedScores: normalizedScores,
      tieBreakerApplied: tiebreaker,
      reasoning: 'Routed to ${chosen.displayName}: '
          '${topCategory.jsonKey} keywords detected '
          '(confidence: ${(topScore * 100).toStringAsFixed(0)}%)'
          '${tiebreaker ? ', tier tiebreak applied' : ''}.',
    );

    _record(decisionLog, prompt, topCategory, topScore, result,
        tieBreakerApplied: tiebreaker);
    return result;
  }

  // ── Single sub-task routing (used by SequentialExecutor) ──────────────────

  DelegationResult? resolveSingle(
    SubTask subTask,
    List<ModelProfile> availableModels,
    List<String> connectedProviders,
  ) {
    final connected = availableModels
        .where((m) => !m.isBenchmark && connectedProviders.contains(m.provider))
        .toList();

    if (connected.isEmpty) return null;

    if (subTask.categoryConfidence < AppConstants.delegationConfidenceThreshold) {
      return null;
    }

    final candidates = connected
        .where((m) => m.strengths.contains(subTask.category))
        .toList();

    if (candidates.isEmpty) return null;

    final chosen =
        candidates.firstWhereOrNull((m) => m.isWorkhorse) ?? candidates.first;

    return DelegationResult(
      selectedModelId: chosen.id,
      selectedProvider: chosen.provider,
      layerUsed: 1,
      confidence: subTask.categoryConfidence,
      reasoning: 'Sub-task routed to ${chosen.displayName} '
          '(${subTask.category}, '
          '${(subTask.categoryConfidence * 100).toStringAsFixed(0)}%).',
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Returns normalised scores per category — matchedWeightSum / maxPossibleSum.
  /// Only categories with a match > 0 are included; empty categories are skipped.
  Map<KeywordCategory, double> _computeNormalizedScores(String lowerPrompt) {
    final scores = <KeywordCategory, double>{};
    for (final entry in kKeywordMatrix.entries) {
      final keywords = entry.value;
      if (keywords.isEmpty) continue;
      var matched = 0.0;
      for (final wk in keywords) {
        if (lowerPrompt.contains(wk.keyword.toLowerCase())) {
          matched += wk.weight;
        }
      }
      if (matched > 0) {
        final max = maxScoreFor(entry.key);
        scores[entry.key] = (max > 0) ? (matched / max).clamp(0.0, 1.0) : 0.0;
      }
    }
    return scores;
  }

  /// Selects the best connected model for [primaryCategory] with optional
  /// tier-aware tiebreak.
  ModelProfile? _selectModel({
    required List<ModelProfile> connected,
    required KeywordCategory primaryCategory,
    required KeywordCategory? secondaryCategory,
    required bool tieBreakerApplied,
  }) {
    final candidates = connected
        .where((m) => m.strengths.contains(primaryCategory.jsonKey))
        .toList();

    if (candidates.isEmpty) return null;

    if (!tieBreakerApplied || candidates.length == 1) {
      // No tiebreak needed — prefer workhorse for cost efficiency.
      return candidates.firstWhereOrNull((m) => m.isWorkhorse) ??
          candidates.first;
    }

    // Tier-aware tiebreak.
    final preferPremium = KeywordCategory.premiumPreferred.contains(primaryCategory) ||
        (secondaryCategory != null &&
            KeywordCategory.premiumPreferred.contains(secondaryCategory));

    if (primaryCategory == KeywordCategory.lowLatency) {
      // low_latency: pick specialist with lowest latencyHintMs.
      final sorted = List<ModelProfile>.from(candidates)
        ..sort((a, b) => a.latencyHintMs.compareTo(b.latencyHintMs));
      return sorted.first;
    }

    if (primaryCategory == KeywordCategory.highVolumeCheap) {
      // high_volume_cheap: pick the cheapest total cost.
      final sorted = List<ModelProfile>.from(candidates)
        ..sort((a, b) => a.totalCostPer1k.compareTo(b.totalCostPer1k));
      return sorted.first;
    }

    if (preferPremium) {
      return candidates.firstWhereOrNull((m) => m.isPremium) ??
          candidates.firstWhereOrNull((m) => m.isWorkhorse) ??
          candidates.first;
    }

    return candidates.firstWhereOrNull((m) => m.isWorkhorse) ??
        candidates.firstWhereOrNull((m) => m.isPremium) ??
        candidates.first;
  }

  ModelProfile? _findByMinContextWindow(
    List<ModelProfile> models,
    int minWindow,
  ) {
    final eligible =
        models.where((m) => m.contextWindow >= minWindow).toList();
    if (eligible.isEmpty) return null;
    eligible.sort((a, b) {
      if (a.isWorkhorse && !b.isWorkhorse) return -1;
      if (!a.isWorkhorse && b.isWorkhorse) return 1;
      return b.contextWindow.compareTo(a.contextWindow);
    });
    return eligible.first;
  }

  ModelProfile _bestConnected(List<ModelProfile> models) =>
      models.firstWhereOrNull((m) => m.isWorkhorse) ?? models.first;

  /// Records one entry to [decisionLog], hashing the prompt in-place.
  void _record(
    DelegationDecisionLog? log,
    String prompt,
    KeywordCategory winningCategory,
    double normalizedScore,
    DelegationResult result, {
    required bool tieBreakerApplied,
  }) {
    if (log == null) return;
    log.record(DelegationDecisionLogEntry.fromPrompt(
      prompt: prompt,
      winningModelId: result.selectedModelId,
      winningCategory: winningCategory,
      normalizedScore: normalizedScore,
      layerUsed: result.layerUsed,
      tieBreakerApplied: tieBreakerApplied,
    ));
  }
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

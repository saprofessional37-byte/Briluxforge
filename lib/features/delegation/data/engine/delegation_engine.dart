// lib/features/delegation/data/engine/delegation_engine.dart
import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/delegation/data/engine/context_analyzer.dart';
import 'package:briluxforge/features/delegation/data/engine/keyword_matrix.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';

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

  /// Core delegation method.
  ///
  /// [availableModels] — the full list from model_profiles.json (may include benchmark).
  /// [connectedProviders] — provider IDs with verified API keys (e.g. ['deepseek', 'google']).
  ///
  /// Returns null when no model can be chosen with sufficient confidence.
  DelegationResult? delegate({
    required String prompt,
    required List<ModelProfile> availableModels,
    required List<String> connectedProviders,
  }) {
    final connected = availableModels
        .where((m) => !m.isBenchmark && connectedProviders.contains(m.provider))
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
      return DelegationResult(
        selectedModelId: model.id,
        selectedProvider: model.provider,
        layerUsed: 1,
        confidence: 1.0,
        reasoning:
            'Only one model connected — routing to ${model.displayName}.',
      );
    }

    // ── Context-length check (runs before keyword scoring) ──────────────────
    final context = contextAnalyzer.analyze(prompt);

    if (context.isHugeContext) {
      final candidate = _findByMinContextWindow(connected, 1000000);
      if (candidate != null) {
        AppLogger.d('DelegationEngine',
            'Huge context (${context.estimatedTokens} tokens) → ${candidate.displayName}.');
        return DelegationResult(
          selectedModelId: candidate.id,
          selectedProvider: candidate.provider,
          layerUsed: 1,
          confidence: 1.0,
          reasoning:
              'Huge context (${context.estimatedTokens} est. tokens) — forced to '
              '${candidate.displayName} for its massive context window.',
        );
      }
      // No model can handle this — caller must warn the user before sending.
      AppLogger.w('DelegationEngine',
          'No connected model with a context window ≥ 1 000 000. Returning null.');
      return null;
    }

    if (context.isLongContext) {
      final candidate = _findByMinContextWindow(connected, 200000);
      if (candidate != null) {
        AppLogger.d('DelegationEngine',
            'Long context (${context.estimatedTokens} tokens) → ${candidate.displayName}.');
        return DelegationResult(
          selectedModelId: candidate.id,
          selectedProvider: candidate.provider,
          layerUsed: 1,
          confidence: 1.0,
          reasoning:
              'Long context (${context.estimatedTokens} est. tokens) — routing to '
              '${candidate.displayName} for its large context window.',
        );
      }
      // No model meets the context requirement; fall through to keyword scoring.
    }

    // ── Keyword scoring ──────────────────────────────────────────────────────
    final scores = _scoreCategories(prompt.toLowerCase());

    if (scores.isEmpty) {
      AppLogger.d('DelegationEngine', 'No keyword matches — returning null.');
      return null;
    }

    final topEntry =
        scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final topCategory = topEntry.key;
    final topScore = topEntry.value;

    AppLogger.d('DelegationEngine',
        'Top category: $topCategory  score: ${topScore.toStringAsFixed(3)}');

    if (topScore < AppConstants.delegationConfidenceThreshold) {
      AppLogger.d('DelegationEngine',
          'Score $topScore below threshold ${AppConstants.delegationConfidenceThreshold} — no Layer 1 result.');
      return null;
    }

    // Find the best model for this category among connected ones.
    final candidates =
        connected.where((m) => m.strengths.contains(topCategory)).toList();

    if (candidates.isEmpty) {
      // No model specialises in this category — pick best workhorse or first connected.
      final fallback = _bestConnected(connected);
      AppLogger.d('DelegationEngine',
          'No model specialises in $topCategory — using ${fallback.displayName} as general best.');
      return DelegationResult(
        selectedModelId: fallback.id,
        selectedProvider: fallback.provider,
        layerUsed: 1,
        confidence: topScore,
        reasoning:
            'No connected model specialises in $topCategory — routing to ${fallback.displayName}.',
      );
    }

    // Prefer workhorse tier for cost efficiency; fall back to first candidate.
    final workhorse =
        candidates.firstWhereOrNull((m) => m.isWorkhorse) ?? candidates.first;

    AppLogger.d('DelegationEngine',
        'Delegating to ${workhorse.displayName} (category: $topCategory, confidence: ${topScore.toStringAsFixed(2)}).');

    return DelegationResult(
      selectedModelId: workhorse.id,
      selectedProvider: workhorse.provider,
      layerUsed: 1,
      confidence: topScore,
      reasoning:
          'Routed to ${workhorse.displayName}: $topCategory keywords detected '
          '(confidence: ${(topScore * 100).toStringAsFixed(0)}%).',
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Scores each category in [kKeywordMatrix] against [lowerPrompt].
  /// Returns only categories with a score > 0; skips empty category lists
  /// (long_context / general).
  Map<String, double> _scoreCategories(String lowerPrompt) {
    final scores = <String, double>{};
    for (final entry in kKeywordMatrix.entries) {
      if (entry.value.isEmpty) continue;
      var sum = 0.0;
      for (final wk in entry.value) {
        if (lowerPrompt.contains(wk.keyword.toLowerCase())) {
          sum += wk.weight;
        }
      }
      if (sum > 0) scores[entry.key] = sum;
    }
    return scores;
  }

  /// Returns the connected model with the smallest context window that still
  /// meets [minWindow]. Prefers workhorse tier among eligible models.
  ModelProfile? _findByMinContextWindow(
    List<ModelProfile> models,
    int minWindow,
  ) {
    final eligible =
        models.where((m) => m.contextWindow >= minWindow).toList();
    if (eligible.isEmpty) return null;

    // Sort: workhorse first, then by largest context window.
    eligible.sort((a, b) {
      if (a.isWorkhorse && !b.isWorkhorse) return -1;
      if (!a.isWorkhorse && b.isWorkhorse) return 1;
      return b.contextWindow.compareTo(a.contextWindow);
    });
    return eligible.first;
  }

  /// Returns the best general-purpose model from the connected list.
  /// Prefers workhorse tier; falls back to first if none found.
  ModelProfile _bestConnected(List<ModelProfile> models) =>
      models.firstWhereOrNull((m) => m.isWorkhorse) ?? models.first;
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// lib/features/delegation/data/engine/context_analyzer.dart
import 'package:flutter/foundation.dart';
import 'package:briluxforge/core/constants/app_constants.dart';

@immutable
class ContextAnalysisResult {
  const ContextAnalysisResult({
    required this.estimatedTokens,
    required this.isLongContext,
    required this.isHugeContext,
    required this.requiredContextWindow,
  });

  /// Rough token count — 1 token ≈ 4 characters for English text.
  final int estimatedTokens;

  /// True when tokens exceed [AppConstants.longContextTokenThreshold] (30 000).
  final bool isLongContext;

  /// True when tokens exceed [AppConstants.hugeContextTokenThreshold] (100 000).
  /// Forces a model with contextWindow ≥ 1 000 000 if one is connected.
  final bool isHugeContext;

  /// Minimum context window required by this prompt. 0 = no special requirement.
  final int requiredContextWindow;
}

/// Stateless analyzer — estimates token usage and classifies context length.
/// Used ONLY for pre-flight routing decisions. Never used for savings math.
class ContextAnalyzer {
  const ContextAnalyzer();

  /// Rough heuristic: 1 token ≈ 4 characters for English text.
  int estimateTokens(String text) => (text.length / 4).ceil();

  ContextAnalysisResult analyze(String prompt) {
    final tokenCount = estimateTokens(prompt);

    if (tokenCount > AppConstants.hugeContextTokenThreshold) {
      return ContextAnalysisResult(
        estimatedTokens: tokenCount,
        isLongContext: true,
        isHugeContext: true,
        requiredContextWindow: 1000000,
      );
    }

    if (tokenCount > AppConstants.longContextTokenThreshold) {
      return ContextAnalysisResult(
        estimatedTokens: tokenCount,
        isLongContext: true,
        isHugeContext: false,
        requiredContextWindow: 200000,
      );
    }

    return ContextAnalysisResult(
      estimatedTokens: tokenCount,
      isLongContext: false,
      isHugeContext: false,
      requiredContextWindow: 0,
    );
  }
}

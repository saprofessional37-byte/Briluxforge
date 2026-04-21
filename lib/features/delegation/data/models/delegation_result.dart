// lib/features/delegation/data/models/delegation_result.dart
import 'package:flutter/foundation.dart';

import 'package:briluxforge/features/delegation/data/models/task_plan.dart';

@immutable
class DelegationResult {
  const DelegationResult({
    required this.selectedModelId,
    required this.selectedProvider,
    required this.layerUsed,
    required this.confidence,
    required this.reasoning,
    this.wasOverridden = false,
    this.userChoseDefault = false,
    this.plan,
    this.precomputedResponse,
  });

  final String selectedModelId;
  final String selectedProvider;

  /// Which layer made the decision: 1 (local), 2 (AI meta-prompt), 3 (default).
  final int layerUsed;

  /// 0.0–1.0 confidence from the selecting layer.
  final double confidence;

  /// Human-readable explanation shown in the delegation badge.
  final String reasoning;

  /// True when the user manually picked a different model after delegation.
  final bool wasOverridden;

  /// True when the user explicitly chose "Use Default" from the failure dialog.
  final bool userChoseDefault;

  /// Non-null when a multi-API task plan was executed. Carries full routing
  /// breakdown for the multi-model delegation badge.
  final TaskPlan? plan;

  /// Non-null when the plan has already been executed and the stitched response
  /// is ready. ChatProvider uses this to skip the live API call.
  final String? precomputedResponse;

  DelegationResult copyWith({
    String? selectedModelId,
    String? selectedProvider,
    int? layerUsed,
    double? confidence,
    String? reasoning,
    bool? wasOverridden,
    bool? userChoseDefault,
    TaskPlan? plan,
    String? precomputedResponse,
  }) =>
      DelegationResult(
        selectedModelId: selectedModelId ?? this.selectedModelId,
        selectedProvider: selectedProvider ?? this.selectedProvider,
        layerUsed: layerUsed ?? this.layerUsed,
        confidence: confidence ?? this.confidence,
        reasoning: reasoning ?? this.reasoning,
        wasOverridden: wasOverridden ?? this.wasOverridden,
        userChoseDefault: userChoseDefault ?? this.userChoseDefault,
        plan: plan ?? this.plan,
        precomputedResponse: precomputedResponse ?? this.precomputedResponse,
      );
}

// lib/features/delegation/providers/delegation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';
import 'package:briluxforge/features/delegation/data/engine/context_analyzer.dart';
import 'package:briluxforge/features/delegation/data/engine/delegation_engine.dart';
import 'package:briluxforge/features/delegation/data/engine/dependency_resolver.dart';
import 'package:briluxforge/features/delegation/data/engine/fallback_handler.dart';
import 'package:briluxforge/features/delegation/data/engine/task_segmenter.dart';
import 'package:briluxforge/features/delegation/data/engine/worthiness_evaluator.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/data/models/task_plan.dart';
import 'package:briluxforge/features/updater/providers/kill_switches_provider.dart';
import 'package:briluxforge/features/updater/providers/updater_provider.dart';
import 'package:briluxforge/features/delegation/providers/task_plan_provider.dart';
import 'package:briluxforge/features/settings/providers/settings_provider.dart';
import 'package:briluxforge/services/secure_storage_service.dart';

part 'delegation_provider.g.dart';

const _uuid = Uuid();
const _contextAnalyzer = ContextAnalyzer();
const _segmenter = TaskSegmenter();
const _evaluator = WorthinessEvaluator();
const _resolver = DependencyResolver();

/// Convenience provider: list of provider IDs that have verified API keys.
@riverpod
List<String> connectedProviders(Ref ref) {
  final keys = ref.watch(apiKeyNotifierProvider).valueOrNull ?? [];
  return keys
      .where((k) => k.status == VerificationStatus.verified)
      .map((k) => k.provider)
      .toList();
}

/// Manages the active delegation result for the current message being composed.
///
/// Flow for the chat screen:
///   1. Call [tryLayer1] — returns a result if confident, null if uncertain.
///      If the prompt warrants a multi-API plan, tryLayer1 executes it and
///      returns a result with [DelegationResult.plan] and
///      [DelegationResult.precomputedResponse] set.
///   2. If null, show [DelegationFailureDialog].
///   3. Based on user choice call [resolveDefault] or [resolveWithAI].
///   4. Use the returned [DelegationResult] for the API call.
///   5. Call [applyManualOverride] if the user changes the model via the badge.
///   6. Call [clearResult] when starting a new message.
@riverpod
class DelegationNotifier extends _$DelegationNotifier {
  @override
  DelegationResult? build() {
    // Invalidate whenever kill-switches change so stale routing results are
    // discarded and the next delegate call uses fresh data (Phase 11.8 §5.2).
    ref.watch(killSwitchesProvider);
    return null;
  }

  // ── Layer 1 (with multi-API pre-stage) ────────────────────────────────────

  /// Runs the local rule engine. Returns null when confidence is below the
  /// threshold — the caller should then show [DelegationFailureDialog].
  ///
  /// If the prompt is determined to warrant multi-API routing, this method
  /// executes the full task plan and returns a [DelegationResult] with
  /// [DelegationResult.precomputedResponse] set — the chat provider skips its
  /// live API call and uses the precomputed content directly.
  Future<DelegationResult?> tryLayer1(String prompt) async {
    final profiles = ref.read(liveModelProfilesProvider).valueOrNull;
    if (profiles == null) {
      AppLogger.w('DelegationNotifier',
          'Model profiles not yet loaded — cannot run Layer 1.');
      return null;
    }
    final connected = ref.read(connectedProvidersProvider);
    final disabledModelIds =
        ref.read(killSwitchesProvider).valueOrNull?.disabledModelIds ??
            const [];

    // ── Multi-API pre-stage ──────────────────────────────────────────────────
    final totalTokens = _contextAnalyzer.estimateTokens(prompt);
    final candidates = _segmenter.segment(prompt);
    final verdict = _evaluator.evaluate(candidates, totalTokens);

    if (verdict.segmentationWorthwhile && verdict.subTasks != null) {
      AppLogger.d('DelegationNotifier',
          'Plan pre-stage: ${verdict.subTasks!.length} sub-tasks detected.');

      // Build the plan with dependency resolution.
      final resolvedSubTasks = _resolver.resolve(verdict.subTasks!);
      final plan = TaskPlan(
        id: _uuid.v4(),
        originalPrompt: prompt,
        subTasks: resolvedSubTasks,
        status: TaskPlanStatus.planning,
        createdAt: DateTime.now(),
      );

      final stitchedContent = await ref
          .read(taskPlanNotifierProvider.notifier)
          .runPlan(plan);

      if (stitchedContent != null) {
        // Plan succeeded — build a representative DelegationResult.
        final completedPlan =
            ref.read(taskPlanNotifierProvider) ?? plan;
        final firstCompletedTask = completedPlan.subTasks
            .firstWhereOrNull((t) => t.selectedModelId != null);

        final result = DelegationResult(
          selectedModelId:
              firstCompletedTask?.selectedModelId ?? 'multi-route',
          selectedProvider:
              firstCompletedTask?.selectedProvider ?? 'multi',
          layerUsed: 1,
          confidence: 1.0,
          reasoning: 'Multi-route plan: '
              '${completedPlan.subTasks.length} sub-tasks executed.',
          plan: completedPlan,
          precomputedResponse: stitchedContent,
        );
        state = result;
        return result;
      }
      // Plan abandoned — fall through to monolithic Layer 1.
      AppLogger.d('DelegationNotifier',
          'Plan abandoned — falling through to monolithic Layer 1.');
    }

    // ── Monolithic Layer 1 ───────────────────────────────────────────────────
    const engine = DelegationEngine();
    final result = engine.delegate(
      prompt: prompt,
      availableModels: profiles.routeableModels,
      connectedProviders: connected,
      disabledModelIds: disabledModelIds,
    );

    if (result != null) state = result;
    return result;
  }

  // ── Layer 3 — user chose "Use Default" ────────────────────────────────────

  Future<DelegationResult> resolveDefault(String prompt) async {
    final profiles = ref.read(liveModelProfilesProvider).valueOrNull!;
    final settings = await ref.read(settingsNotifierProvider.future);
    final connected = ref.read(connectedProvidersProvider);

    final handler = FallbackHandler(
      secureStorage: ref.read(secureStorageServiceProvider),
    );

    final result = handler.layer3Default(
      defaultModelId: settings.defaultModelId,
      availableModels: profiles.routeableModels,
      connectedProviders: connected,
      userChoseDefault: true,
    );

    state = result;
    return result;
  }

  // ── Layer 2 → Layer 3 — user chose "Let AI Decide" ────────────────────────

  Future<DelegationResult> resolveWithAI(String prompt) async {
    final profiles = ref.read(liveModelProfilesProvider).valueOrNull!;
    final settings = await ref.read(settingsNotifierProvider.future);
    final connected = ref.read(connectedProvidersProvider);

    final handler = FallbackHandler(
      secureStorage: ref.read(secureStorageServiceProvider),
    );

    final layer2 = await handler.layer2Classify(
      prompt: prompt,
      availableModels: profiles.routeableModels,
      connectedProviders: connected,
      defaultModelId: settings.defaultModelId,
    );

    if (layer2 != null) {
      state = layer2;
      return layer2;
    }

    AppLogger.w('DelegationNotifier',
        'Layer 2 classification failed — falling back to Layer 3.');

    final layer3 = handler.layer3Default(
      defaultModelId: settings.defaultModelId,
      availableModels: profiles.routeableModels,
      connectedProviders: connected,
    );

    state = layer3;
    return layer3;
  }

  // ── Manual override ────────────────────────────────────────────────────────

  DelegationResult applyManualOverride({
    required DelegationResult original,
    required ModelProfile chosenModel,
  }) {
    final overridden = original.copyWith(
      selectedModelId: chosenModel.id,
      selectedProvider: chosenModel.provider,
      wasOverridden: true,
      reasoning: 'Manual override: you selected ${chosenModel.displayName}.',
    );
    state = overridden;
    return overridden;
  }

  void clearResult() => state = null;
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

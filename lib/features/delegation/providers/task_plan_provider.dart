// lib/features/delegation/providers/task_plan_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/features/delegation/data/engine/delegation_engine.dart';
import 'package:briluxforge/features/delegation/data/engine/response_stitcher.dart';
import 'package:briluxforge/features/delegation/data/engine/sequential_executor.dart';
import 'package:briluxforge/features/delegation/data/models/task_plan.dart';
import 'package:briluxforge/features/delegation/providers/delegation_provider.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';
import 'package:briluxforge/features/skills/providers/skills_provider.dart';
import 'package:briluxforge/services/api_client_service.dart';
import 'package:briluxforge/services/skill_injection_service.dart';

part 'task_plan_provider.g.dart';

// ── Internal factory providers ────────────────────────────────────────────────

@riverpod
Future<SequentialExecutor> sequentialExecutor(Ref ref) async {
  final profiles = await ref.watch(modelProfilesProvider.future);
  final connected = ref.watch(connectedProvidersProvider);
  final enabledSkills = ref.watch(enabledSkillsProvider);
  final apiClient = ref.watch(apiClientServiceProvider);
  final skillService = ref.watch(skillInjectionServiceProvider);

  return SequentialExecutor(
    delegationEngine: const DelegationEngine(),
    apiClientService: apiClient,
    skillInjectionService: skillService,
    availableModels: profiles.routeableModels,
    connectedProviders: connected,
    enabledSkills: enabledSkills,
  );
}

@riverpod
ResponseStitcher responseStitcher(Ref ref) => const ResponseStitcher();

// ── TaskPlanNotifier ──────────────────────────────────────────────────────────

@riverpod
class TaskPlanNotifier extends _$TaskPlanNotifier {
  @override
  TaskPlan? build() => null;

  /// Executes [plan] through the SequentialExecutor and ResponseStitcher.
  /// Advances [state] on every progress event. Returns the fully stitched
  /// assistant message string, or null if the plan was abandoned (caller must
  /// fall through to monolithic delegation).
  Future<String?> runPlan(TaskPlan plan) async {
    state = plan;

    final executor = await ref.read(sequentialExecutorProvider.future);
    final stitcher = ref.read(responseStitcherProvider);

    final progressStream = executor.execute(plan);

    // Wire progress into the stitcher while also advancing our own state.
    final progressController = StreamController<TaskPlanProgress>.broadcast();

    // Collect stitched chunks while forwarding progress events.
    final stitchedChunks = <String>[];
    final stitchFuture = stitcher
        .stitch(progressController.stream)
        .forEach(stitchedChunks.add);

    TaskPlan? finalPlan;
    await for (final event in progressStream) {
      state = event.plan;
      finalPlan = event.plan;
      progressController.add(event);
    }

    await progressController.close();
    await stitchFuture;

    if (finalPlan?.status == TaskPlanStatus.abandoned) {
      state = null;
      return null;
    }

    // Mark plan completed.
    if (finalPlan != null) {
      state = finalPlan.copyWith(status: TaskPlanStatus.completed);
    }

    return stitchedChunks.join();
  }

  void reset() => state = null;
}

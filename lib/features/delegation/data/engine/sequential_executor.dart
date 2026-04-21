// lib/features/delegation/data/engine/sequential_executor.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:briluxforge/features/delegation/data/engine/delegation_engine.dart';
import 'package:briluxforge/features/delegation/data/engine/response_stitcher.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/data/models/sub_task.dart';
import 'package:briluxforge/features/delegation/data/models/task_plan.dart';
import 'package:briluxforge/features/skills/data/models/skill_model.dart';
import 'package:briluxforge/services/api_client_service.dart';
import 'package:briluxforge/services/api_response.dart';
import 'package:briluxforge/services/skill_injection_service.dart';

// ── Progress event ────────────────────────────────────────────────────────────

@immutable
class TaskPlanProgress {
  const TaskPlanProgress({
    required this.plan,
    this.justCompletedSubTaskId,
  });

  final TaskPlan plan;
  final String? justCompletedSubTaskId;
}

// ── Executor ──────────────────────────────────────────────────────────────────

/// Executes the dependency DAG — firing independent sub-tasks in parallel,
/// awaiting dependencies, and feeding upstream outputs as context downstream.
class SequentialExecutor {
  const SequentialExecutor({
    required this.delegationEngine,
    required this.apiClientService,
    required this.skillInjectionService,
    required this.availableModels,
    required this.connectedProviders,
    required this.enabledSkills,
  });

  final DelegationEngine delegationEngine;
  final ApiClientService apiClientService;
  final SkillInjectionService skillInjectionService;
  final List<ModelProfile> availableModels;
  final List<String> connectedProviders;
  final List<SkillModel> enabledSkills;

  /// Executes the plan stage by stage. Emits a [TaskPlanProgress] after each
  /// sub-task transitions. Completes with a final [TaskPlanProgress] whose
  /// plan status is either [TaskPlanStatus.stitching] (success) or
  /// [TaskPlanStatus.abandoned] (Layer 1 routing failed for a sub-task).
  Stream<TaskPlanProgress> execute(TaskPlan initialPlan) async* {
    var plan = initialPlan.copyWith(status: TaskPlanStatus.executing);
    yield TaskPlanProgress(plan: plan);

    // Topological sort into stages.
    final stages = _topoSort(plan.subTasks);

    for (final stage in stages) {
      // Route every sub-task in the stage via Layer 1.
      final routedStage = <SubTask>[];
      for (final task in stage) {
        final routing = delegationEngine.resolveSingle(
          task,
          availableModels,
          connectedProviders,
        );
        if (routing == null) {
          // Layer 1 uncertain — abandon the entire plan.
          final abandoned = plan.copyWith(status: TaskPlanStatus.abandoned);
          yield TaskPlanProgress(plan: abandoned);
          return;
        }
        final routed = task.copyWith(
          status: SubTaskStatus.routing,
          selectedModelId: routing.selectedModelId,
          selectedProvider: routing.selectedProvider,
        );
        plan = plan.replaceSubTask(routed);
        routedStage.add(routed);
        yield TaskPlanProgress(plan: plan);
      }

      // Fire all tasks in this stage concurrently.
      final futures = routedStage.map((t) => _fireOne(t, plan));
      final results = await Future.wait(futures);

      for (final completed in results) {
        plan = plan.replaceSubTask(completed);
        yield TaskPlanProgress(
          plan: plan,
          justCompletedSubTaskId: completed.id,
        );
      }

      // Propagate failures: downstream sub-tasks that depend on a failed task.
      plan = _markDependentsFailed(plan);
    }

    // Transition to stitching.
    plan = plan.copyWith(status: TaskPlanStatus.stitching);
    yield TaskPlanProgress(plan: plan);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Executes one sub-task's API call. Never throws — failures are captured
  /// as [SubTaskStatus.failed] with a sanitized error message.
  Future<SubTask> _fireOne(SubTask task, TaskPlan plan) async {
    // Check if any upstream dependency already failed.
    final failedUpstream = task.dependsOn.any((depId) {
      final dep = plan.subTasks.firstWhere(
        (t) => t.id == depId,
        orElse: () => task,
      );
      return dep.status == SubTaskStatus.failed;
    });

    if (failedUpstream) {
      return task.copyWith(
        status: SubTaskStatus.failed,
        errorMessage: 'Upstream step failed; this step was not executed.',
      );
    }

    // Build context blocks from upstream dependencies' responses.
    final contextBlocks = StringBuffer();
    for (final depId in task.dependsOn) {
      final dep = plan.subTasks.firstWhereOrNull((t) => t.id == depId);
      if (dep?.response != null) {
        contextBlocks.writeln(
          '### Context from previous step (${dep!.category}):\n${dep.response}\n',
        );
      }
    }

    // Build the system prompt: shared preamble + skill prompt + context blocks.
    final skillPrompt = skillInjectionService.buildSystemPrompt(
      enabledSkills: enabledSkills,
      selectedProvider: task.selectedProvider ?? '',
    );
    final systemParts = <String>[
      kSharedPreamble,
      if (skillPrompt.isNotEmpty) skillPrompt,
      if (contextBlocks.isNotEmpty) contextBlocks.toString().trim(),
    ];
    final systemPrompt = systemParts.join('\n\n');

    final messages = [ChatMessage(role: 'user', content: task.text)];

    try {
      final response = await apiClientService.sendPrompt(
        provider: task.selectedProvider!,
        modelId: task.selectedModelId!,
        messages: messages,
        systemPrompt: systemPrompt,
      );
      return task.copyWith(
        status: SubTaskStatus.completed,
        response: response.content,
      );
    } catch (e) {
      return task.copyWith(
        status: SubTaskStatus.failed,
        errorMessage: _sanitizeError(e.toString()),
      );
    }
  }

  /// Topological sort (Kahn's algorithm). Returns a list of stages; each
  /// stage is a list of sub-tasks that can run concurrently.
  List<List<SubTask>> _topoSort(List<SubTask> subTasks) {
    final inDegree = <String, int>{
      for (final t in subTasks) t.id: t.dependsOn.length,
    };
    final stages = <List<SubTask>>[];
    final remaining = List<SubTask>.from(subTasks);

    while (remaining.isNotEmpty) {
      final stage =
          remaining.where((t) => inDegree[t.id] == 0).toList();
      if (stage.isEmpty) break; // Cycle guard — resolver already validated.
      stages.add(stage);
      for (final completed in stage) {
        remaining.remove(completed);
        for (final t in remaining) {
          if (t.dependsOn.contains(completed.id)) {
            inDegree[t.id] = (inDegree[t.id] ?? 1) - 1;
          }
        }
      }
    }

    return stages;
  }

  TaskPlan _markDependentsFailed(TaskPlan plan) {
    var updated = plan;
    for (final task in plan.subTasks) {
      if (task.status == SubTaskStatus.failed) continue;
      if (task.status == SubTaskStatus.pending ||
          task.status == SubTaskStatus.routing) {
        final hasFailedDep = task.dependsOn.any((depId) {
          final dep =
              plan.subTasks.firstWhereOrNull((t) => t.id == depId);
          return dep?.status == SubTaskStatus.failed;
        });
        if (hasFailedDep) {
          updated = updated.replaceSubTask(task.copyWith(
            status: SubTaskStatus.failed,
            errorMessage: 'Upstream step failed; this step was not executed.',
          ));
        }
      }
    }
    return updated;
  }

  String _sanitizeError(String error) {
    // Truncate to prevent leaking large API error bodies.
    const maxLen = 200;
    final trimmed = error.length > maxLen ? error.substring(0, maxLen) : error;
    return trimmed
        .replaceAll(RegExp(r'sk-[A-Za-z0-9_-]{10,}'), '[REDACTED]')
        .replaceAll(RegExp(r'AIza[A-Za-z0-9_-]{35}'), '[REDACTED]');
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

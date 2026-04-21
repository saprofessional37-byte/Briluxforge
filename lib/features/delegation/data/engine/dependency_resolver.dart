// lib/features/delegation/data/engine/dependency_resolver.dart
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/features/delegation/data/models/sub_task.dart';

/// Builds the dependency DAG for a list of sub-tasks so that the executor
/// knows which sub-tasks can run in parallel and which must await others.
class DependencyResolver {
  const DependencyResolver();

  // Discourse markers that create an explicit dependency on the preceding segment.
  static const List<String> _kDependencyMarkers = [
    'then',
    'after that',
    'once you have',
    'using that',
    'based on the research',
    'with the findings',
    'finally',
    'taking those',
    'and then',
    'based on',
    'using the',
    'from the',
  ];

  // Category pairs where the first naturally precedes the second.
  // key = upstream category, value = downstream categories that depend on it.
  static const Map<String, List<String>> _kCategoryOrder = {
    'research': ['writing', 'coding', 'summarization'],
    'summarization': ['writing', 'coding', 'reasoning'],
    'writing': ['summarization'],
  };

  /// Returns the same list of [subTasks] in the same order, with each
  /// [SubTask.dependsOn] populated per the detection rules in §2.3.3.
  List<SubTask> resolve(List<SubTask> subTasks) {
    if (subTasks.length <= 1) return subTasks;

    // Build a mutable dependency map: taskId → set of prerequisite IDs.
    final deps = <String, Set<String>>{
      for (final t in subTasks) t.id: {},
    };

    for (var i = 0; i < subTasks.length; i++) {
      final task = subTasks[i];
      final lowerText = task.text.toLowerCase();

      // Rule 1: discourse-marker dependency (depends on immediately preceding).
      if (i > 0) {
        final hasDependencyMarker = _kDependencyMarkers.any(
          (m) => lowerText.contains(m),
        );
        if (hasDependencyMarker) {
          deps[task.id]!.add(subTasks[i - 1].id);
        }
      }

      // Rule 2: category-ordering heuristics — scan all prior tasks.
      for (var j = 0; j < i; j++) {
        final prior = subTasks[j];
        final downstreams = _kCategoryOrder[prior.category];
        if (downstreams != null && downstreams.contains(task.category)) {
          // Only add dependency if there is no existing discourse-marker dep
          // from rule 1 — to avoid duplicate entries.
          deps[task.id]!.add(prior.id);
        }
      }
    }

    // Defensive topological sort (Kahn's algorithm) to verify no cycles.
    _verifyAcyclic(subTasks, deps);

    // Apply deps back to sub-tasks immutably.
    return subTasks
        .map((t) => t.copyWith(dependsOn: deps[t.id]!.toList()))
        .toList();
  }

  // ── Kahn's algorithm ───────────────────────────────────────────────────────

  void _verifyAcyclic(
    List<SubTask> subTasks,
    Map<String, Set<String>> deps,
  ) {
    // In-degree map: how many unresolved prerequisites each task has.
    final inDegree = <String, int>{
      for (final t in subTasks) t.id: deps[t.id]!.length,
    };

    final queue = subTasks
        .where((t) => inDegree[t.id] == 0)
        .map((t) => t.id)
        .toList();

    var processed = 0;

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      processed++;

      // Reduce in-degree for tasks that depended on `current`.
      for (final t in subTasks) {
        if (deps[t.id]!.contains(current)) {
          inDegree[t.id] = (inDegree[t.id] ?? 1) - 1;
          if (inDegree[t.id] == 0) {
            queue.add(t.id);
          }
        }
      }
    }

    if (processed != subTasks.length) {
      throw const DelegationException('Cyclic task plan detected');
    }
  }
}

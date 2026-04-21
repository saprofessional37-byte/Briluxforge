// lib/features/delegation/data/engine/response_stitcher.dart
import 'dart:async';

import 'package:briluxforge/features/delegation/data/engine/sequential_executor.dart';
import 'package:briluxforge/features/delegation/data/models/sub_task.dart';
import 'package:briluxforge/features/delegation/data/models/task_plan.dart';

// ── Shared preamble (verbatim per §2.3.5) ─────────────────────────────────────

const String kSharedPreamble =
    'You are part of a multi-step response to the user\'s request. '
    'Other models are handling different parts of the same request. '
    'Your specific assignment is described in the user message. '
    'Write only your section. '
    'Respond in GitHub-flavored markdown. '
    'Do not greet the user. '
    'Do not restate the user\'s question. '
    'Do not summarize what other models are doing. '
    'Do not include a title or heading — the orchestrator adds the section heading. '
    'Begin your response with the first sentence of the substantive answer.';

// ── Category display names ────────────────────────────────────────────────────

const Map<String, String> kCategoryDisplayNames = {
  'coding': 'Implementation',
  'research': 'Research',
  'writing': 'Drafting',
  'summarization': 'Summary',
  'reasoning': 'Analysis',
  'math': 'Calculations',
  'long_context': 'Response',
  'general': 'Response',
};

// ── ResponseStitcher ──────────────────────────────────────────────────────────

/// Turns heterogeneous raw model responses into one cohesive markdown message.
/// Listens to the executor's progress stream and emits each section as the
/// corresponding sub-task completes — progressive section reveal.
class ResponseStitcher {
  const ResponseStitcher();

  /// Returns a stream of markdown chunks. Each completed sub-task emits one
  /// section block (`## Heading\n\nbody\n\n`). When the progress stream closes,
  /// a routing footer is emitted as the final chunk.
  Stream<String> stitch(Stream<TaskPlanProgress> progress) async* {
    final completedIds = <String>{};
    TaskPlan? lastPlan;

    await for (final event in progress) {
      lastPlan = event.plan;
      final completedId = event.justCompletedSubTaskId;

      if (completedId != null && !completedIds.contains(completedId)) {
        completedIds.add(completedId);
        final task = event.plan.subTasks.firstWhereOrNull(
          (t) => t.id == completedId,
        );
        if (task != null && task.status == SubTaskStatus.completed && task.response != null) {
          final displayName =
              kCategoryDisplayNames[task.category] ?? 'Response';
          final processed = _postProcess(task.response!);
          yield '## $displayName\n\n$processed\n\n';
        }
      }
    }

    // Emit routing footer.
    if (lastPlan != null) {
      yield _buildFooter(lastPlan);
    }
  }

  // ── Post-processing pipeline ───────────────────────────────────────────────

  String _postProcess(String raw) {
    var result = raw;
    result = _stripConversationalPreamble(result);
    result = _stripTrailingSignOff(result);
    result = _normalizeHeadingLevels(result);
    result = _unifyListMarkers(result);
    result = _collapseBlankLines(result);
    return result.trim();
  }

  /// Rule 1: Remove opening conversational filler lines.
  String _stripConversationalPreamble(String text) {
    const pattern =
        r"^(Sure|Here(?:'s| is)|Certainly|Of course|Absolutely|"
        r'Great question|No problem|Got it)[!.,]? ?.*$';
    final lines = text.split('\n');
    while (lines.isNotEmpty &&
        RegExp(pattern, caseSensitive: false).hasMatch(lines.first.trim())) {
      lines.removeAt(0);
    }
    return lines.join('\n');
  }

  /// Rule 2: Remove trailing sign-off lines.
  String _stripTrailingSignOff(String text) {
    const pattern =
        r'^(Let me know|Hope this helps|Feel free to ask|If you need).*$';
    final lines = text.split('\n');
    while (lines.isNotEmpty &&
        RegExp(pattern, caseSensitive: false).hasMatch(lines.last.trim())) {
      lines.removeLast();
    }
    return lines.join('\n');
  }

  /// Rule 3: Demote # and ## headings to ### so the stitcher's ## headings dominate.
  String _normalizeHeadingLevels(String text) {
    return text.replaceAllMapped(
      RegExp(r'^(#{1,2})(\s)', multiLine: true),
      (m) => '###${m.group(2)}',
    );
  }

  /// Rule 4: Replace line-leading • and * bullets with -.
  /// Preserves *bold* and *italic* by only touching line-leading occurrences.
  String _unifyListMarkers(String text) {
    return text.replaceAllMapped(
      RegExp(r'^([•*])(\s)', multiLine: true),
      (m) => '-${m.group(2)}',
    );
  }

  /// Rule 5: Collapse runs of more than one blank line to a single blank line.
  String _collapseBlankLines(String text) {
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  // ── Routing footer ─────────────────────────────────────────────────────────

  String _buildFooter(TaskPlan plan) {
    final hasFailures =
        plan.subTasks.any((t) => t.status == SubTaskStatus.failed);
    final buffer = StringBuffer();

    if (hasFailures) {
      final failed =
          plan.subTasks.where((t) => t.status == SubTaskStatus.failed);
      buffer.writeln(
        '> **One or more steps encountered an error.** '
        'The following sections could not be completed: '
        '${failed.map((t) => kCategoryDisplayNames[t.category] ?? t.category).join(', ')}. '
        'Try re-sending the relevant portion of your request.\n',
      );
    }

    buffer.writeln('<details>');
    buffer.writeln('<summary>Routing breakdown</summary>\n');
    for (final task in plan.subTasks) {
      final displayName = kCategoryDisplayNames[task.category] ?? task.category;
      final model = task.selectedModelId ?? 'unknown';
      final provider = task.selectedProvider ?? 'unknown';
      final confidence = (task.categoryConfidence * 100).toStringAsFixed(0);
      final statusLabel =
          task.status == SubTaskStatus.failed ? ' ⚠ failed' : '';
      buffer.writeln(
        '- **$displayName** → $model ($provider) · $confidence% confidence$statusLabel',
      );
    }
    buffer.writeln('\n</details>');

    return buffer.toString();
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

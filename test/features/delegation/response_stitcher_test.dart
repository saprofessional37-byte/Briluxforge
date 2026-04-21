// test/features/delegation/response_stitcher_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:briluxforge/features/delegation/data/engine/response_stitcher.dart';
import 'package:briluxforge/features/delegation/data/engine/sequential_executor.dart';
import 'package:briluxforge/features/delegation/data/models/sub_task.dart';
import 'package:briluxforge/features/delegation/data/models/task_plan.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

SubTask _makeCompletedTask({
  required String id,
  required int orderIndex,
  required String category,
  required String response,
}) =>
    SubTask(
      id: id,
      orderIndex: orderIndex,
      text: 'Task text.',
      category: category,
      categoryConfidence: 0.85,
      estimatedTokens: 80,
      dependsOn: const [],
      status: SubTaskStatus.completed,
      selectedModelId: 'gemini-2.0-flash',
      selectedProvider: 'google',
      response: response,
    );

SubTask _makeFailedTask({
  required String id,
  required int orderIndex,
  required String category,
}) =>
    SubTask(
      id: id,
      orderIndex: orderIndex,
      text: 'Task text.',
      category: category,
      categoryConfidence: 0.85,
      estimatedTokens: 80,
      dependsOn: const [],
      status: SubTaskStatus.failed,
      errorMessage: 'API failed.',
    );

TaskPlan _makePlan(List<SubTask> tasks) => TaskPlan(
      id: 'plan-1',
      originalPrompt: 'Test.',
      subTasks: tasks,
      status: TaskPlanStatus.stitching,
      createdAt: DateTime.now(),
    );

Stream<TaskPlanProgress> _progressStreamFor(TaskPlan plan) async* {
  // Emit one progress event per task — completed tasks carry their id as the
  // justCompleted marker; failed tasks emit null. This mirrors SequentialExecutor,
  // which always emits an event so the stitcher can capture lastPlan.
  for (final task in plan.subTasks) {
    yield TaskPlanProgress(
      plan: plan,
      justCompletedSubTaskId:
          task.status == SubTaskStatus.completed ? task.id : null,
    );
  }
}

void main() {
  const stitcher = ResponseStitcher();

  group('ResponseStitcher', () {
    test('preamble strip removes "Sure, here is" opening lines', () async {
      final task = _makeCompletedTask(
        id: 'a',
        orderIndex: 0,
        category: 'research',
        response: 'Sure! Here is the research summary.\n\nActual content here.',
      );
      final plan = _makePlan([task]);
      final chunks = await stitcher.stitch(_progressStreamFor(plan)).toList();
      final combined = chunks.join();
      expect(combined, isNot(contains('Sure!')));
      expect(combined, contains('Actual content here'));
    });

    test('sign-off strip removes trailing "Hope this helps" lines', () async {
      final task = _makeCompletedTask(
        id: 'a',
        orderIndex: 0,
        category: 'writing',
        response: 'Here is the article.\n\nHope this helps you!',
      );
      final plan = _makePlan([task]);
      final chunks = await stitcher.stitch(_progressStreamFor(plan)).toList();
      final combined = chunks.join();
      expect(combined, isNot(contains('Hope this helps')));
    });

    test('heading demotion — H1 and H2 become H3', () async {
      final task = _makeCompletedTask(
        id: 'a',
        orderIndex: 0,
        category: 'research',
        response: '# Top-level heading\n\n## Sub heading\n\nContent.',
      );
      final plan = _makePlan([task]);
      final chunks = await stitcher.stitch(_progressStreamFor(plan)).toList();
      final combined = chunks.join();
      expect(combined, isNot(contains('\n# ')));
      expect(combined, isNot(contains('\n## ')));
      expect(combined, contains('### '));
    });

    test('bullet-marker unification replaces • and * with -', () async {
      final task = _makeCompletedTask(
        id: 'a',
        orderIndex: 0,
        category: 'research',
        response: '• Item one\n* Item two\n- Item three',
      );
      final plan = _makePlan([task]);
      final chunks = await stitcher.stitch(_progressStreamFor(plan)).toList();
      final combined = chunks.join();
      expect(combined, isNot(contains('• ')));
      // Leading * bullets should be replaced; *bold* should remain.
      final lines = combined.split('\n');
      for (final line in lines) {
        if (line.startsWith('* ')) {
          fail('Found unconverted leading * bullet: $line');
        }
      }
    });

    test('blank-line collapse — more than one blank line becomes one', () async {
      final task = _makeCompletedTask(
        id: 'a',
        orderIndex: 0,
        category: 'coding',
        response: 'Line one.\n\n\n\nLine two.',
      );
      final plan = _makePlan([task]);
      final chunks = await stitcher.stitch(_progressStreamFor(plan)).toList();
      final combined = chunks.join();
      expect(combined, isNot(contains('\n\n\n')));
    });

    test('routing footer contains model and provider info', () async {
      final task = _makeCompletedTask(
        id: 'a',
        orderIndex: 0,
        category: 'research',
        response: 'Some research content.',
      );
      final plan = _makePlan([task]);
      final chunks = await stitcher.stitch(_progressStreamFor(plan)).toList();
      final footer = chunks.last;
      expect(footer, contains('<details>'));
      expect(footer, contains('gemini-2.0-flash'));
      expect(footer, contains('google'));
    });

    test('failure notice appears above footer when a task failed', () async {
      final failedTask = _makeFailedTask(
        id: 'f',
        orderIndex: 0,
        category: 'coding',
      );
      final plan = _makePlan([failedTask]);
      // No completed tasks, only failed — no sections emitted, just footer.
      final chunks = await stitcher.stitch(_progressStreamFor(plan)).toList();
      final combined = chunks.join();
      expect(combined, contains('error'));
    });
  });
}

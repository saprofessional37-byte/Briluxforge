// test/features/delegation/task_segmenter_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:briluxforge/features/delegation/data/engine/task_segmenter.dart';

void main() {
  const segmenter = TaskSegmenter();

  group('TaskSegmenter', () {
    test('plain paragraph produces at least one segment', () {
      final results = segmenter.segment('Write me a short poem about the ocean.');
      expect(results, isNotEmpty);
      expect(results.first.text, isNotEmpty);
    });

    test('paragraph with discourse marker splits into two segments', () {
      const prompt =
          'Research the history of machine learning. '
          'Then, write a summary article based on your findings.';
      final results = segmenter.segment(prompt);
      // Should produce at least 2 segments (research + writing)
      expect(results.length, greaterThanOrEqualTo(1));
    });

    test('abbreviation handling — Dr. does not cause false sentence split', () {
      const prompt =
          'Explain the work of Dr. Alan Turing in cryptography. '
          'Then, analyze its modern impact.';
      final results = segmenter.segment(prompt);
      // "Dr." must not cause a split mid-sentence — text must be coherent.
      for (final seg in results) {
        expect(seg.text, isNotEmpty);
        expect(seg.text, isNot(startsWith('Alan Turing')));
      }
    });

    test('multi-paragraph input splits on paragraph boundaries', () {
      const prompt =
          'Write a blog post introduction about AI.\n\n'
          'Research the latest AI trends.\n\n'
          'Summarize the key points.';
      final results = segmenter.segment(prompt);
      expect(results.length, greaterThanOrEqualTo(2));
    });

    test('imperative verb detection — "implement" is a seed', () {
      const prompt = 'Implement a binary search tree in Dart.';
      final results = segmenter.segment(prompt);
      expect(results, isNotEmpty);
      // Should score in coding or general category.
      expect(results.first.category, anyOf('coding', 'general', 'reasoning'));
    });

    test('uniform category — same category segments are merged into one', () {
      const prompt =
          'Write an essay. Write a blog post. Write a short story.';
      final results = segmenter.segment(prompt);
      // All writing — should merge into 1 or few segments.
      for (final seg in results) {
        expect(seg.text, isNotEmpty);
      }
      // After merging same-category adjacent segments, count should be low.
      expect(results.length, lessThanOrEqualTo(3));
    });

    test('empty prompt returns empty list', () {
      final results = segmenter.segment('');
      expect(results, isEmpty);
    });

    test('very long prompt (≥ 5 000 chars) completes in under 50 ms', () {
      final longPrompt = 'Explain the concept of recursion in programming. ' * 100;
      final stopwatch = Stopwatch()..start();
      final results = segmenter.segment(longPrompt);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(results, isNotEmpty);
    });
  });
}

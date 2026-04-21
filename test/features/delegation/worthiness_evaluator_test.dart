// test/features/delegation/worthiness_evaluator_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:briluxforge/features/delegation/data/engine/task_segmenter.dart';
import 'package:briluxforge/features/delegation/data/engine/worthiness_evaluator.dart';

SegmentCandidate _makeCandidate({
  required String text,
  required String category,
  required double confidence,
  double secondConfidence = 0.0,
  int tokens = 100,
}) =>
    SegmentCandidate(
      text: text,
      category: category,
      categoryConfidence: confidence,
      secondCategoryConfidence: secondConfidence,
      estimatedTokens: tokens,
    );

void main() {
  const evaluator = WorthinessEvaluator();

  group('WorthinessEvaluator', () {
    test('returns NOT_WORTHWHILE when total tokens below minimum', () {
      final candidates = [
        _makeCandidate(text: 'Research AI.', category: 'research', confidence: 0.8),
        _makeCandidate(text: 'Write about it.', category: 'writing', confidence: 0.8),
      ];
      // totalPromptTokens < kMinTotalPromptTokens (200)
      final verdict = evaluator.evaluate(candidates, 50);
      expect(verdict.segmentationWorthwhile, isFalse);
    });

    test('returns NOT_WORTHWHILE for empty candidate list', () {
      final verdict = evaluator.evaluate([], 500);
      expect(verdict.segmentationWorthwhile, isFalse);
    });

    test('merges segments below kMinSegmentTokens', () {
      final candidates = [
        _makeCandidate(
          text: 'Research AI.',
          category: 'research',
          confidence: 0.85,
          tokens: 10, // below kMinSegmentTokens (40) — will be merged
        ),
        _makeCandidate(
          text: 'Write a comprehensive article about machine learning trends.',
          category: 'writing',
          confidence: 0.80,
          tokens: 80,
        ),
      ];
      // After merging, only 1 segment → NOT_WORTHWHILE
      final verdict = evaluator.evaluate(candidates, 250);
      expect(verdict.segmentationWorthwhile, isFalse);
    });

    test('returns NOT_WORTHWHILE when segment confidence below minimum', () {
      final candidates = [
        _makeCandidate(
          text: 'Research AI trends.',
          category: 'research',
          confidence: 0.40, // below kMinSegmentConfidence (0.60)
          tokens: 60,
        ),
        _makeCandidate(
          text: 'Write a report.',
          category: 'writing',
          confidence: 0.40, // below kMinSegmentConfidence
          tokens: 60,
        ),
      ];
      final verdict = evaluator.evaluate(candidates, 250);
      expect(verdict.segmentationWorthwhile, isFalse);
    });

    test('returns NOT_WORTHWHILE when category gap below minimum', () {
      final candidates = [
        _makeCandidate(
          text: 'Research and write about AI.',
          category: 'research',
          confidence: 0.75,
          secondConfidence: 0.70, // gap = 0.05, below kMinCategoryGap (0.25)
          tokens: 80,
        ),
        _makeCandidate(
          text: 'Analyze and document the findings.',
          category: 'writing',
          confidence: 0.72,
          secondConfidence: 0.68, // gap = 0.04
          tokens: 80,
        ),
      ];
      final verdict = evaluator.evaluate(candidates, 250);
      expect(verdict.segmentationWorthwhile, isFalse);
    });

    test('returns NOT_WORTHWHILE when only one distinct category survives', () {
      final candidates = [
        _makeCandidate(text: 'Write an essay.', category: 'writing', confidence: 0.90, tokens: 80),
        _makeCandidate(text: 'Draft a blog post.', category: 'writing', confidence: 0.85, tokens: 80),
      ];
      // Both are 'writing' — only 1 distinct category
      final verdict = evaluator.evaluate(candidates, 250);
      expect(verdict.segmentationWorthwhile, isFalse);
    });

    test('caps plan at kMaxSegments (4)', () {
      final candidates = [
        _makeCandidate(text: 'Research AI.', category: 'research', confidence: 0.85, tokens: 60),
        _makeCandidate(text: 'Write an article.', category: 'writing', confidence: 0.80, tokens: 60),
        _makeCandidate(text: 'Implement code.', category: 'coding', confidence: 0.90, tokens: 60),
        _makeCandidate(text: 'Summarize findings.', category: 'summarization', confidence: 0.75, tokens: 60),
        _makeCandidate(text: 'Analyze results.', category: 'reasoning', confidence: 0.78, tokens: 60),
      ];
      final verdict = evaluator.evaluate(candidates, 400);
      if (verdict.segmentationWorthwhile) {
        expect(verdict.subTasks!.length, lessThanOrEqualTo(WorthinessEvaluator.kMaxSegments));
      }
    });

    test('returns WORTHWHILE for valid diverse input', () {
      final candidates = [
        _makeCandidate(
          text: 'Research the top JavaScript charting libraries.',
          category: 'research',
          confidence: 0.85,
          secondConfidence: 0.30,
          tokens: 80,
        ),
        _makeCandidate(
          text: 'Write a short comparison article.',
          category: 'writing',
          confidence: 0.80,
          secondConfidence: 0.20,
          tokens: 80,
        ),
      ];
      final verdict = evaluator.evaluate(candidates, 300);
      expect(verdict.segmentationWorthwhile, isTrue);
      expect(verdict.subTasks, isNotNull);
      expect(verdict.subTasks!.length, equals(2));
    });

    test('exactly one candidate after merge → NOT_WORTHWHILE', () {
      // Only one candidate that passes all thresholds.
      final candidates = [
        _makeCandidate(
          text: 'Research and explain artificial intelligence comprehensively.',
          category: 'research',
          confidence: 0.85,
          secondConfidence: 0.20,
        ),
      ];
      final verdict = evaluator.evaluate(candidates, 300);
      expect(verdict.segmentationWorthwhile, isFalse);
    });

    test('WORTHWHILE produces subTasks with ascending orderIndex', () {
      final candidates = [
        _makeCandidate(
          text: 'Research machine learning.',
          category: 'research',
          confidence: 0.85,
          secondConfidence: 0.20,
          tokens: 80,
        ),
        _makeCandidate(
          text: 'Write a tutorial.',
          category: 'writing',
          confidence: 0.80,
          secondConfidence: 0.15,
          tokens: 80,
        ),
      ];
      final verdict = evaluator.evaluate(candidates, 300);
      expect(verdict.segmentationWorthwhile, isTrue);
      final tasks = verdict.subTasks!;
      for (var i = 0; i < tasks.length; i++) {
        expect(tasks[i].orderIndex, equals(i));
      }
    });
  });
}

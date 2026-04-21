// lib/features/delegation/data/engine/worthiness_evaluator.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:briluxforge/features/delegation/data/engine/task_segmenter.dart';
import 'package:briluxforge/features/delegation/data/models/sub_task.dart';

// ── Verdict ───────────────────────────────────────────────────────────────────

@immutable
class WorthinessVerdict {
  const WorthinessVerdict({
    required this.segmentationWorthwhile,
    this.subTasks,
  });

  final bool segmentationWorthwhile;

  /// Non-null only when [segmentationWorthwhile] is true.
  final List<SubTask>? subTasks;

  static const WorthinessVerdict notWorthwhile =
      WorthinessVerdict(segmentationWorthwhile: false);
}

// ── Evaluator ─────────────────────────────────────────────────────────────────

/// Pure deterministic evaluator — given the same inputs it always returns the
/// same verdict, which makes it safe to test and to replay.
class WorthinessEvaluator {
  const WorthinessEvaluator();

  // Tune only with evidence. These constants are the spec-mandated values.
  static const int kMinTotalPromptTokens = 200;
  static const int kMinSegmentTokens = 40;
  static const double kMinSegmentConfidence = 0.60;
  static const double kMinCategoryGap = 0.25;
  static const int kMinDistinctCategories = 2;
  static const int kMaxSegments = 4;

  static const _uuid = Uuid();

  WorthinessVerdict evaluate(
    List<SegmentCandidate> candidates,
    int totalPromptTokens,
  ) {
    if (candidates.isEmpty) return WorthinessVerdict.notWorthwhile;

    // Gate 1: prompt too short for orchestration overhead to be worthwhile.
    if (totalPromptTokens < kMinTotalPromptTokens) {
      return WorthinessVerdict.notWorthwhile;
    }

    // Step 2: mark each candidate as a merge candidate if it fails thresholds.
    final surviving = <SegmentCandidate>[];
    SegmentCandidate? mergeBuffer;

    for (var i = 0; i < candidates.length; i++) {
      final c = candidates[i];
      final gap = c.categoryConfidence - c.secondCategoryConfidence;
      final isMerge = c.estimatedTokens < kMinSegmentTokens ||
          c.categoryConfidence < kMinSegmentConfidence ||
          gap < kMinCategoryGap;

      if (isMerge) {
        // Merge into buffer if possible; buffer merges right-preferred.
        mergeBuffer = mergeBuffer == null ? c : _merge(mergeBuffer, c);
      } else {
        if (mergeBuffer != null) {
          // Flush the buffer into the surviving candidate on the right.
          final merged = _merge(mergeBuffer, c);
          surviving.add(merged);
          mergeBuffer = null;
        } else {
          surviving.add(c);
        }
      }
    }

    // Flush any trailing merge buffer into the last survivor (left-preferred).
    if (mergeBuffer != null) {
      if (surviving.isNotEmpty) {
        final last = surviving.removeLast();
        surviving.add(_merge(last, mergeBuffer));
      } else {
        // All candidates were merge candidates — nothing survives.
        return WorthinessVerdict.notWorthwhile;
      }
    }

    // Gate 3: after merging, only one segment left — no routing diversity.
    if (surviving.length <= 1) return WorthinessVerdict.notWorthwhile;

    // Gate 4: check distinct categories.
    final distinctCategories =
        surviving.map((c) => c.category).toSet().length;
    if (distinctCategories < kMinDistinctCategories) {
      return WorthinessVerdict.notWorthwhile;
    }

    // Step 5: cap at kMaxSegments by merging lowest-confidence adjacent pairs.
    var capped = surviving;
    while (capped.length > kMaxSegments) {
      capped = _mergeWeakestAdjacentPair(capped);
    }

    // Re-check after capping: must still have ≥ 2 segments with diverse categories.
    if (capped.length <= 1) return WorthinessVerdict.notWorthwhile;
    final distinctAfterCap = capped.map((c) => c.category).toSet().length;
    if (distinctAfterCap < kMinDistinctCategories) {
      return WorthinessVerdict.notWorthwhile;
    }

    // Step 6: emit SubTask instances from survivors.
    final subTasks = capped.indexed.map((entry) {
      final (index, candidate) = entry;
      return SubTask.fromCandidate(
        candidate,
        id: _uuid.v4(),
        orderIndex: index,
      );
    }).toList();

    return WorthinessVerdict(
      segmentationWorthwhile: true,
      subTasks: subTasks,
    );
  }

  // ── Merge helpers ──────────────────────────────────────────────────────────

  SegmentCandidate _merge(SegmentCandidate a, SegmentCandidate b) {
    final combined = '${a.text} ${b.text}';
    // Winning category is whichever has the higher confidence.
    final aWins = a.categoryConfidence >= b.categoryConfidence;
    return SegmentCandidate(
      text: combined,
      category: aWins ? a.category : b.category,
      categoryConfidence:
          aWins ? a.categoryConfidence : b.categoryConfidence,
      secondCategoryConfidence: aWins
          ? a.secondCategoryConfidence
          : b.secondCategoryConfidence,
      estimatedTokens: a.estimatedTokens + b.estimatedTokens,
      discourseMarker: a.discourseMarker,
    );
  }

  List<SegmentCandidate> _mergeWeakestAdjacentPair(
    List<SegmentCandidate> list,
  ) {
    // Find the adjacent pair with the lowest combined confidence.
    var weakestIndex = 0;
    var weakestSum = double.infinity;

    for (var i = 0; i < list.length - 1; i++) {
      final sum = list[i].categoryConfidence + list[i + 1].categoryConfidence;
      if (sum < weakestSum) {
        weakestSum = sum;
        weakestIndex = i;
      }
    }

    final result = <SegmentCandidate>[...list];
    final merged = _merge(result[weakestIndex], result[weakestIndex + 1]);
    result
      ..removeAt(weakestIndex)
      ..removeAt(weakestIndex) // second element now at same index after first removal
      ..insert(weakestIndex, merged);
    return result;
  }
}

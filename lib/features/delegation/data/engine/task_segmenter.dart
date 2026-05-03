// lib/features/delegation/data/engine/task_segmenter.dart
import 'package:flutter/foundation.dart';

import 'package:briluxforge/features/delegation/data/engine/context_analyzer.dart';
import 'package:briluxforge/features/delegation/data/engine/keyword_matrix.dart';

// ── Segment candidate ─────────────────────────────────────────────────────────

@immutable
class SegmentCandidate {
  const SegmentCandidate({
    required this.text,
    required this.category,
    required this.categoryConfidence,
    required this.secondCategoryConfidence,
    required this.estimatedTokens,
    this.discourseMarker,
  });

  final String text;
  final String category;
  final double categoryConfidence;
  final double secondCategoryConfidence;
  final int estimatedTokens;

  /// The leading discourse marker that preceded this segment, if any.
  final String? discourseMarker;
}

// ── Abbreviation mask so sentence-splitting doesn't break on them ─────────────

const List<String> _kAbbreviations = [
  'e.g.',
  'i.e.',
  'Dr.',
  'Mr.',
  'Mrs.',
  'Ms.',
  'vs.',
  'etc.',
  'Inc.',
  'Ltd.',
  'No.',
  'St.',
  'Prof.',
  'Jr.',
  'Sr.',
];

// ── Discourse markers that signal task-chaining ───────────────────────────────

const List<String> _kDiscourseMarkers = [
  'then,',
  'after that,',
  'once you have',
  'using that,',
  'based on the research',
  'with the findings',
  'finally,',
  'taking those',
  'and then',
  'also,',
];

// ── TaskSegmenter ─────────────────────────────────────────────────────────────

/// Pure-Dart prompt segmenter. Runs synchronously in < 5 ms for prompts up to
/// 10 000 characters. Produces candidate segments — worthiness check is
/// downstream (WorthinessEvaluator).
class TaskSegmenter {
  const TaskSegmenter({
    this.contextAnalyzer = const ContextAnalyzer(),
  });

  final ContextAnalyzer contextAnalyzer;

  // Category verbs that signal imperative task seeds.
  static const List<String> _kImperativeVerbs = [
    'write',
    'research',
    'summarize',
    'explain',
    'analyze',
    'code',
    'implement',
    'debug',
    'calculate',
    'draft',
    'rewrite',
    'compare',
    'create',
    'build',
    'design',
    'review',
    'evaluate',
    'find',
    'list',
    'describe',
    'translate',
    'fix',
    'refactor',
    'generate',
    'solve',
  ];

  // Conjunctions to strip from the start of a sentence before verb detection.
  static const List<String> _kLeadingConjunctions = [
    'and ',
    'also ',
    'then ',
    'after ',
    'finally ',
    'additionally ',
    'furthermore ',
    'moreover ',
  ];

  /// Segments [prompt] into ordered [SegmentCandidate]s.
  List<SegmentCandidate> segment(String prompt) {
    if (prompt.trim().isEmpty) return const [];

    // Step 1: normalize whitespace within lines; preserve paragraph breaks.
    final normalized = _normalizeWhitespace(prompt);

    // Step 2: paragraph-split first.
    final paragraphs = normalized.split(RegExp(r'\n\n+'));

    final rawSegments = <String>[];
    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;
      // Step 3: sentence-split within each paragraph.
      rawSegments.addAll(_splitSentences(trimmed));
    }

    if (rawSegments.isEmpty) return const [];

    // Step 4 & 5: detect imperative verbs and discourse markers.
    final classified = <_RawSegment>[];
    for (final raw in rawSegments) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final discourseMarker = _detectDiscourseMarker(trimmed);
      final isImperative = _isImperativeSeed(trimmed);
      classified.add(_RawSegment(
        text: trimmed,
        discourseMarker: discourseMarker,
        isImperative: isImperative,
      ));
    }

    // Step 6: category-score each segment.
    final candidates = classified.map((r) {
      final scores = _scoreCategories(r.text.toLowerCase());
      final topEntry = scores.isEmpty
          ? const MapEntry('general', 0.0)
          : scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
      final sortedValues = scores.values.toList()..sort((a, b) => b.compareTo(a));
      final second = sortedValues.length > 1 ? sortedValues[1] : 0.0;
      return SegmentCandidate(
        text: r.text,
        category: topEntry.key,
        categoryConfidence: topEntry.value,
        secondCategoryConfidence: second,
        estimatedTokens: contextAnalyzer.estimateTokens(r.text),
        discourseMarker: r.discourseMarker,
      );
    }).toList();

    // Step 7: merge adjacent segments with the same top category.
    return _mergeAdjacentSameCategory(candidates);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  String _normalizeWhitespace(String text) {
    // Preserve \n\n paragraph breaks; collapse other whitespace within lines.
    final lines = text.split('\n');
    final normalized = lines.map((l) => l.replaceAll(RegExp(r'[ \t]+'), ' ').trim()).join('\n');
    return normalized;
  }

  List<String> _splitSentences(String paragraph) {
    // Mask abbreviations to prevent false splits.
    var masked = paragraph;
    final masks = <String, String>{};
    for (var i = 0; i < _kAbbreviations.length; i++) {
      final abbr = _kAbbreviations[i];
      final placeholder = '__ABBR${i}__';
      masks[placeholder] = abbr;
      masked = masked.replaceAll(abbr, placeholder);
    }

    // Split on '. ', '? ', or '! ' followed by capital letter, digit, or quote.
    // Dart doesn't support lookbehind, so we insert a marker then split on it.
    const splitMarker = '\x00';
    final splitPattern = RegExp(r'([.?!])\s+(?=[A-Z0-9])');
    final markedText = masked.replaceAllMapped(
      splitPattern,
      (m) => '${m[1]}$splitMarker',
    );
    var parts = markedText.split(splitMarker);

    // Restore abbreviations.
    parts = parts.map((p) {
      var restored = p;
      for (final entry in masks.entries) {
        restored = restored.replaceAll(entry.key, entry.value);
      }
      return restored.trim();
    }).where((p) => p.isNotEmpty).toList();

    // Further split on discourse markers.
    final result = <String>[];
    for (final part in parts) {
      result.addAll(_splitOnDiscourseMarkers(part));
    }

    return result;
  }

  List<String> _splitOnDiscourseMarkers(String sentence) {
    for (final marker in _kDiscourseMarkers) {
      // Look for the marker mid-sentence (preceded by space or period+space).
      final pattern = RegExp(
        r'(?<=\s|^)' + RegExp.escape(marker),
        caseSensitive: false,
      );
      final match = pattern.firstMatch(sentence);
      if (match != null && match.start > 2) {
        final before = sentence.substring(0, match.start).trim();
        final after = sentence.substring(match.start).trim();
        if (before.isNotEmpty && after.isNotEmpty) {
          return [before, after];
        }
      }
    }
    return [sentence];
  }

  String? _detectDiscourseMarker(String text) {
    final lower = text.toLowerCase();
    for (final marker in _kDiscourseMarkers) {
      if (lower.startsWith(marker)) return marker;
    }
    return null;
  }

  bool _isImperativeSeed(String text) {
    var lower = text.toLowerCase().trim();
    // Strip leading conjunctions.
    for (final conjunction in _kLeadingConjunctions) {
      if (lower.startsWith(conjunction)) {
        lower = lower.substring(conjunction.length).trim();
        break;
      }
    }
    final firstToken = lower.split(RegExp(r'\s+')).first;
    return _kImperativeVerbs.contains(firstToken);
  }

  Map<String, double> _scoreCategories(String lowerText) {
    final scores = <String, double>{};
    for (final entry in kKeywordMatrix.entries) {
      if (entry.value.isEmpty) continue;
      var sum = 0.0;
      for (final wk in entry.value) {
        if (lowerText.contains(wk.keyword.toLowerCase())) {
          sum += wk.weight;
        }
      }
      if (sum > 0) scores[entry.key.jsonKey] = sum;
    }
    return scores;
  }

  List<SegmentCandidate> _mergeAdjacentSameCategory(
    List<SegmentCandidate> candidates,
  ) {
    if (candidates.length <= 1) return candidates;

    final merged = <SegmentCandidate>[];
    var current = candidates.first;

    for (var i = 1; i < candidates.length; i++) {
      final next = candidates[i];
      if (next.category == current.category) {
        // Merge: combine text, keep higher confidence, sum tokens.
        final combinedText = '${current.text} ${next.text}';
        final combinedConfidence =
            current.categoryConfidence > next.categoryConfidence
                ? current.categoryConfidence
                : next.categoryConfidence;
        current = SegmentCandidate(
          text: combinedText,
          category: current.category,
          categoryConfidence: combinedConfidence,
          secondCategoryConfidence: current.secondCategoryConfidence > next.secondCategoryConfidence
              ? current.secondCategoryConfidence
              : next.secondCategoryConfidence,
          estimatedTokens: current.estimatedTokens + next.estimatedTokens,
          discourseMarker: current.discourseMarker,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    return merged;
  }
}

// ── Internal helper ───────────────────────────────────────────────────────────

@immutable
class _RawSegment {
  const _RawSegment({
    required this.text,
    required this.isImperative,
    this.discourseMarker,
  });

  final String text;
  final bool isImperative;
  final String? discourseMarker;
}

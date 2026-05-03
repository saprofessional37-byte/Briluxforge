// lib/features/delegation/data/engine/keyword_matrix.dart
import 'package:flutter/foundation.dart';

import 'package:briluxforge/features/delegation/data/engine/keyword_category.dart';

@immutable
class WeightedKeyword {
  const WeightedKeyword(this.keyword, this.weight);

  final String keyword;

  /// [0.4, 1.0] weight applied when this keyword appears in the prompt.
  /// 1.0 = unambiguous marker (sufficient alone).
  /// 0.4 = weak signal (only useful when stacked with others).
  final double weight;
}

/// Canonical 14-category weighted keyword matrix.
///
/// [long_context] and [general] are intentionally empty — they are triggered
/// by token count and score fallback respectively, not by keywords.
/// Every keyword-bearing category has ≥ 8 entries.
const Map<KeywordCategory, List<WeightedKeyword>> kKeywordMatrix = {
  // ── coding ──────────────────────────────────────────────────────────────
  KeywordCategory.coding: [
    WeightedKeyword('implement', 0.7),
    WeightedKeyword('function', 0.6),
    WeightedKeyword('class', 0.5),
    WeightedKeyword('code', 0.7),
    WeightedKeyword('refactor', 0.8),
    WeightedKeyword('api', 0.5),
    WeightedKeyword('algorithm', 0.7),
    WeightedKeyword('compile', 0.9),
    WeightedKeyword('python', 0.8),
    WeightedKeyword('javascript', 0.8),
    WeightedKeyword('typescript', 0.8),
    WeightedKeyword('dart', 0.8),
    WeightedKeyword('rust', 0.8),
    WeightedKeyword('kotlin', 0.8),
    WeightedKeyword('swift', 0.8),
    WeightedKeyword('java', 0.7),
    WeightedKeyword('flutter', 0.8),
    WeightedKeyword('react', 0.7),
    WeightedKeyword('regex', 0.6),
    WeightedKeyword('sql', 0.7),
    WeightedKeyword('async', 0.6),
    WeightedKeyword('await', 0.6),
    WeightedKeyword('stream', 0.5),
    WeightedKeyword('repository', 0.5),
    WeightedKeyword('dockerfile', 0.7),
    WeightedKeyword('unit test', 0.7),
    WeightedKeyword('write a', 0.4),
    WeightedKeyword('generate a', 0.4),
  ],

  // ── debugging ────────────────────────────────────────────────────────────
  KeywordCategory.debugging: [
    WeightedKeyword('debug', 0.9),
    WeightedKeyword('stack trace', 1.0),
    WeightedKeyword('stacktrace', 1.0),
    WeightedKeyword('error in', 0.8),
    WeightedKeyword('fix this', 0.8),
    WeightedKeyword('exception', 0.8),
    WeightedKeyword('null pointer', 0.9),
    WeightedKeyword('type error', 0.9),
    WeightedKeyword('compile error', 1.0),
    WeightedKeyword('runtime error', 0.9),
    WeightedKeyword('crashes', 0.7),
    WeightedKeyword('crash', 0.7),
    WeightedKeyword('not working', 0.6),
    WeightedKeyword("doesn't work", 0.6),
    WeightedKeyword('broken', 0.6),
    WeightedKeyword('failing', 0.7),
    WeightedKeyword('bug', 0.8),
    WeightedKeyword('undefined', 0.7),
    WeightedKeyword('unexpected behavior', 0.8),
    WeightedKeyword('issue with', 0.5),
  ],

  // ── math_reasoning ───────────────────────────────────────────────────────
  KeywordCategory.mathReasoning: [
    WeightedKeyword('calculate', 0.8),
    WeightedKeyword('equation', 0.9),
    WeightedKeyword('integral', 1.0),
    WeightedKeyword('derivative', 1.0),
    WeightedKeyword('matrix', 0.7),
    WeightedKeyword('probability', 0.8),
    WeightedKeyword('statistics', 0.7),
    WeightedKeyword('formula', 0.7),
    WeightedKeyword('theorem', 0.8),
    WeightedKeyword('proof', 0.8),
    WeightedKeyword('algebra', 0.8),
    WeightedKeyword('calculus', 0.9),
    WeightedKeyword('geometry', 0.8),
    WeightedKeyword('trigonometry', 0.9),
    WeightedKeyword('linear regression', 0.9),
    WeightedKeyword('variance', 0.7),
    WeightedKeyword('standard deviation', 0.8),
    WeightedKeyword('factorial', 0.9),
    WeightedKeyword('permutation', 0.8),
    WeightedKeyword('combination', 0.7),
    WeightedKeyword('solve for', 0.7),
    WeightedKeyword('vector', 0.7),
    WeightedKeyword('differentiate', 0.9),
  ],

  // ── analysis ─────────────────────────────────────────────────────────────
  KeywordCategory.analysis: [
    WeightedKeyword('compare', 0.7),
    WeightedKeyword('evaluate', 0.7),
    WeightedKeyword('tradeoff', 0.8),
    WeightedKeyword('trade-off', 0.8),
    WeightedKeyword('trade off', 0.8),
    WeightedKeyword('review', 0.6),
    WeightedKeyword('analyze', 0.7),
    WeightedKeyword('analyse', 0.7),
    WeightedKeyword('pros and cons', 0.8),
    WeightedKeyword('advantages', 0.6),
    WeightedKeyword('disadvantages', 0.6),
    WeightedKeyword('assess', 0.6),
    WeightedKeyword('critique', 0.7),
    WeightedKeyword('explain the difference', 0.8),
    WeightedKeyword('which is better', 0.8),
    WeightedKeyword('what are the implications', 0.7),
    WeightedKeyword('what would happen if', 0.6),
    WeightedKeyword('tradeoffs between', 0.9),
    WeightedKeyword('compare and contrast', 0.9),
    WeightedKeyword('examination', 0.5),
    WeightedKeyword('strengths and weaknesses', 0.8),
  ],

  // ── creative_writing ─────────────────────────────────────────────────────
  KeywordCategory.creativeWriting: [
    WeightedKeyword('story', 0.8),
    WeightedKeyword('poem', 1.0),
    WeightedKeyword('fiction', 0.8),
    WeightedKeyword('character', 0.6),
    WeightedKeyword('creative', 0.7),
    WeightedKeyword('narrative', 0.7),
    WeightedKeyword('plot', 0.7),
    WeightedKeyword('dialogue', 0.8),
    WeightedKeyword('write a story', 1.0),
    WeightedKeyword('short story', 0.9),
    WeightedKeyword('world building', 0.8),
    WeightedKeyword('fantasy', 0.7),
    WeightedKeyword('science fiction', 0.7),
    WeightedKeyword('lyric', 0.8),
    WeightedKeyword('haiku', 1.0),
    WeightedKeyword('sonnet', 1.0),
    WeightedKeyword('protagonist', 0.7),
    WeightedKeyword('setting', 0.4),
    WeightedKeyword('scene', 0.5),
    WeightedKeyword('metaphor', 0.6),
  ],

  // ── professional_writing ─────────────────────────────────────────────────
  KeywordCategory.professionalWriting: [
    WeightedKeyword('email', 0.7),
    WeightedKeyword('memo', 0.8),
    WeightedKeyword('blog post', 0.8),
    WeightedKeyword('blog', 0.6),
    WeightedKeyword('essay', 0.7),
    WeightedKeyword('article', 0.7),
    WeightedKeyword('draft', 0.6),
    WeightedKeyword('rewrite', 0.7),
    WeightedKeyword('copywriting', 0.9),
    WeightedKeyword('headline', 0.7),
    WeightedKeyword('caption', 0.6),
    WeightedKeyword('marketing', 0.6),
    WeightedKeyword('landing page', 0.8),
    WeightedKeyword('cover letter', 0.9),
    WeightedKeyword('resume', 0.8),
    WeightedKeyword('proposal', 0.7),
    WeightedKeyword('press release', 0.9),
    WeightedKeyword('newsletter', 0.8),
    WeightedKeyword('announcement', 0.6),
    WeightedKeyword('professional tone', 0.8),
    WeightedKeyword('formal', 0.5),
    WeightedKeyword('thank you note', 0.8),
  ],

  // ── summarization ────────────────────────────────────────────────────────
  KeywordCategory.summarization: [
    WeightedKeyword('summarize', 1.0),
    WeightedKeyword('tldr', 1.0),
    WeightedKeyword('tl;dr', 1.0),
    WeightedKeyword('key points', 0.9),
    WeightedKeyword('key takeaways', 0.9),
    WeightedKeyword('overview', 0.6),
    WeightedKeyword('digest', 0.7),
    WeightedKeyword('condense', 0.9),
    WeightedKeyword('brief summary', 0.9),
    WeightedKeyword('highlight', 0.6),
    WeightedKeyword('extract the main', 0.8),
    WeightedKeyword('main points', 0.8),
    WeightedKeyword('shorten', 0.7),
    WeightedKeyword('shorter version', 0.8),
    WeightedKeyword('in a nutshell', 0.8),
  ],

  // ── instruction_following ─────────────────────────────────────────────────
  KeywordCategory.instructionFollowing: [
    WeightedKeyword('follow these steps', 0.9),
    WeightedKeyword('step by step', 0.8),
    WeightedKeyword('exactly as', 0.8),
    WeightedKeyword('structured output', 0.9),
    WeightedKeyword('output format', 0.8),
    WeightedKeyword('format as', 0.7),
    WeightedKeyword('json format', 0.9),
    WeightedKeyword('output as json', 1.0),
    WeightedKeyword('follow the template', 0.9),
    WeightedKeyword('fill in the', 0.6),
    WeightedKeyword('complete each', 0.7),
    WeightedKeyword('for each item', 0.7),
    WeightedKeyword('follow instructions', 0.9),
    WeightedKeyword('do not deviate', 0.9),
    WeightedKeyword('strictly follow', 0.9),
    WeightedKeyword('multi-step', 0.7),
    WeightedKeyword('checklist', 0.7),
    WeightedKeyword('template', 0.6),
  ],

  // ── long_context ──────────────────────────────────────────────────────────
  // Empty: triggered by token count in the engine, not keywords.
  KeywordCategory.longContext: [],

  // ── low_latency ───────────────────────────────────────────────────────────
  KeywordCategory.lowLatency: [
    WeightedKeyword('quick', 0.6),
    WeightedKeyword('quickly', 0.6),
    WeightedKeyword('fast', 0.6),
    WeightedKeyword('right now', 0.7),
    WeightedKeyword('asap', 0.8),
    WeightedKeyword('hurry', 0.7),
    WeightedKeyword('immediately', 0.6),
    WeightedKeyword('instant', 0.6),
    WeightedKeyword('rapid', 0.6),
    WeightedKeyword('snappy', 0.5),
  ],

  // ── high_volume_cheap ─────────────────────────────────────────────────────
  KeywordCategory.highVolumeCheap: [
    WeightedKeyword('routine', 0.6),
    WeightedKeyword('batch', 0.7),
    WeightedKeyword('bulk', 0.7),
    WeightedKeyword('low stakes', 0.8),
    WeightedKeyword('simple task', 0.7),
    WeightedKeyword('basic', 0.4),
    WeightedKeyword('straightforward', 0.5),
    WeightedKeyword('quick check', 0.7),
    WeightedKeyword('cheap', 0.6),
    WeightedKeyword('trivial', 0.7),
  ],

  // ── multilingual ──────────────────────────────────────────────────────────
  KeywordCategory.multilingual: [
    WeightedKeyword('translate', 0.9),
    WeightedKeyword('translation', 0.9),
    WeightedKeyword('en español', 1.0),
    WeightedKeyword('in french', 0.9),
    WeightedKeyword('in german', 0.9),
    WeightedKeyword('in japanese', 0.9),
    WeightedKeyword('in arabic', 0.9),
    WeightedKeyword('in chinese', 0.9),
    WeightedKeyword('in portuguese', 0.9),
    WeightedKeyword('multilingual', 0.9),
    WeightedKeyword('localize', 0.8),
    WeightedKeyword('localization', 0.8),
    WeightedKeyword('language:', 0.7),
    WeightedKeyword('into english', 0.9),
    WeightedKeyword('from spanish', 0.9),
    WeightedKeyword('from french', 0.9),
  ],

  // ── safety_critical ───────────────────────────────────────────────────────
  KeywordCategory.safetyCritical: [
    WeightedKeyword('medical advice', 1.0),
    WeightedKeyword('legal advice', 1.0),
    WeightedKeyword('financial advice', 1.0),
    WeightedKeyword('is this legal', 0.9),
    WeightedKeyword('is this safe', 0.8),
    WeightedKeyword('should i take', 0.8),
    WeightedKeyword('prescription', 0.8),
    WeightedKeyword('diagnosis', 0.9),
    WeightedKeyword('symptoms', 0.7),
    WeightedKeyword('contract clause', 0.9),
    WeightedKeyword('enforceable', 0.9),
    WeightedKeyword('sue', 0.8),
    WeightedKeyword('invest in', 0.7),
    WeightedKeyword('portfolio', 0.6),
    WeightedKeyword('retirement', 0.6),
    WeightedKeyword('emergency', 0.7),
    WeightedKeyword('drug interaction', 1.0),
    WeightedKeyword('side effects', 0.7),
  ],

  // ── general ───────────────────────────────────────────────────────────────
  // Empty: activates as fallback when nothing else hits threshold.
  KeywordCategory.general: [],
};

/// Computes the maximum achievable score for [category] — the sum of all
/// weights in its keyword list. Used for normalisation in the engine.
double maxScoreFor(KeywordCategory category) {
  final keywords = kKeywordMatrix[category] ?? [];
  if (keywords.isEmpty) return 0;
  return keywords.fold(0.0, (sum, wk) => sum + wk.weight);
}

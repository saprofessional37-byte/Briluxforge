// tools/brain_editor/lib/brain_validator.dart
// Canonical brain schema validator.
// Used by the CLI before signing and by the runtime loader.
import 'dart:convert';

/// Result of [BrainValidator.validate].
class BrainValidationReport {
  const BrainValidationReport._ok() : errors = const [];
  const BrainValidationReport._errors(this.errors);

  factory BrainValidationReport.ok() => const BrainValidationReport._ok();
  factory BrainValidationReport.errors(List<String> reasons) =>
      BrainValidationReport._errors(List.unmodifiable(reasons));

  final List<String> errors;
  bool get isValid => errors.isEmpty;

  @override
  String toString() =>
      isValid ? 'OK' : 'INVALID:\n${errors.map((e) => '  - $e').join('\n')}';
}

/// Canonical set of routable category names (from KeywordCategory enum).
const Set<String> _kCanonicalCategories = {
  'coding',
  'debugging',
  'math_reasoning',
  'analysis',
  'creative_writing',
  'professional_writing',
  'summarization',
  'instruction_following',
  'long_context',
  'low_latency',
  'high_volume_cheap',
  'multilingual',
  'safety_critical',
  'general',
};

const Set<String> _kValidTiers = {'workhorse', 'premium', 'specialist'};

class BrainValidator {
  const BrainValidator();

  /// Validates [jsonText] against the canonical brain schema v2.
  ///
  /// Returns [BrainValidationReport.ok()] on success.
  /// Returns [BrainValidationReport.errors(...)] with a list of problems.
  BrainValidationReport validate(String jsonText) {
    final errors = <String>[];

    late Map<String, dynamic> raw;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        return BrainValidationReport.errors(['Root must be a JSON object.']);
      }
      raw = decoded;
    } catch (e) {
      return BrainValidationReport.errors(['JSON parse error: $e']);
    }

    // ── Top-level required fields ─────────────────────────────────────────
    final schemaVersion = raw['schemaVersion'];
    if (schemaVersion is! int) {
      errors.add('Missing or non-integer "schemaVersion".');
    } else if (schemaVersion != 2) {
      errors.add('"schemaVersion" must be 2, got $schemaVersion.');
    }

    final version = raw['version'];
    if (version == null) {
      errors.add('Missing "version" field.');
    }

    final modelsList = raw['models'];
    if (modelsList is! List) {
      errors.add('"models" must be a JSON array.');
      return BrainValidationReport.errors(errors);
    }

    // ── Per-model validation ──────────────────────────────────────────────
    final seenIds = <String>{};
    final seenDisplayNamesByProvider = <String, Set<String>>{};
    int benchmarkCount = 0;

    for (var i = 0; i < modelsList.length; i++) {
      final entry = modelsList[i];
      if (entry is! Map<String, dynamic>) {
        errors.add('models[$i]: must be a JSON object.');
        continue;
      }

      final prefix = 'models[$i] (${entry['id'] ?? '?'})';

      // Required string fields.
      for (final field in ['id', 'provider', 'displayName', 'tier', 'descriptionForAdmin']) {
        if (entry[field] is! String || (entry[field] as String).isEmpty) {
          errors.add('$prefix: missing or empty string "$field".');
        }
      }

      // Required numeric fields.
      final contextWindow = entry['contextWindow'];
      if (contextWindow is! int || contextWindow <= 0) {
        errors.add('$prefix: "contextWindow" must be a positive int.');
      }

      final costIn = entry['costPer1kInput'];
      if (costIn is! num || costIn < 0) {
        errors.add('$prefix: "costPer1kInput" must be >= 0.');
      }

      final costOut = entry['costPer1kOutput'];
      if (costOut is! num || costOut < 0) {
        errors.add('$prefix: "costPer1kOutput" must be >= 0.');
      }

      final latency = entry['latencyHintMs'];
      if (latency is! int || latency < 0) {
        errors.add('$prefix: "latencyHintMs" must be a non-negative int.');
      }

      // Strengths: every entry must be a canonical category.
      final strengths = entry['strengths'];
      if (strengths is! List) {
        errors.add('$prefix: "strengths" must be a JSON array.');
      } else {
        for (final s in strengths) {
          if (s is! String || !_kCanonicalCategories.contains(s)) {
            errors.add(
                '$prefix: unknown strength "$s". '
                'Must be one of: ${_kCanonicalCategories.join(', ')}.');
          }
        }
      }

      // Tier.
      final tier = entry['tier'];
      if (tier is! String || !_kValidTiers.contains(tier)) {
        errors.add('$prefix: "tier" must be one of: ${_kValidTiers.join(', ')}.');
      }

      // Uniqueness checks.
      final id = entry['id'] as String?;
      if (id != null) {
        if (!seenIds.add(id)) {
          errors.add('$prefix: duplicate id "$id".');
        }
      }

      final provider = entry['provider'] as String?;
      final displayName = entry['displayName'] as String?;
      if (provider != null && displayName != null) {
        final names = seenDisplayNamesByProvider.putIfAbsent(provider, () => {});
        if (!names.add(displayName)) {
          errors.add('$prefix: duplicate displayName "$displayName" for provider "$provider".');
        }
      }

      // Benchmark count.
      if (entry['isBenchmark'] == true) benchmarkCount++;
    }

    if (benchmarkCount > 1) {
      errors.add('At most one model may have "isBenchmark": true, found $benchmarkCount.');
    }

    return errors.isEmpty
        ? BrainValidationReport.ok()
        : BrainValidationReport.errors(errors);
  }
}

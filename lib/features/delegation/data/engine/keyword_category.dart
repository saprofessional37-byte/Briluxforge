// lib/features/delegation/data/engine/keyword_category.dart

/// Canonical 14-category taxonomy for delegation routing.
///
/// Every entry in [kKeywordMatrix] uses these values as keys.
/// Every model_profiles.json `strengths` array must contain only
/// the [name] of members from this enum (validated by BrainValidator).
enum KeywordCategory {
  coding,
  debugging,
  mathReasoning,
  analysis,
  creativeWriting,
  professionalWriting,
  summarization,
  instructionFollowing,
  longContext,
  lowLatency,
  highVolumeCheap,
  multilingual,
  safetyCritical,
  general;

  /// JSON / model_profiles.json representation.
  String get jsonKey => switch (this) {
        coding => 'coding',
        debugging => 'debugging',
        mathReasoning => 'math_reasoning',
        analysis => 'analysis',
        creativeWriting => 'creative_writing',
        professionalWriting => 'professional_writing',
        summarization => 'summarization',
        instructionFollowing => 'instruction_following',
        longContext => 'long_context',
        lowLatency => 'low_latency',
        highVolumeCheap => 'high_volume_cheap',
        multilingual => 'multilingual',
        safetyCritical => 'safety_critical',
        general => 'general',
      };

  static KeywordCategory? fromJsonKey(String key) => switch (key) {
        'coding' => coding,
        'debugging' => debugging,
        'math_reasoning' => mathReasoning,
        'analysis' => analysis,
        'creative_writing' => creativeWriting,
        'professional_writing' => professionalWriting,
        'summarization' => summarization,
        'instruction_following' => instructionFollowing,
        'long_context' => longContext,
        'low_latency' => lowLatency,
        'high_volume_cheap' => highVolumeCheap,
        'multilingual' => multilingual,
        'safety_critical' => safetyCritical,
        'general' => general,
        _ => null,
      };

  /// Categories where premium-tier models win tiebreaks.
  static const Set<KeywordCategory> premiumPreferred = {
    safetyCritical,
    analysis,
    instructionFollowing,
    creativeWriting,
    professionalWriting,
  };

  /// Categories where workhorse-tier models win tiebreaks.
  static const Set<KeywordCategory> workhousePreferred = {
    coding,
    debugging,
    summarization,
    mathReasoning,
    general,
    highVolumeCheap,
  };
}

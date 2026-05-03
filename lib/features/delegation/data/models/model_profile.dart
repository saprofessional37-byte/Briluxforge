// lib/features/delegation/data/models/model_profile.dart
import 'package:flutter/foundation.dart';

@immutable
class ModelProfile {
  const ModelProfile({
    required this.id,
    required this.provider,
    required this.displayName,
    required this.strengths,
    required this.contextWindow,
    required this.costPer1kInput,
    required this.costPer1kOutput,
    required this.tier,
    required this.latencyHintMs,
    required this.descriptionForAdmin,
    this.isBenchmark = false,
  });

  factory ModelProfile.fromJson(Map<String, Object?> json) => ModelProfile(
        id: json['id'] as String,
        provider: json['provider'] as String,
        displayName: json['displayName'] as String,
        strengths: (json['strengths'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        contextWindow: json['contextWindow'] as int,
        costPer1kInput: (json['costPer1kInput'] as num).toDouble(),
        costPer1kOutput: (json['costPer1kOutput'] as num).toDouble(),
        tier: json['tier'] as String,
        latencyHintMs: json['latencyHintMs'] as int? ?? 999,
        descriptionForAdmin: json['descriptionForAdmin'] as String? ?? '',
        isBenchmark: json['isBenchmark'] as bool? ?? false,
      );

  final String id;
  final String provider;
  final String displayName;
  final List<String> strengths;
  final int contextWindow;
  final double costPer1kInput;
  final double costPer1kOutput;
  final String tier;

  /// Approximate median response latency in milliseconds (informational).
  final int latencyHintMs;

  /// One-sentence rationale for why this model is in the brain.
  final String descriptionForAdmin;

  final bool isBenchmark;

  bool get isWorkhorse => tier == 'workhorse';
  bool get isPremium => tier == 'premium';
  bool get isSpecialist => tier == 'specialist';

  double get totalCostPer1k => costPer1kInput + costPer1kOutput;
}

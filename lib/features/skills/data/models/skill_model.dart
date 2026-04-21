// lib/features/skills/data/models/skill_model.dart

import 'package:flutter/foundation.dart';

@immutable
class SkillModel {
  const SkillModel({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.isEnabled,
    required this.isBuiltIn,
    required this.createdAt,
    required this.updatedAt,
    this.pinnedProviders,
  });

  /// UUID
  final String id;

  /// Display name, e.g. "Senior Flutter Developer"
  final String name;

  /// One-line summary shown on the skill card
  final String description;

  /// The actual instruction text injected into API calls as a system prompt
  final String systemPrompt;

  /// Whether this skill is globally active
  final bool isEnabled;

  /// true = shipped with the app and cannot be deleted
  final bool isBuiltIn;

  /// null = applies to all providers; non-null = restrict to listed provider IDs
  final List<String>? pinnedProviders;

  final DateTime createdAt;
  final DateTime updatedAt;

  SkillModel copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    bool? isEnabled,
    bool? isBuiltIn,
    List<String>? pinnedProviders,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearPinnedProviders = false,
  }) =>
      SkillModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        isEnabled: isEnabled ?? this.isEnabled,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        pinnedProviders:
            clearPinnedProviders ? null : (pinnedProviders ?? this.pinnedProviders),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

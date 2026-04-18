// lib/services/skill_injection_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/features/skills/data/models/skill_model.dart';

part 'skill_injection_service.g.dart';

/// Builds the combined system prompt from all active, applicable skills.
/// Stateless — safe to call from any context.
class SkillInjectionService {
  const SkillInjectionService();

  /// Collects all [enabledSkills] that apply to [selectedProvider] and
  /// concatenates their [SkillModel.systemPrompt] fields into a single
  /// system prompt string, separated by horizontal rules.
  ///
  /// Returns an empty string when no applicable skills are active.
  String buildSystemPrompt({
    required List<SkillModel> enabledSkills,
    required String selectedProvider,
  }) {
    final applicable = enabledSkills.where((skill) {
      final pins = skill.pinnedProviders;
      if (pins == null) return true;
      return pins.contains(selectedProvider);
    }).toList();

    if (applicable.isEmpty) return '';

    return applicable
        .map((s) => '## Skill: ${s.name}\n${s.systemPrompt}')
        .join('\n\n---\n\n');
  }
}

@riverpod
SkillInjectionService skillInjectionService(Ref ref) {
  return const SkillInjectionService();
}

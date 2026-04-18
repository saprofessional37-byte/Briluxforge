// lib/features/skills/providers/skills_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:briluxforge/features/skills/data/models/skill_model.dart';
import 'package:briluxforge/features/skills/data/repositories/skills_repository.dart';

part 'skills_provider.g.dart';

const _uuid = Uuid();

// ── Built-in skill seed data (Section 5.5) ───────────────────────────────────

const _builtInSeed = [
  (
    id: 'builtin_concise_responder',
    name: 'Concise Responder',
    description: 'Short, direct answers — no filler or unnecessary caveats.',
    systemPrompt:
        'Keep responses brief and direct. No filler, no caveats, no disclaimers unless safety-critical.',
  ),
  (
    id: 'builtin_code_expert',
    name: 'Code Expert',
    description: 'Production-ready code with error handling — no pseudocode.',
    systemPrompt:
        'You are a senior software engineer. Always provide complete, production-ready code. Include error handling. No pseudocode.',
  ),
  (
    id: 'builtin_research_assistant',
    name: 'Research Assistant',
    description:
        'Thorough, well-sourced answers that distinguish facts from speculation.',
    systemPrompt:
        'Provide thorough, well-sourced answers. Cite specific data when available. Distinguish between facts and speculation.',
  ),
  (
    id: 'builtin_creative_writer',
    name: 'Creative Writer',
    description: 'Vivid, engaging prose with varied sentence structure.',
    systemPrompt:
        "Write with vivid, engaging prose. Use varied sentence structure. Show, don't tell.",
  ),
  (
    id: 'builtin_eli5_explainer',
    name: 'ELI5 Explainer',
    description: "Explains anything like you're talking to a curious 10-year-old.",
    systemPrompt:
        'Explain concepts as if talking to a curious 10-year-old. Use analogies and simple language.',
  ),
];

// ── All skills stream ─────────────────────────────────────────────────────────

@riverpod
Stream<List<SkillModel>> allSkills(Ref ref) {
  return ref.watch(skillsRepositoryProvider).watchAllSkills();
}

// ── Enabled skills (synchronous derived list) ─────────────────────────────────

@riverpod
List<SkillModel> enabledSkills(Ref ref) {
  return ref.watch(allSkillsProvider).valueOrNull
          ?.where((s) => s.isEnabled)
          .toList() ??
      const [];
}

// ── Skills notifier ──────────────────────────────────────────────────────────

@immutable
class SkillsState {
  const SkillsState({this.isSeeding = false, this.error});

  final bool isSeeding;
  final String? error;

  SkillsState copyWith({bool? isSeeding, String? error, bool clearError = false}) =>
      SkillsState(
        isSeeding: isSeeding ?? this.isSeeding,
        error: clearError ? null : (error ?? this.error),
      );
}

@Riverpod(keepAlive: true)
class SkillsNotifier extends _$SkillsNotifier {
  @override
  SkillsState build() {
    _seedIfFirstRun();
    return const SkillsState();
  }

  Future<void> _seedIfFirstRun() async {
    final repo = ref.read(skillsRepositoryProvider);
    if (await repo.hasAnyBuiltIn()) return;

    state = state.copyWith(isSeeding: true);
    final now = DateTime.now();
    for (final data in _builtInSeed) {
      await repo.insertSkill(SkillModel(
        id: data.id,
        name: data.name,
        description: data.description,
        systemPrompt: data.systemPrompt,
        isEnabled: true,
        isBuiltIn: true,
        createdAt: now,
        updatedAt: now,
      ));
    }
    state = state.copyWith(isSeeding: false);
  }

  Future<void> toggle(String id, {required bool enabled}) async {
    await ref.read(skillsRepositoryProvider).toggleSkill(id, enabled: enabled);
  }

  Future<void> createSkill({
    required String name,
    required String description,
    required String systemPrompt,
    List<String>? pinnedProviders,
  }) async {
    final now = DateTime.now();
    await ref.read(skillsRepositoryProvider).insertSkill(SkillModel(
          id: _uuid.v4(),
          name: name,
          description: description,
          systemPrompt: systemPrompt,
          isEnabled: true,
          isBuiltIn: false,
          pinnedProviders: pinnedProviders,
          createdAt: now,
          updatedAt: now,
        ));
  }

  Future<void> updateSkill(SkillModel updated) async {
    await ref
        .read(skillsRepositoryProvider)
        .updateSkill(updated.copyWith(updatedAt: DateTime.now()));
  }

  Future<void> deleteSkill(String id) async {
    await ref.read(skillsRepositoryProvider).deleteSkill(id);
  }
}

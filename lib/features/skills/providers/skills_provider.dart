// lib/features/skills/providers/skills_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:briluxforge/features/skills/data/models/skill_model.dart';
import 'package:briluxforge/features/skills/data/repositories/skills_repository.dart';

part 'skills_provider.g.dart';

const _uuid = Uuid();

// ── All skills stream ─────────────────────────────────────────────────────────

@riverpod
Stream<List<SkillModel>> allSkills(Ref ref) {
  return ref.watch(skillsRepositoryProvider).watchAllSkills();
}

// ── Enabled skills (synchronous derived list) ─────────────────────────────────

@riverpod
List<SkillModel> enabledSkills(Ref ref) {
  return ref
          .watch(allSkillsProvider)
          .valueOrNull
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

  SkillsState copyWith({
    bool? isSeeding,
    String? error,
    bool clearError = false,
  }) => SkillsState(
    isSeeding: isSeeding ?? this.isSeeding,
    error: clearError ? null : (error ?? this.error),
  );
}

@Riverpod(keepAlive: true)
class SkillsNotifier extends _$SkillsNotifier {
  @override
  SkillsState build() {
    // Idempotent per-ID seed on every launch. Fire-and-forget — the Drift
    // stream in allSkillsProvider will update the UI once rows are written.
    Future.microtask(_ensureBuiltIns);
    return const SkillsState();
  }

  Future<void> _ensureBuiltIns() async {
    state = state.copyWith(isSeeding: true);
    await ref.read(skillsRepositoryProvider).ensureBuiltInsPresent();
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
    await ref
        .read(skillsRepositoryProvider)
        .insertSkill(
          SkillModel(
            id: _uuid.v4(),
            name: name,
            description: description,
            systemPrompt: systemPrompt,
            isEnabled: true,
            isBuiltIn: false,
            pinnedProviders: pinnedProviders,
            createdAt: now,
            updatedAt: now,
          ),
        );
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

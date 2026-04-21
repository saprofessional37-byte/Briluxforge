// lib/features/skills/data/repositories/skills_repository.dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/core/database/app_database.dart';
import 'package:briluxforge/core/database/database_provider.dart';
import 'package:briluxforge/features/skills/data/models/skill_model.dart';

part 'skills_repository.g.dart';

// ── Built-in skill seed definitions ──────────────────────────────────────────
//
// IDs are stable, deterministic strings — NOT UUIDs — so that re-seeding on
// every launch is idempotent. Adding a new built-in here is safe; existing
// rows are never overwritten, which preserves any user customisation.

class _BuiltInSkillSeed {
  const _BuiltInSkillSeed({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
  });

  final String id;
  final String name;
  final String description;
  final String systemPrompt;
}

const List<_BuiltInSkillSeed> _kBuiltInSeeds = [
  _BuiltInSkillSeed(
    id: 'builtin_concise_responder',
    name: 'Concise Responder',
    description: 'Short, direct answers — no filler or unnecessary caveats.',
    systemPrompt:
        'Keep responses brief and direct. No filler, no caveats, no disclaimers unless safety-critical.',
  ),
  _BuiltInSkillSeed(
    id: 'builtin_code_expert',
    name: 'Code Expert',
    description: 'Production-ready code with error handling — no pseudocode.',
    systemPrompt:
        'You are a senior software engineer. Always provide complete, production-ready code. Include error handling. No pseudocode.',
  ),
  _BuiltInSkillSeed(
    id: 'builtin_research_assistant',
    name: 'Research Assistant',
    description:
        'Thorough, well-sourced answers that distinguish facts from speculation.',
    systemPrompt:
        'Provide thorough, well-sourced answers. Cite specific data when available. Distinguish between facts and speculation.',
  ),
  _BuiltInSkillSeed(
    id: 'builtin_creative_writer',
    name: 'Creative Writer',
    description: 'Vivid, engaging prose with varied sentence structure.',
    systemPrompt:
        "Write with vivid, engaging prose. Use varied sentence structure. Show, don't tell.",
  ),
  _BuiltInSkillSeed(
    id: 'builtin_eli5_explainer',
    name: 'ELI5 Explainer',
    description:
        "Explains anything like you're talking to a curious 10-year-old.",
    systemPrompt:
        'Explain concepts as if talking to a curious 10-year-old. Use analogies and simple language.',
  ),
];

// ── Repository ────────────────────────────────────────────────────────────────

class SkillsRepository {
  const SkillsRepository(this._db);

  final AppDatabase _db;

  /// Ensures every built-in skill seed is present in the database.
  ///
  /// Checks each of the five built-in skills by its fixed deterministic ID and
  /// inserts only the ones that are missing. Existing rows are left untouched
  /// so that any user customisation of built-in prompts is preserved.
  ///
  /// Safe to call on every app launch — the check is O(5 point-queries) and
  /// terminates in milliseconds even on a cold SQLite file.
  Future<void> ensureBuiltInsPresent() async {
    final now = DateTime.now();
    for (final seed in _kBuiltInSeeds) {
      final existing = await (_db.select(_db.skills)
            ..where((t) => t.id.equals(seed.id)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.skills).insert(
              SkillsCompanion(
                id: Value(seed.id),
                name: Value(seed.name),
                description: Value(seed.description),
                systemPrompt: Value(seed.systemPrompt),
                isEnabled: const Value(true),
                isBuiltIn: const Value(true),
                pinnedProvidersJson: const Value(null),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    }
  }

  Stream<List<SkillModel>> watchAllSkills() {
    return (_db.select(_db.skills)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isBuiltIn, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  Future<List<SkillModel>> getEnabledSkills() async {
    final rows = await (_db.select(_db.skills)
          ..where((t) => t.isEnabled.equals(true)))
        .get();
    return rows.map(_toModel).toList();
  }

  Future<void> insertSkill(SkillModel skill) async {
    await _db.into(_db.skills).insert(_toCompanion(skill));
  }

  Future<void> updateSkill(SkillModel skill) async {
    await (_db.update(_db.skills)
          ..where((t) => t.id.equals(skill.id)))
        .write(_toCompanion(skill));
  }

  Future<void> toggleSkill(String id, {required bool enabled}) async {
    await (_db.update(_db.skills)..where((t) => t.id.equals(id))).write(
      SkillsCompanion(
        isEnabled: Value(enabled),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSkill(String id) async {
    await (_db.delete(_db.skills)..where((t) => t.id.equals(id))).go();
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  SkillModel _toModel(Skill row) => SkillModel(
        id: row.id,
        name: row.name,
        description: row.description,
        systemPrompt: row.systemPrompt,
        isEnabled: row.isEnabled,
        isBuiltIn: row.isBuiltIn,
        pinnedProviders: row.pinnedProvidersJson != null
            ? (jsonDecode(row.pinnedProvidersJson!) as List<dynamic>)
                .cast<String>()
            : null,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  SkillsCompanion _toCompanion(SkillModel m) => SkillsCompanion(
        id: Value(m.id),
        name: Value(m.name),
        description: Value(m.description),
        systemPrompt: Value(m.systemPrompt),
        isEnabled: Value(m.isEnabled),
        isBuiltIn: Value(m.isBuiltIn),
        pinnedProvidersJson: Value(
          m.pinnedProviders != null ? jsonEncode(m.pinnedProviders) : null,
        ),
        createdAt: Value(m.createdAt),
        updatedAt: Value(m.updatedAt),
      );
}

@riverpod
SkillsRepository skillsRepository(Ref ref) {
  return SkillsRepository(ref.watch(appDatabaseProvider));
}

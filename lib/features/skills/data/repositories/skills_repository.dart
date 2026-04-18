// lib/features/skills/data/repositories/skills_repository.dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/core/database/app_database.dart';
import 'package:briluxforge/core/database/database_provider.dart';
import 'package:briluxforge/features/skills/data/models/skill_model.dart';

part 'skills_repository.g.dart';

class SkillsRepository {
  const SkillsRepository(this._db);

  final AppDatabase _db;

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

  Future<bool> hasAnyBuiltIn() async {
    final row = await (_db.select(_db.skills)
          ..where((t) => t.isBuiltIn.equals(true))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
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

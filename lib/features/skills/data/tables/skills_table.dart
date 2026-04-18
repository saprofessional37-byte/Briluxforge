// lib/features/skills/data/tables/skills_table.dart
import 'package:drift/drift.dart';

class Skills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get systemPrompt => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  /// JSON-encoded list of provider IDs, or null = applies to all providers.
  TextColumn get pinnedProvidersJson => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

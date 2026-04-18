// lib/core/database/app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:briluxforge/features/chat/data/tables/conversations_table.dart';
import 'package:briluxforge/features/chat/data/tables/messages_table.dart';
import 'package:briluxforge/features/skills/data/tables/skills_table.dart';

export 'package:briluxforge/features/chat/data/tables/conversations_table.dart';
export 'package:briluxforge/features/chat/data/tables/messages_table.dart';
export 'package:briluxforge/features/skills/data/tables/skills_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Conversations, Messages, Skills])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(conversations);
            await m.createTable(messages);
          }
          if (from < 3) {
            await m.createTable(skills);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'briluxforge.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// lib/features/chat/data/tables/messages_table.dart
import 'package:drift/drift.dart';
import 'package:briluxforge/features/chat/data/tables/conversations_table.dart';

class Messages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId =>
      text().references(Conversations, #id)();
  TextColumn get role => text()(); // 'user' | 'assistant'
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get tokenCount =>
      integer().withDefault(const Constant(0))();
  TextColumn get delegationJson => text().nullable()();
  TextColumn get provider => text().nullable()();
  TextColumn get modelId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

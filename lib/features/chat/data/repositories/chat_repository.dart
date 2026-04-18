// lib/features/chat/data/repositories/chat_repository.dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/core/database/app_database.dart';
import 'package:briluxforge/core/database/database_provider.dart';
import 'package:briluxforge/features/chat/data/models/conversation_model.dart';
import 'package:briluxforge/features/chat/data/models/message_model.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';

part 'chat_repository.g.dart';

class ChatRepository {
  const ChatRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  // ── Conversations ──────────────────────────────────────────────────────────

  Stream<List<ConversationModel>> watchAllConversations() =>
      (_db.select(_db.conversations)
            ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
          .watch()
          .map((rows) => rows.map(_toConversation).toList());

  Future<ConversationModel?> getConversation(String id) async {
    final row = await (_db.select(_db.conversations)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toConversation(row);
  }

  Future<ConversationModel> createConversation(ConversationModel c) async {
    await _db.into(_db.conversations).insert(
          ConversationsCompanion.insert(
            id: c.id,
            title: c.title,
            createdAt: c.createdAt,
            updatedAt: c.updatedAt,
          ),
        );
    return c;
  }

  Future<void> updateConversation(String id, {String? title}) async {
    await (_db.update(_db.conversations)..where((c) => c.id.equals(id))).write(
      ConversationsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteConversation(String id) async {
    // Delete messages first to respect the foreign key.
    await (_db.delete(_db.messages)
          ..where((m) => m.conversationId.equals(id)))
        .go();
    await (_db.delete(_db.conversations)..where((c) => c.id.equals(id))).go();
  }

  Future<List<ConversationModel>> searchConversations(String query) async {
    if (query.isEmpty) return const [];
    final lower = query.toLowerCase();
    final rows = await (_db.select(_db.conversations)
          ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
        .get();
    return rows
        .where((r) => r.title.toLowerCase().contains(lower))
        .map(_toConversation)
        .toList();
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> watchMessages(String conversationId) =>
      (_db.select(_db.messages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .watch()
          .map((rows) => rows.map(_toMessage).toList());

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final rows = await (_db.select(_db.messages)
          ..where((m) => m.conversationId.equals(conversationId))
          ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
        .get();
    return rows.map(_toMessage).toList();
  }

  Future<void> addMessage(MessageModel message) async {
    await _db
        .into(_db.messages)
        .insertOnConflictUpdate(_toCompanion(message));
  }

  Future<void> updateMessage(MessageModel message) async {
    await (_db.update(_db.messages)
          ..where((m) => m.id.equals(message.id)))
        .write(_toCompanion(message));
  }

  // ── Mapping helpers ────────────────────────────────────────────────────────

  ConversationModel _toConversation(Conversation row) => ConversationModel(
        id: row.id,
        title: row.title,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  MessageModel _toMessage(Message row) {
    DelegationResult? delegation;
    if (row.delegationJson != null) {
      try {
        final json = jsonDecode(row.delegationJson!) as Map<String, Object?>;
        delegation = DelegationResult(
          selectedModelId: json['selectedModelId'] as String,
          selectedProvider: json['selectedProvider'] as String,
          layerUsed: json['layerUsed'] as int,
          confidence: (json['confidence'] as num).toDouble(),
          reasoning: json['reasoning'] as String,
          wasOverridden: json['wasOverridden'] as bool? ?? false,
          userChoseDefault: json['userChoseDefault'] as bool? ?? false,
        );
      } catch (_) {}
    }
    return MessageModel(
      id: row.id,
      conversationId: row.conversationId,
      role: row.role,
      content: row.content,
      timestamp: row.timestamp,
      tokenCount: row.tokenCount,
      delegation: delegation,
      provider: row.provider,
      modelId: row.modelId,
    );
  }

  MessagesCompanion _toCompanion(MessageModel m) {
    String? delegationJson;
    if (m.delegation != null) {
      final d = m.delegation!;
      delegationJson = jsonEncode({
        'selectedModelId': d.selectedModelId,
        'selectedProvider': d.selectedProvider,
        'layerUsed': d.layerUsed,
        'confidence': d.confidence,
        'reasoning': d.reasoning,
        'wasOverridden': d.wasOverridden,
        'userChoseDefault': d.userChoseDefault,
      });
    }
    return MessagesCompanion(
      id: Value(m.id),
      conversationId: Value(m.conversationId),
      role: Value(m.role),
      content: Value(m.content),
      timestamp: Value(m.timestamp),
      tokenCount: Value(m.tokenCount),
      delegationJson: Value(delegationJson),
      provider: Value(m.provider),
      modelId: Value(m.modelId),
    );
  }
}

@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository(db: ref.watch(appDatabaseProvider));
}

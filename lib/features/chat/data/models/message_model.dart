// lib/features/chat/data/models/message_model.dart
import 'package:flutter/foundation.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';

@immutable
class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.tokenCount = 0,
    this.delegation,
    this.provider,
    this.modelId,
  });

  final String id;
  final String conversationId;

  /// 'user' | 'assistant'
  final String role;
  final String content;
  final DateTime timestamp;

  /// Total tokens (input + output) from the provider's response JSON.
  final int tokenCount;

  /// Delegation decision that routed this message. Only set on assistant messages.
  final DelegationResult? delegation;
  final String? provider;
  final String? modelId;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  MessageModel copyWith({
    String? content,
    int? tokenCount,
  }) =>
      MessageModel(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        tokenCount: tokenCount ?? this.tokenCount,
        delegation: delegation,
        provider: provider,
        modelId: modelId,
      );
}

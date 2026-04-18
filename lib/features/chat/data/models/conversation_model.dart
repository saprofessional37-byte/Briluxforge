// lib/features/chat/data/models/conversation_model.dart
import 'package:flutter/foundation.dart';

@immutable
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel copyWith({
    String? title,
    DateTime? updatedAt,
  }) =>
      ConversationModel(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

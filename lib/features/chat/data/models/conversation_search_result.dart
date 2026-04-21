// lib/features/chat/data/models/conversation_search_result.dart
import 'package:flutter/foundation.dart';

import 'package:briluxforge/features/chat/data/models/conversation_model.dart';

@immutable
class ConversationSearchResult {
  const ConversationSearchResult({
    required this.conversation,
    required this.matchedTitle,
    required this.matchedMessageContent,
    this.firstMatchingMessageSnippet,
  });

  /// The conversation that matched the search query.
  final ConversationModel conversation;

  /// True when the conversation title contains the query.
  final bool matchedTitle;

  /// True when at least one message body contains the query.
  final bool matchedMessageContent;

  /// Up to ~80 characters of context around the first message match.
  /// Null when only the title matched.
  final String? firstMatchingMessageSnippet;
}

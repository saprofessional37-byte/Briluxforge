// lib/features/chat/providers/active_conversation_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_conversation_provider.g.dart';

/// Holds the ID of the currently open conversation. Null = empty state (no chat open).
@Riverpod(keepAlive: true)
class ActiveConversationNotifier extends _$ActiveConversationNotifier {
  @override
  String? build() => null;

  void setConversation(String id) => state = id;
  void clearConversation() => state = null;
}

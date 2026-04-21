// lib/features/chat/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/chat/data/models/conversation_model.dart';
import 'package:briluxforge/features/chat/data/models/conversation_search_result.dart';
import 'package:briluxforge/features/chat/data/models/message_model.dart';
import 'package:briluxforge/features/chat/data/repositories/chat_repository.dart';
import 'package:briluxforge/features/chat/providers/active_conversation_provider.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/savings/providers/savings_provider.dart';
import 'package:briluxforge/features/skills/providers/skills_provider.dart';
import 'package:briluxforge/services/api_client_service.dart';
import 'package:briluxforge/services/api_response.dart';
import 'package:briluxforge/services/skill_injection_service.dart';

part 'chat_provider.g.dart';

const _uuid = Uuid();

// ── State ──────────────────────────────────────────────────────────────────

@immutable
class ChatState {
  const ChatState({
    this.conversation,
    required this.messages,
    this.isSending = false,
    this.streamingContent = '',
    this.lastDelegation,
    this.errorMessage,
    this.errorTechnicalDetail,
  });

  final ConversationModel? conversation;
  final List<MessageModel> messages;

  /// True while the API stream is in flight.
  final bool isSending;

  /// Accumulated text from the active stream — rendered as a temporary
  /// assistant bubble until the stream completes and persists to the DB.
  final String streamingContent;

  /// Delegation result from the most recent (or active) send.
  final DelegationResult? lastDelegation;

  /// Non-null when a send failed. Cleared on the next send attempt.
  final String? errorMessage;

  /// Sanitized raw technical detail (HTTP status, provider, API response body)
  /// from the most recent failure. Populated from [AppException.technicalDetail].
  /// Null when there is no error or when the error has no technical detail.
  final String? errorTechnicalDetail;

  bool get hasConversation => conversation != null;
  bool get isStreaming => isSending && streamingContent.isNotEmpty;

  static const ChatState empty = ChatState(messages: []);

  ChatState copyWith({
    ConversationModel? conversation,
    List<MessageModel>? messages,
    bool? isSending,
    String? streamingContent,
    DelegationResult? lastDelegation,
    String? errorMessage,
    String? errorTechnicalDetail,
    bool clearError = false,
    bool clearConversation = false,
  }) =>
      ChatState(
        conversation:
            clearConversation ? null : (conversation ?? this.conversation),
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        streamingContent: streamingContent ?? this.streamingContent,
        lastDelegation: lastDelegation ?? this.lastDelegation,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        errorTechnicalDetail: clearError
            ? null
            : (errorTechnicalDetail ?? this.errorTechnicalDetail),
      );
}

// ── Stream provider for the sidebar conversation list ──────────────────────

@riverpod
Stream<List<ConversationModel>> conversations(Ref ref) {
  return ref.watch(chatRepositoryProvider).watchAllConversations();
}

// ── Main chat notifier ─────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatState build() => ChatState.empty;

  // ── Navigation ──────────────────────────────────────────────────────────

  /// Load an existing conversation from the database.
  Future<void> selectConversation(String id) async {
    final repo = ref.read(chatRepositoryProvider);
    final conversation = await repo.getConversation(id);
    if (conversation == null) return;

    final messages = await repo.getMessages(id);
    ref
        .read(activeConversationNotifierProvider.notifier)
        .setConversation(id);

    state = ChatState(
      conversation: conversation,
      messages: messages,
    );
  }

  /// Clear the active conversation and return to the empty state.
  ///
  /// Sets the active ID to '' (not null) so the ChatScreen (with its input bar)
  /// is shown immediately — null signals the welcome landing screen.
  void newConversation() {
    ref
        .read(activeConversationNotifierProvider.notifier)
        .setConversation('');
    state = ChatState.empty;
  }

  // ── Sending ──────────────────────────────────────────────────────────────

  /// Send [content] using the provided [delegation] result.
  ///
  /// If there is no active conversation, one is created automatically.
  /// Streams the API response token-by-token, then persists the full message.
  Future<void> sendMessage(
    String content,
    DelegationResult delegation,
  ) async {
    if (content.trim().isEmpty) return;
    if (state.isSending) return;

    final repo = ref.read(chatRepositoryProvider);

    // ── 1. Ensure a conversation exists ────────────────────────────────────
    final ConversationModel conversation = state.conversation ??
        await _createConversation(content, repo);

    // ── 2. Persist the user message ─────────────────────────────────────────
    final userMsg = MessageModel(
      id: _uuid.v4(),
      conversationId: conversation.id,
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );
    await repo.addMessage(userMsg);

    state = state.copyWith(
      conversation: conversation,
      messages: [...state.messages, userMsg],
      isSending: true,
      streamingContent: '',
      lastDelegation: delegation,
      clearError: true,
    );

    // ── 3. Build API payload ─────────────────────────────────────────────────
    final apiMessages = state.messages
        .map((m) => ChatMessage(role: m.role, content: m.content))
        .toList();

    final systemPrompt = ref.read(skillInjectionServiceProvider).buildSystemPrompt(
          enabledSkills: ref.read(enabledSkillsProvider),
          selectedProvider: delegation.selectedProvider,
        );

    // ── 4. Stream the response ───────────────────────────────────────────────
    final apiClient = ref.read(apiClientServiceProvider);
    String accumulated = '';
    int inputTokens = 0;
    int outputTokens = 0;
    bool encounteredError = false;

    try {
      await for (final event in apiClient.sendPromptStreaming(
        provider: delegation.selectedProvider,
        modelId: delegation.selectedModelId,
        messages: apiMessages,
        systemPrompt: systemPrompt,
      )) {
        switch (event) {
          case ApiStreamDelta(:final content):
            accumulated += content;
            state = state.copyWith(streamingContent: accumulated);

          case ApiStreamComplete(:final response):
            inputTokens = response.inputTokens;
            outputTokens = response.outputTokens;

          case ApiStreamError(:final error):
            AppLogger.e('ChatNotifier', 'Stream error', error);
            encounteredError = true;
            final AppException? appEx =
                error is AppException ? error : null;
            state = state.copyWith(
              isSending: false,
              streamingContent: '',
              errorMessage: appEx?.message ?? _friendlyError(error),
              errorTechnicalDetail: appEx?.technicalDetail,
            );
        }
      }
    } catch (e) {
      AppLogger.e('ChatNotifier', 'Unexpected error during send', e);
      encounteredError = true;
      final AppException? appEx = e is AppException ? e : null;
      state = state.copyWith(
        isSending: false,
        streamingContent: '',
        errorMessage: appEx?.message ??
            'An unexpected error occurred. Please try again.',
        errorTechnicalDetail: appEx?.technicalDetail,
      );
    }

    if (encounteredError) return;

    // ── 5. Record tokens for savings tracker (exact counts from API response) ─
    if (inputTokens > 0 || outputTokens > 0) {
      ref.read(savingsNotifierProvider.notifier).recordCall(
            modelId: delegation.selectedModelId,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
          );
    } else {
      AppLogger.w(
        'ChatNotifier',
        'Provider ${delegation.selectedProvider} returned zero token counts — '
        'skipping savings record for this response.',
      );
    }

    // ── 6. Persist the assistant message ────────────────────────────────────
    final assistantMsg = MessageModel(
      id: _uuid.v4(),
      conversationId: conversation.id,
      role: 'assistant',
      content: accumulated,
      timestamp: DateTime.now(),
      tokenCount: inputTokens + outputTokens,
      delegation: delegation,
      provider: delegation.selectedProvider,
      modelId: delegation.selectedModelId,
    );
    await repo.addMessage(assistantMsg);

    // Touch updatedAt on the conversation so sidebar ordering stays fresh.
    await repo.updateConversation(conversation.id);

    state = state.copyWith(
      messages: [...state.messages, assistantMsg],
      isSending: false,
      streamingContent: '',
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /// Full-text search across conversation titles and message content.
  ///
  /// Delegates to [ChatRepository.search] which performs DB-level filtering
  /// on both the `conversations` and `messages` tables.
  Future<List<ConversationSearchResult>> search(String query) =>
      ref.read(chatRepositoryProvider).search(query);

  // ── Conversation management ───────────────────────────────────────────────

  Future<void> deleteConversation(String id) async {
    await ref.read(chatRepositoryProvider).deleteConversation(id);
    if (state.conversation?.id == id) {
      newConversation();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<ConversationModel> _createConversation(
    String firstMessage,
    ChatRepository repo,
  ) async {
    final now = DateTime.now();
    final title = _titleFromMessage(firstMessage);
    final conversation = ConversationModel(
      id: _uuid.v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await repo.createConversation(conversation);
    ref
        .read(activeConversationNotifierProvider.notifier)
        .setConversation(conversation.id);
    AppLogger.i('ChatNotifier', 'Created conversation: ${conversation.id}');
    return conversation;
  }

  String _titleFromMessage(String message) {
    final trimmed = message.trim().replaceAll('\n', ' ');
    if (trimmed.length <= 55) return trimmed;
    return '${trimmed.substring(0, 52)}…';
  }

  String _friendlyError(Exception error) {
    final msg = error.toString();
    if (msg.contains('ApiKeyNotFoundException')) {
      return 'No API key found for this provider. Open Settings → API Keys to add one.';
    }
    if (msg.contains('429')) {
      return 'Rate limit reached. Wait a moment and try again.';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'API key rejected. Open Settings → API Keys to update it.';
    }
    return "Couldn't reach the API. Check your connection and try again.";
  }
}

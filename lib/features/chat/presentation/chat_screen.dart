// lib/features/chat/presentation/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/widgets/error_details_card.dart';
import 'package:briluxforge/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:briluxforge/features/chat/presentation/widgets/message_bubble.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/chat/providers/chat_provider.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/presentation/widgets/delegation_failure_dialog.dart';
import 'package:briluxforge/features/delegation/providers/delegation_provider.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';
import 'package:briluxforge/features/settings/providers/settings_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Send flow ──────────────────────────────────────────────────────────────

  Future<void> _handleSend(String content) async {
    final delegationNotifier =
        ref.read(delegationNotifierProvider.notifier);
    final chatNotifier = ref.read(chatNotifierProvider.notifier);

    // ── Manual override fast-path ──────────────────────────────────────────
    // If the user explicitly chose a model via the model selector, the stored
    // state has wasOverridden: true. In that case, skip Layer 1 entirely and
    // send directly with the user's choice. The delegation engine must never
    // second-guess an explicit user decision.
    final existingResult = ref.read(delegationNotifierProvider);
    if (existingResult != null && existingResult.wasOverridden) {
      await chatNotifier.sendMessage(content, existingResult);
      _scrollToBottom();
      return;
    }

    // ── Layer 1: local rule engine (synchronous, < 5 ms) ──────────────────
    DelegationResult? result = delegationNotifier.tryLayer1(content);

    if (result == null) {
      // Layer 1 uncertain — show failure dialog and let user decide.
      if (!mounted) return;
      result = await _showDelegationDialog(content);
      if (result == null) return; // user dismissed without choosing
    }

    await chatNotifier.sendMessage(content, result);
    _scrollToBottom();
  }

  Future<DelegationResult?> _showDelegationDialog(String prompt) async {
    // Resolve display names for the dialog.
    final settings = ref.read(settingsNotifierProvider).valueOrNull;
    final profiles =
        ref.read(modelProfilesProvider).valueOrNull?.routeableModels ?? [];

    final defaultModelId = settings?.defaultModelId ?? 'deepseek-chat';
    final defaultProfile =
        profiles.firstWhereOrNull((m) => m.id == defaultModelId);
    final defaultName =
        defaultProfile?.displayName ?? _shortModelName(defaultModelId);

    // Best model = first premium profile among connected providers, or default.
    final connected = ref.read(connectedProvidersProvider);
    final bestProfile = profiles.firstWhereOrNull(
          (m) => m.isPremium && connected.contains(m.provider),
        ) ??
        defaultProfile;
    final bestName = bestProfile?.displayName ?? defaultName;

    final dialogResult = await DelegationFailureDialog.show(
      context,
      defaultModelName: defaultName,
      bestModelName: bestName,
    );
    if (dialogResult == null) return null;

    final delegationNotifier =
        ref.read(delegationNotifierProvider.notifier);

    if (dialogResult.choice == DelegationFailureChoice.useDefault) {
      return delegationNotifier.resolveDefault(prompt);
    } else {
      return delegationNotifier.resolveWithAI(prompt);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);

    // Auto-scroll when new content arrives.
    ref.listen<ChatState>(chatNotifierProvider, (prev, next) {
      final prevLen = prev?.messages.length ?? 0;
      final prevStreamLen = prev?.streamingContent.length ?? 0;
      if (next.messages.length != prevLen ||
          next.streamingContent.length > prevStreamLen) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        Expanded(
          child: _MessageList(
            chatState: chatState,
            scrollController: _scrollController,
          ),
        ),
        if (chatState.errorMessage != null)
          _ChatErrorBanner(
            message: chatState.errorMessage!,
            technicalDetail: chatState.errorTechnicalDetail,
          ),
        ChatInputBar(onSend: _handleSend),
      ],
    );
  }

  String _shortModelName(String id) => switch (id) {
        'deepseek-chat' => 'DeepSeek V3',
        'gemini-2.0-flash' => 'Gemini Flash',
        'claude-sonnet-4-20250514' => 'Claude Sonnet',
        _ => id,
      };
}

// ── Message list ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.chatState,
    required this.scrollController,
  });

  final ChatState chatState;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final messages = chatState.messages;
    final isStreaming = chatState.isStreaming;
    final isSending = chatState.isSending;

    if (messages.isEmpty && !isSending) {
      return const _EmptyConversationHint();
    }

    // +2 for top/bottom padding items, +1 for optional streaming bubble.
    final itemCount = messages.length + (isSending ? 1 : 0) + 2;

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) return const SizedBox(height: 24);
        if (index == itemCount - 1) return const SizedBox(height: 24);

        final msgIndex = index - 1;

        // Streaming assistant bubble.
        if (isSending && msgIndex == messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: StreamingMessageBubble(
              content: isStreaming ? chatState.streamingContent : '',
            ),
          );
        }

        return MessageBubble(message: messages[msgIndex]);
      },
    );
  }
}

// ── Empty conversation hint ──────────────────────────────────────────────────

class _EmptyConversationHint extends StatelessWidget {
  const _EmptyConversationHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Type a message to start the conversation.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiaryDark,
            ),
      ),
    );
  }
}

// ── Chat error banner ────────────────────────────────────────────────────────
// Wraps [ErrorDetailsCard] with the margin/insets appropriate for the chat
// layout (sits above the input bar, inside the Column).

class _ChatErrorBanner extends StatelessWidget {
  const _ChatErrorBanner({
    required this.message,
    this.technicalDetail,
  });

  final String message;
  final String? technicalDetail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ErrorDetailsCard(
        message: message,
        technicalDetail: technicalDetail,
        compact: true,
      ),
    );
  }
}

// ── Extension helpers ────────────────────────────────────────────────────────

extension _IterableExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

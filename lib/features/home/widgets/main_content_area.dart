// lib/features/home/widgets/main_content_area.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/chat/presentation/chat_screen.dart';
import 'package:briluxforge/features/chat/providers/active_conversation_provider.dart';
import 'package:briluxforge/features/chat/providers/chat_provider.dart';
import 'package:briluxforge/features/delegation/providers/delegation_provider.dart';

class MainContentArea extends ConsumerWidget {
  const MainContentArea({
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
    super.key,
  });

  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeConversationNotifierProvider);
    final hasConversation = activeId != null;

    return Container(
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          _TopBar(
            sidebarCollapsed: sidebarCollapsed,
            onToggleSidebar: onToggleSidebar,
          ),
          Expanded(
            child: hasConversation
                ? const ChatScreen()
                : _EmptyState(
                    onStartChat: () {
                      // newConversation() sets activeId = '' which transitions
                      // to ChatScreen with an empty message list + input bar.
                      ref
                          .read(chatNotifierProvider.notifier)
                          .newConversation();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.sidebarCollapsed,
    required this.onToggleSidebar,
  });

  final bool sidebarCollapsed;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatNotifierProvider);
    final title = chatState.conversation?.title;

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(bottom: BorderSide(color: AppColors.borderDark)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (sidebarCollapsed) ...[
            IconButton(
              onPressed: onToggleSidebar,
              icon: const Icon(Icons.menu, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.textSecondaryDark,
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(30, 30),
              ),
              tooltip: 'Show sidebar',
            ),
            const SizedBox(width: 8),
          ],
          if (title != null)
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryDark,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),
          const SizedBox(width: 8),
          _NewChatIconButton(
            onTap: () {
              ref.read(chatNotifierProvider.notifier).newConversation();
              ref
                  .read(delegationNotifierProvider.notifier)
                  .clearResult();
            },
          ),
        ],
      ),
    );
  }
}

class _NewChatIconButton extends StatelessWidget {
  const _NewChatIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'New Chat  Ctrl+N',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.edit_outlined,
            size: 18,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}

// ── Empty state (no conversation open) ───────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStartChat});

  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bolt,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Start a new conversation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Briluxforge routes every prompt to the best model automatically.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryDark,
                ),
          ),
          const SizedBox(height: 32),
          _SuggestionGrid(onSelect: onStartChat),
        ],
      ),
    );
  }
}

class _SuggestionGrid extends StatelessWidget {
  const _SuggestionGrid({required this.onSelect});

  final VoidCallback onSelect;

  static const List<_Suggestion> _suggestions = [
    _Suggestion(icon: Icons.code_outlined, label: 'Debug my code'),
    _Suggestion(icon: Icons.search_outlined, label: 'Research a topic'),
    _Suggestion(icon: Icons.edit_note_outlined, label: 'Write an email'),
    _Suggestion(icon: Icons.calculate_outlined, label: 'Solve a problem'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _suggestions
          .map((s) => _SuggestionChip(suggestion: s, onTap: onSelect))
          .toList(),
    );
  }
}

class _Suggestion {
  const _Suggestion({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(suggestion.icon,
                size: 15, color: AppColors.textSecondaryDark),
            const SizedBox(width: 8),
            Text(
              suggestion.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/features/home/widgets/app_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/chat/data/models/conversation_model.dart';
import 'package:briluxforge/features/chat/providers/active_conversation_provider.dart';
import 'package:briluxforge/features/chat/providers/chat_provider.dart';
import 'package:briluxforge/features/savings/presentation/widgets/savings_tracker_widget.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({required this.onToggle, super.key});

  final VoidCallback onToggle;

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConstants.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.sidebarDark,
        border: Border(right: BorderSide(color: AppColors.borderDark)),
      ),
      child: Column(
        children: [
          _SidebarHeader(onToggle: widget.onToggle),
          const Divider(color: AppColors.dividerDark, height: 1),
          _NewChatButton(
            onTap: () =>
                ref.read(chatNotifierProvider.notifier).newConversation(),
          ),
          const SizedBox(height: 6),
          _SearchField(controller: _searchController),
          const SizedBox(height: 4),
          Expanded(
            child: _ConversationList(query: _query),
          ),
          const Divider(color: AppColors.dividerDark, height: 1),
          const _SidebarFooter(),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.onToggle});

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onToggle,
            icon: const Icon(Icons.menu, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondaryDark,
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(30, 30),
            ),
            tooltip: 'Collapse sidebar',
          ),
        ],
      ),
    );
  }
}

// ── New chat ──────────────────────────────────────────────────────────────────

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Chat'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondaryDark,
            side: const BorderSide(color: AppColors.borderDark),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            alignment: Alignment.centerLeft,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Search ────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimaryDark,
            ),
        decoration: InputDecoration(
          hintText: 'Search conversations…',
          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
          prefixIcon: const Icon(
            Icons.search,
            size: 15,
            color: AppColors.textTertiaryDark,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 13),
                  color: AppColors.textTertiaryDark,
                  onPressed: controller.clear,
                  padding: EdgeInsets.zero,
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceElevatedDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Conversation list ─────────────────────────────────────────────────────────

class _ConversationList extends ConsumerWidget {
  const _ConversationList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final activeId = ref.watch(activeConversationNotifierProvider);

    return conversationsAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
      error: (_, __) => Center(
        child: Text(
          'Could not load conversations.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
          textAlign: TextAlign.center,
        ),
      ),
      data: (conversations) {
        final filtered = query.isEmpty
            ? conversations
            : conversations
                .where((c) =>
                    c.title.toLowerCase().contains(query.toLowerCase()))
                .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                query.isEmpty
                    ? 'No conversations yet.\nStart a new chat!'
                    : 'No results for "$query"',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return _GroupedConversationList(
          conversations: filtered,
          activeId: activeId,
        );
      },
    );
  }
}

class _GroupedConversationList extends ConsumerWidget {
  const _GroupedConversationList({
    required this.conversations,
    required this.activeId,
  });

  final List<ConversationModel> conversations;
  final String? activeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by relative date bucket.
    final now = DateTime.now();
    final today = <ConversationModel>[];
    final yesterday = <ConversationModel>[];
    final older = <ConversationModel>[];

    for (final c in conversations) {
      final diff = now.difference(c.updatedAt);
      if (diff.inDays == 0) {
        today.add(c);
      } else if (diff.inDays == 1) {
        yesterday.add(c);
      } else {
        older.add(c);
      }
    }

    final items = <Widget>[];

    if (today.isNotEmpty) {
      items.add(const _SectionLabel('Today'));
      items.addAll(today.map((c) => _ConversationTile(
            conversation: c,
            isActive: c.id == activeId,
          )));
    }
    if (yesterday.isNotEmpty) {
      items.add(const _SectionLabel('Yesterday'));
      items.addAll(yesterday.map((c) => _ConversationTile(
            conversation: c,
            isActive: c.id == activeId,
          )));
    }
    if (older.isNotEmpty) {
      items.add(const _SectionLabel('Older'));
      items.addAll(older.map((c) => _ConversationTile(
            conversation: c,
            isActive: c.id == activeId,
          )));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      children: items,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 3),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryDark,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
  });

  final ConversationModel conversation;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref
            .read(chatNotifierProvider.notifier)
            .selectConversation(conversation.id),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive
                            ? AppColors.textPrimaryDark
                            : AppColors.textSecondaryDark,
                        fontWeight: isActive
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                ),
              ),
              if (isActive)
                _DeleteButton(conversationId: conversation.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Delete conversation',
      child: InkWell(
        onTap: () => ref
            .read(chatNotifierProvider.notifier)
            .deleteConversation(conversationId),
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(3),
          child: Icon(
            Icons.delete_outline,
            size: 13,
            color: AppColors.textTertiaryDark,
          ),
        ),
      ),
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const SavingsTrackerWidget(),
          const SizedBox(height: 8),
          Row(
            children: [
              Builder(
                builder: (ctx) => _FooterIconButton(
                  icon: Icons.psychology_outlined,
                  tooltip: 'Skills',
                  onTap: () =>
                      Navigator.pushNamed(ctx, AppRoutes.skills),
                ),
              ),
              const SizedBox(width: 4),
              Builder(
                builder: (ctx) => _FooterIconButton(
                  icon: Icons.key_rounded,
                  tooltip: 'API Keys',
                  onTap: () =>
                      Navigator.pushNamed(ctx, AppRoutes.apiKeys),
                ),
              ),
              const SizedBox(width: 4),
              Builder(
                builder: (ctx) => _FooterIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: 'Settings  Ctrl+,',
                  onTap: () =>
                      Navigator.pushNamed(ctx, AppRoutes.settings),
                ),
              ),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterIconButton extends StatelessWidget {
  const _FooterIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.textSecondaryDark),
        ),
      ),
    );
  }
}

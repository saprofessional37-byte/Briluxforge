// lib/features/home/widgets/app_sidebar.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/features/auth/providers/auth_provider.dart';
import 'package:briluxforge/features/chat/data/models/conversation_model.dart';
import 'package:briluxforge/features/chat/data/models/conversation_search_result.dart';
import 'package:briluxforge/features/chat/providers/active_conversation_provider.dart';
import 'package:briluxforge/features/chat/providers/chat_provider.dart';
import 'package:briluxforge/features/savings/presentation/widgets/savings_tracker_widget.dart';
import 'package:briluxforge/features/updater/presentation/update_ready_banner.dart';

// ── Profile menu action enum ──────────────────────────────────────────────────

enum _ProfileMenuAction { settings, logOut }

// ── Sidebar ───────────────────────────────────────────────────────────────────

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({required this.onToggle, super.key});

  final VoidCallback onToggle;

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  final _searchController = TextEditingController();
  String _query = '';

  // Deep-search state (B.4).
  Timer? _searchDebounce;
  List<ConversationSearchResult>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text;
    setState(() => _query = query);

    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    // 150 ms debounce — prevents hitting the DB on every keystroke.
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      final results =
          await ref.read(chatNotifierProvider.notifier).search(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
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
            child: _query.trim().isEmpty
                ? const _ConversationList()
                : _SearchResultsList(
                    results: _searchResults,
                    isSearching: _isSearching,
                    query: _query,
                  ),
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
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadii.borderSm,
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
          border: const OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderSm,
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stream-based conversation list (shown when search is empty) ───────────────

class _ConversationList extends ConsumerWidget {
  const _ConversationList();

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
        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'No conversations yet.\nStart a new chat!',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return _GroupedConversationList(
          conversations: conversations,
          activeId: activeId,
        );
      },
    );
  }
}

// ── Search results list (shown while query is non-empty) ──────────────────────

class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList({
    required this.results,
    required this.isSearching,
    required this.query,
  });

  final List<ConversationSearchResult>? results;
  final bool isSearching;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isSearching) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    final list = results;
    if (list == null || list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      itemCount: list.length,
      itemBuilder: (_, i) => _SearchResultTile(result: list[i], query: query),
    );
  }
}

class _SearchResultTile extends ConsumerWidget {
  const _SearchResultTile({
    required this.result,
    required this.query,
  });

  final ConversationSearchResult result;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippet = result.firstMatchingMessageSnippet;
    // Show snippet only when the title did not also match — avoids visual
    // redundancy when both the title and a message contain the query.
    final showSnippet = snippet != null && !result.matchedTitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref
            .read(chatNotifierProvider.notifier)
            .selectConversation(result.conversation.id),
        borderRadius: AppRadii.borderSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HighlightedText(
                text: result.conversation.title,
                query: query,
                baseStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (showSnippet)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _HighlightedText(
                    text: snippet,
                    query: query,
                    baseStyle:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiaryDark,
                              fontSize: 10,
                            ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [text] with [query] substrings bolded.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
  });

  final String text;
  final String query;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <InlineSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: baseStyle?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Grouped conversation list ─────────────────────────────────────────────────

class _GroupedConversationList extends ConsumerWidget {
  const _GroupedConversationList({
    required this.conversations,
    required this.activeId,
  });

  final List<ConversationModel> conversations;
  final String? activeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        borderRadius: AppRadii.borderSm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: AppRadii.borderSm,
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
        borderRadius: AppRadii.borderXs,
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

// ── Footer ────────────────────────────────────────────────────────────────────

class _SidebarFooter extends ConsumerWidget {
  const _SidebarFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final userEmail =
        authAsync.valueOrNull?.email ?? 'Signed out';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ── Update banner (Phase 11 §8.1) ────────────────────────────────
          // Collapses to zero height when idle; slides in as a 44 px row
          // when a download is in progress or an update is ready to install.
          // Positioned immediately above SavingsTrackerWidget per spec §8.1.
          const UpdateReadyBanner(),

          // ── Savings tracker ───────────────────────────────────────────────
          const SavingsTrackerWidget(),
          const SizedBox(height: 8),

          // ── Icon tray + profile avatar ────────────────────────────────────
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
              // Profile avatar with popup menu (B.2 fix).
              PopupMenuButton<_ProfileMenuAction>(
                tooltip: 'Account',
                position: PopupMenuPosition.over,
                offset: const Offset(0, -8),
                color: AppColors.surfaceElevatedDark,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadii.borderMd,
                  side: BorderSide(color: AppColors.borderDark),
                ),
                itemBuilder: (_) => [
                  // Email header — non-interactive.
                  PopupMenuItem<_ProfileMenuAction>(
                    enabled: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      userEmail,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiaryDark,
                          ),
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<_ProfileMenuAction>(
                    value: _ProfileMenuAction.settings,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.settings_outlined,
                          size: 15,
                          color: AppColors.textSecondaryDark,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Settings',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textPrimaryDark,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<_ProfileMenuAction>(
                    value: _ProfileMenuAction.logOut,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout,
                          size: 15,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Log out',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (action) async {
                  switch (action) {
                    case _ProfileMenuAction.settings:
                      Navigator.pushNamed(context, AppRoutes.settings);
                    case _ProfileMenuAction.logOut:
                      await ref.read(authRepositoryProvider).logOut();
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle, // profile avatar — fully-rounded exempt
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
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
        borderRadius: AppRadii.borderSm,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.textSecondaryDark),
        ),
      ),
    );
  }
}

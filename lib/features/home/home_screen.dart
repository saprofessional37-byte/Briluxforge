// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/chat/providers/chat_provider.dart';
import 'package:briluxforge/features/delegation/providers/delegation_provider.dart';
import 'package:briluxforge/features/home/widgets/app_sidebar.dart';
import 'package:briluxforge/features/home/widgets/main_content_area.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _sidebarCollapsed = false;

  void _toggleSidebar() {
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  void _newChat() {
    ref.read(chatNotifierProvider.notifier).newConversation();
    ref.read(delegationNotifierProvider.notifier).clearResult();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const NewChatIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyN):
            const NewChatIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.comma,
        ): const OpenSettingsIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.comma,
        ): const OpenSettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const OpenModelSelectorIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            const OpenModelSelectorIntent(),
      },
      child: Actions(
        actions: {
          NewChatIntent: CallbackAction<NewChatIntent>(
            onInvoke: (_) {
              _newChat();
              return null;
            },
          ),
          OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
            onInvoke: (_) {
              Navigator.pushNamed(context, AppRoutes.settings);
              return null;
            },
          ),
          // Ctrl+K is handled by ChatInputBar's own Actions widget, which has
          // direct access to the delegation badge key needed to position the
          // model selector popup. This entry exists so the shortcut definition
          // in the Shortcuts map above does not go unhandled when chat is not
          // active (no-op in that case).
          OpenModelSelectorIntent: CallbackAction<OpenModelSelectorIntent>(
            onInvoke: (_) => null,
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  width:
                      _sidebarCollapsed ? 0 : AppConstants.sidebarWidth,
                  child: _sidebarCollapsed
                      ? const SizedBox.shrink()
                      : AppSidebar(onToggle: _toggleSidebar),
                ),
                Expanded(
                  child: MainContentArea(
                    sidebarCollapsed: _sidebarCollapsed,
                    onToggleSidebar: _toggleSidebar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NewChatIntent extends Intent {
  const NewChatIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class OpenModelSelectorIntent extends Intent {
  const OpenModelSelectorIntent();
}

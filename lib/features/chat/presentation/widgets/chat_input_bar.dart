// lib/features/chat/presentation/widgets/chat_input_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/routing/app_router.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/chat/presentation/widgets/delegation_badge.dart';
import 'package:briluxforge/features/chat/presentation/widgets/model_selector.dart';
import 'package:briluxforge/features/chat/providers/chat_provider.dart';
import 'package:briluxforge/features/home/home_screen.dart';
import 'package:briluxforge/features/skills/data/models/skill_model.dart';
import 'package:briluxforge/features/skills/providers/skills_provider.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  const ChatInputBar({
    required this.onSend,
    super.key,
  });

  /// Called with the trimmed message content when the user sends.
  final void Function(String content) onSend;

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _badgeKey = GlobalKey();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _hasText = false);
    widget.onSend(text);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isSending =
        ref.watch(chatNotifierProvider.select((s) => s.isSending));
    final activeSkills = ref.watch(enabledSkillsProvider);

    return Actions(
      actions: {
        OpenModelSelectorIntent: CallbackAction<OpenModelSelectorIntent>(
          onInvoke: (_) {
            showModelSelector(context, _badgeKey);
            return null;
          },
        ),
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.backgroundDark,
          border: Border(top: BorderSide(color: AppColors.borderDark)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InputField(
                  controller: _controller,
                  focusNode: _focusNode,
                  isSending: isSending,
                  onSend: _send,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DelegationBadge(
                      key: _badgeKey,
                      onTap: () => showModelSelector(context, _badgeKey),
                    ),
                    const SizedBox(width: 8),
                    _SkillsIndicator(
                      activeSkills: activeSkills,
                      onTap: () => _showSkillsPanel(context, activeSkills),
                    ),
                    const Spacer(),
                    _SendButton(
                      canSend: _hasText && !isSending,
                      onSend: _send,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSkillsPanel(
    BuildContext context,
    List<SkillModel> activeSkills,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _SkillsQuickPanel(
        onManage: () {
          Navigator.pop(ctx);
          Navigator.pushNamed(context, AppRoutes.skills);
        },
      ),
    );
  }
}

// ── Input field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey != LogicalKeyboardKey.enter) {
          return KeyEventResult.ignored;
        }
        // Ctrl/Cmd+Enter — redundant secondary binding for muscle memory.
        if (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) {
          onSend();
          return KeyEventResult.handled;
        }
        // Shift+Enter — fall through so TextField inserts a newline.
        if (HardwareKeyboard.instance.isShiftPressed) {
          return KeyEventResult.ignored;
        }
        // Bare Enter — primary send binding.
        onSend();
        return KeyEventResult.handled;
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: null,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        enabled: !isSending,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textPrimaryDark,
              height: 1.5,
            ),
        decoration: InputDecoration(
          hintText: 'Message Briluxforge…',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
          filled: true,
          fillColor: AppColors.surfaceElevatedDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderDark),
          ),
        ),
        autofocus: true,
      ),
    );
  }
}

// ── Skills indicator ──────────────────────────────────────────────────────────

class _SkillsIndicator extends StatelessWidget {
  const _SkillsIndicator({
    required this.activeSkills,
    required this.onTap,
  });

  final List<SkillModel> activeSkills;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = activeSkills.length;
    final hasActive = count > 0;
    final label = hasActive ? '$count skill${count == 1 ? '' : 's'} active' : 'No skills';

    return Tooltip(
      message: hasActive ? 'Tap to manage active skills' : 'Tap to add skills',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: hasActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasActive
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.borderDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 13,
                color: hasActive
                    ? AppColors.primary
                    : AppColors.textTertiaryDark,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: hasActive
                          ? AppColors.primary
                          : AppColors.textTertiaryDark,
                      fontWeight:
                          hasActive ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skills quick-toggle panel (bottom sheet) ──────────────────────────────────

class _SkillsQuickPanel extends ConsumerWidget {
  const _SkillsQuickPanel({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSkillsAsync = ref.watch(allSkillsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Skills',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onManage,
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          allSkillsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load skills.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiaryDark,
                    ),
              ),
            ),
            data: (skills) {
              if (skills.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No skills yet. Tap "Manage" to create one.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                        ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shrinkWrap: true,
                  itemCount: skills.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: AppColors.dividerDark,
                    height: 1,
                  ),
                  itemBuilder: (ctx, i) {
                    final skill = skills[i];
                    return _QuickToggleRow(skill: skill);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickToggleRow extends ConsumerWidget {
  const _QuickToggleRow({required this.skill});

  final SkillModel skill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: skill.isEnabled
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.psychology_outlined,
              size: 15,
              color: skill.isEnabled
                  ? AppColors.primary
                  : AppColors.textTertiaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (skill.description.isNotEmpty)
                  Text(
                    skill.description,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                          fontSize: 10,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Switch(
            value: skill.isEnabled,
            onChanged: (enabled) => ref
                .read(skillsNotifierProvider.notifier)
                .toggle(skill.id, enabled: enabled),
            activeThumbColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ── Send button ───────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({required this.canSend, required this.onSend});

  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Send  Enter',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: canSend
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canSend ? onSend : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: canSend
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

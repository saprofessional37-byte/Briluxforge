// lib/features/chat/presentation/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:highlight/highlight.dart' as hl;
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'package:briluxforge/core/constants/app_constants.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/chat/data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.maxChatContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: message.isUser
              ? _UserBubble(message: message)
              : _AssistantBubble(message: message),
        ),
      ),
    );
  }
}

/// A temporary bubble used while the assistant response is still streaming.
class StreamingMessageBubble extends StatelessWidget {
  const StreamingMessageBubble({required this.content, super.key});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AppConstants.maxChatContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: content.isEmpty
              ? _ThinkingIndicator()
              : _AssistantContent(content: content),
        ),
      ),
    );
  }
}

// ── User bubble ─────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: SelectableText(
              message.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimaryDark,
                    height: 1.5,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Assistant bubble ─────────────────────────────────────────────────────────

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AssistantContent(content: message.content),
        if (message.delegation != null || message.tokenCount > 0)
          _MessageMeta(message: message),
      ],
    );
  }
}

class _AssistantContent extends StatelessWidget {
  const _AssistantContent({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: _buildStyleSheet(context),
      builders: {'code': _CodeElementBuilder()},
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        <md.InlineSyntax>[
          md.EmojiSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(
            Uri.parse(href),
            mode: LaunchMode.externalApplication,
          );
        }
      },
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimaryDark,
        height: 1.6,
      ),
      h1: theme.textTheme.headlineSmall?.copyWith(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w700,
      ),
      h2: theme.textTheme.titleLarge?.copyWith(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
      ),
      h3: theme.textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
      ),
      strong: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w700,
        height: 1.6,
      ),
      em: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimaryDark,
        fontStyle: FontStyle.italic,
        height: 1.6,
      ),
      code: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: AppColors.accent,
        backgroundColor: Colors.transparent,
      ),
      codeblockDecoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
        color: AppColors.primary.withValues(alpha: 0.06),
      ),
      blockquote: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.textSecondaryDark,
        fontStyle: FontStyle.italic,
        height: 1.5,
      ),
      listBullet: theme.textTheme.bodyLarge?.copyWith(
        color: AppColors.textSecondaryDark,
        height: 1.6,
      ),
      tableHead: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w600,
      ),
      tableBody: theme.textTheme.bodySmall?.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      tableBorder: TableBorder.all(
        color: AppColors.borderDark,
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderDark),
        ),
      ),
    );
  }
}

class _MessageMeta extends StatelessWidget {
  const _MessageMeta({required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];

    if (message.delegation != null) {
      final d = message.delegation!;
      final modelName = _shortName(d.selectedModelId);
      final tag = d.wasOverridden
          ? '↗ $modelName (manual)'
          : d.layerUsed == 1
              ? '→ $modelName (layer 1)'
              : d.layerUsed == 2
                  ? '→ $modelName (AI routed)'
                  : '→ $modelName (default)';
      parts.add(tag);
    }
    if (message.tokenCount > 0) {
      parts.add('${message.tokenCount} tokens');
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        parts.join('  ·  '),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryDark,
              fontSize: 10,
            ),
      ),
    );
  }

  String _shortName(String id) => switch (id) {
        'deepseek-chat' => 'DeepSeek V3',
        'gemini-2.0-flash' => 'Gemini Flash',
        'claude-sonnet-4-20250514' => 'Claude Sonnet',
        'gpt-4o' => 'GPT-4o',
        _ => id.split('-').take(2).join(' '),
      };
}

// ── Thinking indicator ───────────────────────────────────────────────────────

class _ThinkingIndicator extends StatefulWidget {
  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Padding(
            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
            child: Opacity(
              opacity: (_anim.value - i * 0.15).clamp(0.2, 1.0),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.textSecondaryDark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Code block builder ───────────────────────────────────────────────────────

class _CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final lang =
        element.attributes['class']?.replaceFirst('language-', '') ?? '';
    final isBlock = element.attributes.containsKey('class') || lang.isNotEmpty;
    final code = element.textContent;

    if (!isBlock) {
      // Inline code — keep default flutter_markdown rendering.
      return null;
    }

    return _CodeBlock(code: code, language: lang);
  }
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({required this.code, required this.language});

  final String code;
  final String language;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.codeBlockBackgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderDark),
              ),
            ),
            child: Row(
              children: [
                if (widget.language.isNotEmpty)
                  Text(
                    widget.language.toLowerCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                  )
                else
                  Text(
                    'code',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiaryDark,
                          fontSize: 11,
                        ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: _copy,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Row(
                            key: const ValueKey('copied'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check,
                                  size: 13, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Copied',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.success,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('copy'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy_outlined,
                                  size: 13,
                                  color: AppColors.textTertiaryDark),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textTertiaryDark,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: _buildHighlighted(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlighted(BuildContext context) {
    try {
      final result = hl.highlight.parse(
        widget.code,
        language: widget.language.isNotEmpty ? widget.language : null,
        autoDetection: widget.language.isEmpty,
      );
      if (result.nodes != null && result.nodes!.isNotEmpty) {
        return RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.55,
              color: AppColors.textPrimaryDark,
            ),
            children: _spansFromNodes(result.nodes!),
          ),
        );
      }
    } catch (_) {}

    return Text(
      widget.code,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.55,
        color: AppColors.textPrimaryDark,
      ),
    );
  }

  List<TextSpan> _spansFromNodes(List<hl.Node> nodes) {
    return nodes.map((node) {
      if (node.value != null) {
        return TextSpan(
          text: node.value,
          style: node.className != null
              ? _styleForClass(node.className!)
              : null,
        );
      }
      if (node.children != null) {
        return TextSpan(
          children: _spansFromNodes(node.children!),
          style: node.className != null
              ? _styleForClass(node.className!)
              : null,
        );
      }
      return const TextSpan();
    }).toList();
  }

  // VS Code dark+ inspired syntax colors
  TextStyle? _styleForClass(String cls) => switch (cls) {
        'keyword' || 'selector-tag' =>
          const TextStyle(color: Color(0xFF569CD6)),
        'string' ||
        'regexp' ||
        'addition' =>
          const TextStyle(color: Color(0xFFCE9178)),
        'comment' || 'quote' =>
          const TextStyle(color: Color(0xFF6A9955)),
        'number' || 'literal' =>
          const TextStyle(color: Color(0xFFB5CEA8)),
        'function' || 'title' =>
          const TextStyle(color: Color(0xFFDCDCAA)),
        'class' ||
        'built_in' ||
        'type' =>
          const TextStyle(color: Color(0xFF4EC9B0)),
        'tag' => const TextStyle(color: Color(0xFF808080)),
        'attr' || 'variable' =>
          const TextStyle(color: Color(0xFF9CDCFE)),
        'symbol' => const TextStyle(color: Color(0xFF56B6C2)),
        'params' => const TextStyle(color: Color(0xFFDCDCAA)),
        'doctag' => const TextStyle(color: Color(0xFF608B4E)),
        'meta' || 'meta-keyword' =>
          const TextStyle(color: Color(0xFF9B9B9B)),
        _ => null,
      };
}

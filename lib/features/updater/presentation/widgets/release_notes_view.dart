// lib/features/updater/presentation/widgets/release_notes_view.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §8.1

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';

/// Scrollable markdown renderer for update release notes.
///
/// Bounded to [maxHeight] (default 280 px per §8.1). Reuses the existing
/// theme-derived [MarkdownStyleSheet] — no second stylesheet defined.
class ReleaseNotesView extends StatelessWidget {
  const ReleaseNotesView({
    super.key,
    required this.markdown,
    this.maxHeight = 280,
  });

  final String markdown;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (markdown.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'No release notes available.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: MarkdownBody(
            data: markdown,
            styleSheet:
                MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.5,
                  ),
              h1: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                  ),
              h2: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
              h3: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                  ),
              listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
              code: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.accent,
                    backgroundColor: AppColors.codeBlockBackgroundDark,
                  ),
              codeblockDecoration: const BoxDecoration(
                color: AppColors.codeBlockBackgroundDark,
                borderRadius: AppRadii.borderSm,
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// lib/core/widgets/error_details_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:briluxforge/core/theme/app_colors.dart';

/// A premium, two-layer error card used consistently across all error states
/// in Briluxforge.
///
/// **Layer 1 (always visible):** the human-readable [message] with a Copy
/// button and, when [technicalDetail] is provided, a Details toggle.
///
/// **Layer 2 (expandable):** the sanitized raw [technicalDetail] (API
/// response body, HTTP status, provider name). Rendered in a selectable
/// monospace block so the user can read, copy, and paste it into a support
/// request or GitHub issue.
///
/// The Copy button copies both layers to the clipboard in a single action,
/// so users never have to manually combine them.
///
/// Usage:
/// ```dart
/// ErrorDetailsCard(
///   message: exception.message,
///   technicalDetail: exception.technicalDetail,
/// )
/// ```
class ErrorDetailsCard extends StatefulWidget {
  const ErrorDetailsCard({
    super.key,
    required this.message,
    this.technicalDetail,
    this.compact = false,
  });

  /// Human-readable, friendly error message shown by default.
  final String message;

  /// Sanitized technical detail (API response body, HTTP status, provider).
  /// When [null] or empty, the expand toggle is not rendered.
  final String? technicalDetail;

  /// When [true], uses tighter padding — suited for inline error states
  /// (e.g., inside a chat input area). Default is [false].
  final bool compact;

  @override
  State<ErrorDetailsCard> createState() => _ErrorDetailsCardState();
}

class _ErrorDetailsCardState extends State<ErrorDetailsCard> {
  bool _expanded = false;
  bool _copied = false;

  bool get _hasTechnical =>
      widget.technicalDetail != null && widget.technicalDetail!.isNotEmpty;

  Future<void> _copyToClipboard() async {
    final StringBuffer buf = StringBuffer(widget.message);
    if (_hasTechnical) {
      buf
        ..write('\n\n--- Technical Details ---\n')
        ..write(widget.technicalDetail);
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final double vPad = widget.compact ? 10.0 : 14.0;
    final double hPad = widget.compact ? 12.0 : 14.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Primary row ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, vPad, 8, vPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error icon
                Padding(
                  padding: const EdgeInsets.only(top: 1.5),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: widget.compact ? 14 : 15,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 8),
                // Friendly message
                Expanded(
                  child: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          height: 1.55,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
                // Action buttons (copy + expand)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionChip(
                      icon: _copied
                          ? Icons.check_rounded
                          : Icons.copy_outlined,
                      label: _copied ? 'Copied' : 'Copy',
                      onTap: _copyToClipboard,
                      isActive: _copied,
                      activeColor: AppColors.success,
                    ),
                    if (_hasTechnical) ...[
                      const SizedBox(width: 4),
                      _ActionChip(
                        icon: _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        label: _expanded ? 'Less' : 'Details',
                        onTap: () => setState(() => _expanded = !_expanded),
                        isActive: _expanded,
                        activeColor: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Technical detail panel ───────────────────────────────────────
          if (_hasTechnical)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? _TechnicalPanel(
                      detail: widget.technicalDetail!,
                      hPad: hPad,
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

// ── Technical detail panel ────────────────────────────────────────────────────

class _TechnicalPanel extends StatelessWidget {
  const _TechnicalPanel({
    required this.detail,
    required this.hPad,
  });

  final String detail;
  final double hPad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: AppColors.error.withValues(alpha: 0.18),
          height: 1,
        ),
        Padding(
          padding: EdgeInsets.all(hPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TECHNICAL DETAILS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.error.withValues(alpha: 0.55),
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: SelectableText(
                  detail,
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    color: AppColors.textSecondaryDark,
                    height: 1.65,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Compact action chip button ────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color color =
        isActive ? activeColor : AppColors.textTertiaryDark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.10)
              : AppColors.backgroundDark.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.35)
                : AppColors.borderDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

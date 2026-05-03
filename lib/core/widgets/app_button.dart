// lib/core/widgets/app_button.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost }

enum AppButtonSize { compact, normal, large }

/// Unified button widget. Use instead of [ElevatedButton], [OutlinedButton],
/// or [TextButton] everywhere in the codebase.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.normal,
    this.leadingIcon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final bool isLoading;

  double get _height => switch (size) {
        AppButtonSize.compact => 32,
        AppButtonSize.normal => 36,
        AppButtonSize.large => 44,
      };

  EdgeInsets get _padding => switch (size) {
        AppButtonSize.compact =>
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        AppButtonSize.normal =>
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        AppButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      };

  @override
  Widget build(BuildContext context) {
    final effective = isLoading ? null : onPressed;
    return switch (variant) {
      AppButtonVariant.primary => _PrimaryButton(
          label: label,
          onPressed: effective,
          height: _height,
          padding: _padding,
          leadingIcon: leadingIcon,
          isLoading: isLoading,
        ),
      AppButtonVariant.secondary => _SecondaryButton(
          label: label,
          onPressed: effective,
          height: _height,
          padding: _padding,
          leadingIcon: leadingIcon,
          isLoading: isLoading,
        ),
      AppButtonVariant.ghost => _GhostButton(
          label: label,
          onPressed: effective,
          height: _height,
          padding: _padding,
          leadingIcon: leadingIcon,
          isLoading: isLoading,
        ),
    };
  }
}

// ── Primary ──────────────────────────────────────────────────────────────────
//
// Phase 13 fix: replaced the Stack-with-Positioned-1px-slab highlight with a
// vertical LinearGradient inside the button's decoration. The gradient is
// painted as a BoxDecoration fill, so it follows the ClipRRect corner radius
// naturally — no horizontal edge artefacts are possible.

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.padding,
    required this.leadingIcon,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final EdgeInsets padding;
  final IconData? leadingIcon;
  final bool isLoading;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final baseColor = isDisabled
        ? AppColors.brandPrimaryMuted.withValues(alpha: 0.4)
        : _hovered
            ? AppColors.brandPrimary
            : AppColors.brandPrimaryMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            // Gradient: subtle top-to-transparent luminance fade (~40% height),
            // then solid base color. Follows the border radius naturally.
            gradient: isDisabled
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: const Alignment(0, -0.2),
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
            color: baseColor,
            borderRadius: AppRadii.borderSm,
            boxShadow: isDisabled ? AppElevation.none : AppElevation.subtle,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(widget.leadingIcon,
                            size: 16, color: Colors.white),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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

// ── Secondary ────────────────────────────────────────────────────────────────

class _SecondaryButton extends StatefulWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.padding,
    required this.leadingIcon,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final EdgeInsets padding;
  final IconData? leadingIcon;
  final bool isLoading;

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hovered && !isDisabled ? hoverBg : Colors.transparent,
            borderRadius: AppRadii.borderSm,
            border: Border.all(
              color: isDisabled
                  ? borderColor.withValues(alpha: 0.05)
                  : borderColor,
            ),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDisabled ? fg.withValues(alpha: 0.3) : fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(
                          widget.leadingIcon,
                          size: 16,
                          color:
                              isDisabled ? fg.withValues(alpha: 0.3) : fg,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: isDisabled ? fg.withValues(alpha: 0.3) : fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

// ── Ghost ─────────────────────────────────────────────────────────────────────

class _GhostButton extends StatefulWidget {
  const _GhostButton({
    required this.label,
    required this.onPressed,
    required this.height,
    required this.padding,
    required this.leadingIcon,
    required this.isLoading,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final EdgeInsets padding;
  final IconData? leadingIcon;
  final bool isLoading;

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final isDisabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor:
          isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hovered && !isDisabled ? hoverBg : Colors.transparent,
            borderRadius: AppRadii.borderSm,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDisabled ? fg.withValues(alpha: 0.3) : fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(
                          widget.leadingIcon,
                          size: 16,
                          color:
                              isDisabled ? fg.withValues(alpha: 0.3) : fg,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: isDisabled ? fg.withValues(alpha: 0.3) : fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

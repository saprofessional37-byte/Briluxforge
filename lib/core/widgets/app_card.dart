// lib/core/widgets/app_card.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';

/// Standard surface card. AppRadii.md radius, 1px borderSubtle border.
/// Pass [onTap] to enable hover elevation and pointer cursor.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Override background; defaults to [AppColors.surfaceRaised] (dark) /
  /// [AppColors.surfaceLight] (light).
  final Color? color;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.color ??
        (isDark ? AppColors.surfaceRaised : AppColors.surfaceLight);
    final border =
        isDark ? AppColors.borderSubtle : const Color(0x0F000000); // 6% black
    final isInteractive = widget.onTap != null;
    final hoverBg =
        isDark ? AppColors.surfaceOverlay : AppColors.surfaceElevatedLight;

    return MouseRegion(
      onEnter:
          isInteractive ? (_) => setState(() => _hovered = true) : null,
      onExit:
          isInteractive ? (_) => setState(() => _hovered = false) : null,
      cursor:
          isInteractive ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isInteractive && _hovered ? hoverBg : bg,
          borderRadius: AppRadii.borderMd,
          border: Border.all(color: border),
          boxShadow: isInteractive && _hovered
              ? AppElevation.subtle
              : AppElevation.none,
        ),
        child: isInteractive
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: AppRadii.borderMd,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: _child,
              )
            : _child,
      ),
    );
  }

  Widget get _child => widget.padding != null
      ? Padding(padding: widget.padding!, child: widget.child)
      : widget.child;
}

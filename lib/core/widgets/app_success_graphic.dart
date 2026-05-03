// lib/core/widgets/app_success_graphic.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';

/// Composed onboarding success illustration.
/// Ring scales in (300ms), then checkmark fades in (200ms).
/// Uses only implicit animations — no AnimationController.
class AppSuccessGraphic extends StatefulWidget {
  const AppSuccessGraphic({super.key});

  @override
  State<AppSuccessGraphic> createState() => _AppSuccessGraphicState();
}

class _AppSuccessGraphicState extends State<AppSuccessGraphic> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Drive entrance on the next frame so AnimatedContainer sees a state change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: _visible ? 96 : 86,
      height: _visible ? 96 : 86,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.20),
        ),
        boxShadow: AppElevation.subtle,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        // Delay check appearance until after ring finishes settling.
        opacity: _visible ? 1.0 : 0.0,
        curve: Curves.easeOut,
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            size: 40,
            color: AppColors.brandPrimary,
          ),
        ),
      ),
    );
  }
}

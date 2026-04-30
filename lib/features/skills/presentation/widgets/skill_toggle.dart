// lib/features/skills/presentation/widgets/skill_toggle.dart
import 'package:flutter/material.dart';
import 'package:briluxforge/core/widgets/app_toggle.dart';

/// Labelled toggle row for a skill enable/disable setting.
/// Delegates entirely to [AppToggle].
class SkillToggle extends StatelessWidget {
  const SkillToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  final String label;
  final bool value;
  final void Function(bool) onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppToggle(
      value: value,
      onChanged: onChanged,
      label: label,
      description: subtitle,
    );
  }
}

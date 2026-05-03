// lib/features/skills/presentation/skill_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_card.dart';
import 'package:briluxforge/core/widgets/app_toggle.dart';
import 'package:briluxforge/features/skills/data/models/skill_model.dart';
import 'package:briluxforge/features/skills/providers/skills_provider.dart';

/// Route arguments for the Skill Editor screen.
class SkillEditorArgs {
  const SkillEditorArgs({this.skill});

  /// null = create mode; non-null = edit mode.
  final SkillModel? skill;
}

const _allProviders = <String, String>{
  'anthropic': 'Anthropic (Claude)',
  'deepseek': 'DeepSeek',
  'google': 'Google (Gemini)',
  'openai': 'OpenAI (GPT)',
  'groq': 'Groq',
};

class SkillEditorScreen extends ConsumerStatefulWidget {
  const SkillEditorScreen({this.skill, super.key});

  final SkillModel? skill;

  @override
  ConsumerState<SkillEditorScreen> createState() => _SkillEditorScreenState();
}

class _SkillEditorScreenState extends ConsumerState<SkillEditorScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _promptCtrl;
  late Set<String> _pinned;
  late bool _isEnabled;
  bool _isSaving = false;

  bool get _isEditing => widget.skill != null;
  bool get _isBuiltIn => widget.skill?.isBuiltIn ?? false;

  @override
  void initState() {
    super.initState();
    final s = widget.skill;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _promptCtrl = TextEditingController(text: s?.systemPrompt ?? '');
    _pinned = Set.from(s?.pinnedProviders ?? <String>[]);
    _isEnabled = s?.isEnabled ?? true;

    _promptCtrl.addListener(() => setState(() {}));
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _promptCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && _promptCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(skillsNotifierProvider.notifier);
    final providers = _pinned.isEmpty ? null : _pinned.toList();

    if (_isEditing) {
      await notifier.updateSkill(
        widget.skill!.copyWith(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          systemPrompt: _promptCtrl.text.trim(),
          pinnedProviders: providers,
          isEnabled: _isEnabled,
          clearPinnedProviders: providers == null,
        ),
      );
    } else {
      await notifier.createSkill(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        systemPrompt: _promptCtrl.text.trim(),
        pinnedProviders: providers,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? (_isBuiltIn ? 'Edit Built-in Skill' : 'Edit Skill')
        : 'New Skill';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _canSave && !_isSaving ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderDark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _FormField(
            label: 'Name',
            hint: 'e.g. "Senior Flutter Developer"',
            controller: _nameCtrl,
            readOnly: _isBuiltIn,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Description',
            hint: 'Short summary shown on the skill card',
            controller: _descCtrl,
            readOnly: _isBuiltIn,
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'System Prompt',
            hint: 'Instruction text injected before every message…',
            controller: _promptCtrl,
            minLines: 6,
            maxLines: null,
          ),
          const SizedBox(height: 20),
          _ProviderPinSection(
            selected: _pinned,
            onChanged: (updated) => setState(() => _pinned = updated),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 20),
            _EnabledRow(
              value: _isEnabled,
              onChanged: (v) => setState(() => _isEnabled = v),
            ),
          ],
          const SizedBox(height: 24),
          _PromptPreview(
            name: _nameCtrl.text,
            prompt: _promptCtrl.text,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Form field ────────────────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int minLines;
  final int? maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          readOnly: readOnly,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimaryDark,
                height: 1.55,
              ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiaryDark,
                ),
            filled: true,
            fillColor: readOnly
                ? AppColors.surfaceDark
                : AppColors.surfaceElevatedDark,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: const OutlineInputBorder(
              borderRadius: AppRadii.borderMd,
              borderSide: BorderSide(color: AppColors.borderDark),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.borderMd,
              borderSide: BorderSide(color: AppColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.borderMd,
              borderSide:
                  BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            disabledBorder: const OutlineInputBorder(
              borderRadius: AppRadii.borderMd,
              borderSide: BorderSide(color: AppColors.borderDark),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Provider pin section ──────────────────────────────────────────────────────

class _ProviderPinSection extends StatelessWidget {
  const _ProviderPinSection({
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final void Function(Set<String>) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider Pinning (optional)',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          'Leave all unchecked to apply to every provider.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryDark,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allProviders.entries.map((e) {
            final isSelected = selected.contains(e.key);
            return FilterChip(
              label: Text(e.value),
              selected: isSelected,
              onSelected: (val) {
                final next = Set<String>.from(selected);
                val ? next.add(e.key) : next.remove(e.key);
                onChanged(next);
              },
              backgroundColor: AppColors.surfaceElevatedDark,
              selectedColor: AppColors.primary.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.borderDark,
              ),
              labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondaryDark,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Enabled toggle row ────────────────────────────────────────────────────────

class _EnabledRow extends StatelessWidget {
  const _EnabledRow({required this.value, required this.onChanged});

  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: AppToggle(
        value: value,
        onChanged: onChanged,
        label: 'Enabled',
        description: 'Active skills are injected into every API call.',
      ),
    );
  }
}

// ── Prompt preview ─────────────────────────────────────────────────────────────

class _PromptPreview extends StatelessWidget {
  const _PromptPreview({required this.name, required this.prompt});

  final String name;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final preview = name.trim().isNotEmpty
        ? '## Skill: ${name.trim()}\n$trimmed'
        : trimmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Prompt Preview',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textTertiaryDark,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.codeBlockBackgroundDark,
            borderRadius: AppRadii.borderMd,
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Text(
            preview,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                  fontFamily: 'JetBrains Mono',
                  height: 1.6,
                ),
          ),
        ),
      ],
    );
  }
}

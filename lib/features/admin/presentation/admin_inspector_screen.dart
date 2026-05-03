// lib/features/admin/presentation/admin_inspector_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/features/admin/data/decision_log.dart';
import 'package:briluxforge/features/admin/providers/admin_provider.dart';
import 'package:briluxforge/features/delegation/data/engine/keyword_category.dart';
import 'package:briluxforge/features/delegation/data/engine/delegation_engine.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';

class AdminInspectorScreen extends ConsumerStatefulWidget {
  const AdminInspectorScreen({super.key});

  @override
  ConsumerState<AdminInspectorScreen> createState() =>
      _AdminInspectorScreenState();
}

class _AdminInspectorScreenState extends ConsumerState<AdminInspectorScreen> {
  final _previewController = TextEditingController();
  Timer? _debounce;
  DelegationResult? _previewResult;

  @override
  void dispose() {
    _previewController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onPreviewChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _runPreview(text);
    });
  }

  void _runPreview(String prompt) {
    if (prompt.trim().isEmpty) {
      setState(() => _previewResult = null);
      return;
    }

    final profilesAsync = ref.read(modelProfilesProvider);
    final keysAsync = ref.read(apiKeyNotifierProvider);

    final profiles = profilesAsync.valueOrNull;
    final keys = keysAsync.valueOrNull;
    if (profiles == null || keys == null) return;

    final connectedProviders = keys
        .where((k) => k.status == VerificationStatus.verified)
        .map((k) => k.provider)
        .toList();

    const engine = DelegationEngine();
    final result = engine.delegate(
      prompt: prompt,
      availableModels: profiles.routeableModels,
      connectedProviders: connectedProviders,
    );

    setState(() => _previewResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final logEntries = ref.watch(decisionLogProvider).snapshot();
    final profilesAsync = ref.watch(modelProfilesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceBase,
      body: Column(
        children: [
          _Header(onClose: () => Navigator.maybePop(context)),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xl,
                    AppSpacing.xxxl,
                  ),
                  children: [
                    _EngineStateCard(profilesAsync: profilesAsync),
                    const SizedBox(height: AppSpacing.md),
                    _LivePreviewCard(
                      controller: _previewController,
                      result: _previewResult,
                      onChanged: _onPreviewChanged,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DecisionLogCard(entries: logEntries),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.surfaceBase,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.arrow_back, size: 18),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.all(AppSpacing.sm),
              minimumSize: const Size(36, 36),
            ),
            tooltip: 'Back',
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'Delegation Inspector',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.statusWarnBg,
              borderRadius: AppRadii.borderXs,
              border: Border.all(color: AppColors.statusWarnBorder),
            ),
            child: const Text(
              'ADMIN ONLY',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.statusWarnFg,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Engine State Card ──────────────────────────────────────────────────────────

class _EngineStateCard extends ConsumerWidget {
  const _EngineStateCard({required this.profilesAsync});
  final AsyncValue<ModelProfilesData> profilesAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _InspectorCard(
      title: 'Engine State',
      child: profilesAsync.when(
        loading: () => const _LoadingRow(),
        error: (e, _) => _ErrorRow(message: e.toString()),
        data: (profiles) {
          final total = (profiles.allModels as List).length;
          final routable = (profiles.routeableModels as List).length;
          final killed = total - routable - 1; // subtract benchmark
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StateRow(label: 'Brain source', value: 'asset (bundled)'),
              const _StateRow(label: 'Schema version', value: '2'),
              _StateRow(label: 'Total models', value: '$total'),
              _StateRow(label: 'Routable models', value: '$routable'),
              if (killed > 0)
                _StateRow(
                  label: 'Kill-switched',
                  value: '$killed',
                  valueColor: AppColors.statusWarnFg,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StateRow extends StatelessWidget {
  const _StateRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live Preview Card ──────────────────────────────────────────────────────────

class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({
    required this.controller,
    required this.result,
    required this.onChanged,
  });

  final TextEditingController controller;
  final DelegationResult? result;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _InspectorCard(
      title: 'Live Preview Tester',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 4,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'Type a prompt to preview delegation routing…',
              hintStyle: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
              fillColor: AppColors.surfaceOverlay,
              contentPadding: EdgeInsets.all(AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: BorderSide(color: AppColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadii.borderSm,
                borderSide: BorderSide(
                    color: AppColors.brandPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (result == null)
            const Text(
              'Type a prompt above to see routing decision.',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            )
          else
            _PreviewResult(result: result!),
        ],
      ),
    );
  }
}

class _PreviewResult extends StatelessWidget {
  const _PreviewResult({required this.result});
  final DelegationResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.statusSuccessFg),
            const SizedBox(width: AppSpacing.sm),
            Text(
              result.selectedModelId,
              style: const TextStyle(
                color: AppColors.statusSuccessFg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (result.tieBreakerApplied)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: 1),
                decoration: const BoxDecoration(
                  color: AppColors.statusInfoBg,
                  borderRadius: AppRadii.borderXs,
                ),
                child: const Text(
                  'TIEBREAK',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.statusInfoFg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          result.reasoning,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        if (result.normalizedScores.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'NORMALIZED CATEGORY SCORES',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...result.normalizedScores.entries
              .toList()
              .sorted((a, b) => b.value.compareTo(a.value))
              .map((e) => _ScoreBar(
                    category: e.key,
                    score: e.value,
                    isWinner: e.key.jsonKey ==
                        result.normalizedScores.entries
                            .reduce((a, b) => a.value >= b.value ? a : b)
                            .key
                            .jsonKey,
                  )),
        ],
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.category,
    required this.score,
    required this.isWinner,
  });
  final KeywordCategory category;
  final double score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              category.jsonKey,
              style: TextStyle(
                color: isWinner
                    ? AppColors.statusSuccessFg
                    : AppColors.textTertiary,
                fontSize: 11,
                fontWeight:
                    isWinner ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadii.borderXs,
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: AppColors.surfaceOverlay,
                color: isWinner
                    ? AppColors.statusSuccessFg
                    : AppColors.brandPrimaryMuted,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: isWinner
                  ? AppColors.statusSuccessFg
                  : AppColors.textTertiary,
              fontSize: 11,
              fontWeight:
                  isWinner ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Decision Log Card ──────────────────────────────────────────────────────────

class _DecisionLogCard extends ConsumerWidget {
  const _DecisionLogCard({required this.entries});
  final List<DelegationDecisionLogEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _InspectorCard(
      title: 'Decision Log  (${entries.length} / 100)',
      trailing: Row(
        children: [
          TextButton.icon(
            onPressed: entries.isEmpty
                ? null
                : () async {
                    final log = ref.read(decisionLogProvider);
                    final file = await log.flushToFile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Flushed to ${file.path}'),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.save_alt, size: 14),
            label: const Text('Flush to file'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton.icon(
            onPressed: entries.isEmpty
                ? null
                : () => ref.read(decisionLogProvider).clear(),
            icon: const Icon(Icons.clear_all, size: 14),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.statusErrorFg,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      child: entries.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'No entries yet. Send a chat message to record a decision.',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            )
          : Column(
              children: entries.map((e) => _LogEntryRow(entry: e)).toList(),
            ),
    );
  }
}

class _LogEntryRow extends StatelessWidget {
  const _LogEntryRow({required this.entry});
  final DelegationDecisionLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = entry.timestamp.toLocal();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            entry.promptHashPrefix,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.winningModelId,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            entry.winningCategory.jsonKey,
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${(entry.normalizedScore * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
          if (entry.tieBreakerApplied)
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.xs),
              child: Icon(Icons.compare_arrows,
                  size: 12, color: AppColors.statusInfoFg),
            ),
        ],
      ),
    );
  }
}

// ── Shared inspector card shell ────────────────────────────────────────────────

class _InspectorCard extends StatelessWidget {
  const _InspectorCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Shared utility widgets ─────────────────────────────────────────────────────

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.brandPrimary,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          'Loading…',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(color: AppColors.statusErrorFg, fontSize: 12),
    );
  }
}

// ── List extension used by _PreviewResult ─────────────────────────────────────

extension _SortedList<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) =>
      List<T>.from(this)..sort(compare);
}

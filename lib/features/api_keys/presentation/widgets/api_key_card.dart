// lib/features/api_keys/presentation/widgets/api_key_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/errors/error_translator.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_button.dart';
import 'package:briluxforge/core/widgets/app_card.dart';
import 'package:briluxforge/core/widgets/app_dialog.dart';
import 'package:briluxforge/core/widgets/app_error_display.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/presentation/widgets/key_status_indicator.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';

/// Full management card for a single connected API key.
class ApiKeyCard extends ConsumerStatefulWidget {
  const ApiKeyCard({required this.model, super.key});

  final ApiKeyModel model;

  @override
  ConsumerState<ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends ConsumerState<ApiKeyCard> {
  bool _guideExpanded = false;
  _VerifyError? _verifyError;

  ProviderConfig get _config =>
      kSupportedProviders.firstWhere((p) => p.id == widget.model.provider);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: _borderColor.withValues(alpha: 0.04),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.borderMd,
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            _CardBody(
              model: widget.model,
              config: _config,
              verifyError: _verifyError,
              guideExpanded: _guideExpanded,
              onVerify: _handleVerify,
              onRemove: _handleRemove,
              onToggleGuide: () =>
                  setState(() => _guideExpanded = !_guideExpanded),
              onDismissError: () => setState(() => _verifyError = null),
            ),
            if (_guideExpanded) _ScreenshotWalkthrough(config: _config),
          ],
        ),
      ),
    );
  }

  Color get _borderColor {
    if (_verifyError != null) {
      return AppColors.statusErrorBorder;
    }
    return switch (widget.model.status) {
      VerificationStatus.verified => AppColors.statusSuccessBorder,
      VerificationStatus.failed   => AppColors.statusErrorBorder,
      VerificationStatus.verifying => AppColors.statusInfoBorder,
      VerificationStatus.unverified => AppColors.borderSubtle,
    };
  }

  Future<void> _handleVerify() async {
    setState(() => _verifyError = null);
    try {
      await ref
          .read(apiKeyNotifierProvider.notifier)
          .verifyKey(widget.model.provider);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _verifyError = _VerifyError(exception: e));
      }
    } catch (_) {
      // Non-AppException — show generic verification-failed message.
      // Do not expose raw exception strings to the UI (§8.4 CLAUDE.MD).
      if (mounted) {
        setState(() => _verifyError = const _VerifyError());
      }
    }
  }

  Future<void> _handleRemove() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Remove ${_config.displayName}?',
      body: Text(
        'This permanently deletes the key from secure storage. '
        'You will need to re-enter it to use ${_config.displayName} again.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
      ),
      primaryLabel: 'Remove',
      onPrimary: () => Navigator.pop(context, true),
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.pop(context, false),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(apiKeyNotifierProvider.notifier)
          .removeKey(widget.model.provider);
    }
  }
}

/// Holds the last verification error.
class _VerifyError {
  // ignore: unused_element_parameter
  const _VerifyError({this.exception, this.raw});

  final AppException? exception;
  final String? raw;
}

// ──────────────────────────────────────────────────────────
// Card body
// ──────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.model,
    required this.config,
    required this.verifyError,
    required this.guideExpanded,
    required this.onVerify,
    required this.onRemove,
    required this.onToggleGuide,
    required this.onDismissError,
  });

  final ApiKeyModel model;
  final ProviderConfig config;
  final _VerifyError? verifyError;
  final bool guideExpanded;
  final VoidCallback onVerify;
  final VoidCallback onRemove;
  final VoidCallback onToggleGuide;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _ProviderIcon(config: config),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      config.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              KeyStatusIndicator(status: model.status),
            ],
          ),

          // Last verified timestamp
          if (model.status == VerificationStatus.verified &&
              model.lastVerifiedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Verified ${_relativeTime(model.lastVerifiedAt!)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
            ),
          ],

          // Error display
          if (verifyError != null) ...[
            const SizedBox(height: AppSpacing.md),
            if (verifyError!.exception != null)
              AppErrorDisplay(
                error: ErrorTranslator.translate(
                  verifyError!.exception!,
                  onAction: onDismissError,
                  actionLabel: 'Dismiss',
                ),
              )
            else
              AppErrorDisplay(
                error: ErrorTranslator.translate(
                  ApiRequestException(
                    provider: config.displayName,
                    message: verifyError!.raw ?? 'Verification failed.',
                  ),
                  onAction: onDismissError,
                  actionLabel: 'Dismiss',
                ),
              ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Action row
          Row(
            children: [
              AppButton(
                label: 'Verify',
                leadingIcon: Icons.refresh_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.compact,
                onPressed: model.status == VerificationStatus.verifying
                    ? null
                    : onVerify,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Remove',
                leadingIcon: Icons.delete_outline_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.compact,
                onPressed: onRemove,
              ),
              const Spacer(),
              AppButton(
                label: guideExpanded ? 'Hide guide' : 'How to get key',
                leadingIcon: guideExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.help_outline_rounded,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.compact,
                onPressed: onToggleGuide,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ──────────────────────────────────────────────────────────
// Screenshot walkthrough
// ──────────────────────────────────────────────────────────

class _ScreenshotWalkthrough extends StatelessWidget {
  const _ScreenshotWalkthrough({required this.config});

  final ProviderConfig config;

  @override
  Widget build(BuildContext context) {
    final host = config.signupUrl.replaceFirst('https://', '');
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg + 2,
        AppSpacing.lg + 2,
        AppSpacing.lg + 2,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to get your ${config.displayName} API key',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Step(number: 1, text: 'Go to $host and create a free account.'),
          const SizedBox(height: AppSpacing.sm),
          const _ImagePlaceholder(label: 'Screenshot: sign-up page'),
          const SizedBox(height: AppSpacing.lg),
          const _Step(
            number: 2,
            text:
                'Navigate to the API Keys section in your account dashboard.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ImagePlaceholder(label: 'Screenshot: dashboard → API Keys'),
          const SizedBox(height: AppSpacing.lg),
          const _Step(
            number: 3,
            text:
                'Click "Create new key" (or equivalent). Copy the key — it\'s shown only once.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ImagePlaceholder(label: 'Screenshot: key creation dialog'),
          const SizedBox(height: AppSpacing.lg),
          const _Step(
            number: 4,
            text: 'Paste the key in the field above and click Add & Verify.',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Shared small widgets
// ──────────────────────────────────────────────────────────

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.config});

  final ProviderConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: AppRadii.borderMd,
      ),
      child: Icon(config.iconData, color: config.color, size: 22),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.borderSubtle,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined,
              size: 30, color: AppColors.textTertiaryDark),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                ),
          ),
        ],
      ),
    );
  }
}

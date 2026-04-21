// lib/features/api_keys/presentation/widgets/api_key_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/presentation/widgets/key_status_indicator.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';

/// Full management card for a single connected API key.
/// Shows status, verify / remove actions, and an expandable screenshot guide.
class ApiKeyCard extends ConsumerStatefulWidget {
  const ApiKeyCard({required this.model, super.key});

  final ApiKeyModel model;

  @override
  ConsumerState<ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends ConsumerState<ApiKeyCard> {
  bool _guideExpanded = false;
  String? _errorMessage;

  ProviderConfig get _config =>
      kSupportedProviders.firstWhere((p) => p.id == widget.model.provider);

  @override
  Widget build(BuildContext context) {
    final borderColor = _resolveBorderColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          _CardBody(
            model: widget.model,
            config: _config,
            errorMessage: _errorMessage,
            guideExpanded: _guideExpanded,
            onVerify: _handleVerify,
            onRemove: _handleRemove,
            onToggleGuide: () =>
                setState(() => _guideExpanded = !_guideExpanded),
          ),
          if (_guideExpanded)
            _ScreenshotWalkthrough(config: _config),
        ],
      ),
    );
  }

  Color _resolveBorderColor() {
    if (_errorMessage != null) {
      return AppColors.error.withValues(alpha: 0.4);
    }
    return switch (widget.model.status) {
      VerificationStatus.verified => AppColors.success.withValues(alpha: 0.3),
      VerificationStatus.failed => AppColors.error.withValues(alpha: 0.3),
      VerificationStatus.verifying => AppColors.info.withValues(alpha: 0.3),
      VerificationStatus.unverified => AppColors.borderDark,
    };
  }

  Future<void> _handleVerify() async {
    setState(() => _errorMessage = null);
    try {
      await ref
          .read(apiKeyNotifierProvider.notifier)
          .verifyKey(widget.model.provider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        });
      }
    }
  }

  Future<void> _handleRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevatedDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Remove ${_config.displayName}?',
          style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        content: Text(
          'This permanently deletes the key from secure storage. '
          'You will need to re-enter it to use ${_config.displayName} again.',
          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryDark,
                height: 1.5,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(apiKeyNotifierProvider.notifier)
          .removeKey(widget.model.provider);
    }
  }
}

// ──────────────────────────────────────────────────────────
// Card body
// ──────────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.model,
    required this.config,
    required this.errorMessage,
    required this.guideExpanded,
    required this.onVerify,
    required this.onRemove,
    required this.onToggleGuide,
  });

  final ApiKeyModel model;
  final ProviderConfig config;
  final String? errorMessage;
  final bool guideExpanded;
  final VoidCallback onVerify;
  final VoidCallback onRemove;
  final VoidCallback onToggleGuide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              _ProviderIcon(config: config),
              const SizedBox(width: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      config.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              KeyStatusIndicator(status: model.status),
            ],
          ),

          // Last verified timestamp
          if (model.status == VerificationStatus.verified &&
              model.lastVerifiedAt != null) ...[
            const SizedBox(height: 10),
            Text(
              'Verified ${_relativeTime(model.lastVerifiedAt!)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                  ),
            ),
          ],

          // Error feedback
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: errorMessage!),
          ],

          const SizedBox(height: 16),

          // Action row
          Row(
            children: [
              _ActionButton(
                icon: Icons.refresh_rounded,
                label: 'Verify',
                onPressed: model.status == VerificationStatus.verifying
                    ? null
                    : onVerify,
                color: AppColors.textSecondaryDark,
                borderColor: AppColors.borderDark,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                label: 'Remove',
                onPressed: onRemove,
                color: AppColors.error,
                borderColor: AppColors.error.withValues(alpha: 0.3),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onToggleGuide,
                icon: Icon(
                  guideExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.help_outline_rounded,
                  size: 14,
                ),
                label: Text(guideExpanded ? 'Hide guide' : 'How to get key'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textTertiaryDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
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
// Screenshot walkthrough (expandable)
// ──────────────────────────────────────────────────────────

class _ScreenshotWalkthrough extends StatelessWidget {
  const _ScreenshotWalkthrough({required this.config});

  final ProviderConfig config;

  @override
  Widget build(BuildContext context) {
    final host = config.signupUrl.replaceFirst('https://', '');
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
          const SizedBox(height: 16),
          _Step(
            number: 1,
            text: 'Go to $host and create a free account.',
          ),
          const SizedBox(height: 10),
          const _ImagePlaceholder(label: 'Screenshot: sign-up page'),
          const SizedBox(height: 16),
          const _Step(
            number: 2,
            text: 'Navigate to the API Keys section in your account dashboard.',
          ),
          const SizedBox(height: 10),
          const _ImagePlaceholder(label: 'Screenshot: dashboard → API Keys'),
          const SizedBox(height: 16),
          const _Step(
            number: 3,
            text:
                "Click \"Create new key\" (or equivalent). Copy the key — it's shown only once.",
          ),
          const SizedBox(height: 10),
          const _ImagePlaceholder(label: 'Screenshot: key creation dialog'),
          const SizedBox(height: 16),
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
// Small shared widgets
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(config.iconData, color: config.color, size: 22),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
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
            color: AppColors.borderDark,
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
        const SizedBox(width: 10),
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
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined,
              size: 30, color: AppColors.textTertiaryDark),
          const SizedBox(height: 8),
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

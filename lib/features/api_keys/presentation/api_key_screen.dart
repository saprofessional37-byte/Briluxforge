// lib/features/api_keys/presentation/api_key_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/error_details_card.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/presentation/widgets/api_key_card.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';

/// Full API key management screen. Accessible from the sidebar and Settings.
/// Shows connected keys and an add-key panel with provider picker + key field.
class ApiKeyScreen extends ConsumerWidget {
  const ApiKeyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(apiKeyNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Text(
          'API Keys',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w600,
              ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textSecondaryDark,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.borderDark, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AddKeyPanel(),
                const SizedBox(height: 32),
                _ConnectedKeysList(keysAsync: keysAsync),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Add key panel
// ──────────────────────────────────────────────────────────

class _AddKeyPanel extends ConsumerStatefulWidget {
  const _AddKeyPanel();

  @override
  ConsumerState<_AddKeyPanel> createState() => _AddKeyPanelState();
}

class _AddKeyPanelState extends ConsumerState<_AddKeyPanel> {
  String _selectedProvider = kSupportedProviders.first.id;
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _isAdding = false;
  String? _errorMessage;
  String? _errorTechnicalDetail;
  String? _successMessage;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  ProviderConfig get _selectedConfig =>
      kSupportedProviders.firstWhere((p) => p.id == _selectedProvider);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadii.borderMd,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add an API key',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stored in platform-native secure storage. Never leaves your device.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.dividerDark, height: 1),
          const SizedBox(height: 24),

          // Provider selector
          Text(
            'PROVIDER',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSupportedProviders.map(_buildProviderChip).toList(),
          ),

          const SizedBox(height: 24),

          // Key field
          Text(
            'API KEY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryDark,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _keyController,
            obscureText: _obscureKey,
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              color: AppColors.textPrimaryDark,
              letterSpacing: 0.5,
            ),
            decoration: InputDecoration(
              hintText: 'Paste your ${_selectedConfig.displayName} API key…',
              hintStyle: const TextStyle(
                color: AppColors.textTertiaryDark,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: const OutlineInputBorder(
                borderRadius: AppRadii.borderMd,
                borderSide: BorderSide(color: AppColors.borderDark),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: AppRadii.borderMd,
                borderSide: BorderSide(color: AppColors.borderDark),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadii.borderMd,
                borderSide:
                    BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureKey = !_obscureKey),
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textTertiaryDark,
                ),
                tooltip: _obscureKey ? 'Show key' : 'Hide key',
              ),
            ),
            onSubmitted: (_) => _handleAdd(),
          ),

          // Feedback
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            ErrorDetailsCard(
              message: _errorMessage!,
              technicalDetail: _errorTechnicalDetail,
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 12),
            _SuccessBanner(message: _successMessage!),
          ],

          const SizedBox(height: 20),

          // CTA
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: _isAdding ? null : _handleAdd,
              icon: _isAdding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isAdding ? 'Verifying…' : 'Add & Verify'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderChip(ProviderConfig p) {
    final selected = _selectedProvider == p.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedProvider = p.id;
        _errorMessage = null;
        _errorTechnicalDetail = null;
        _successMessage = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? p.color.withValues(alpha: 0.14)
              : AppColors.backgroundDark,
          borderRadius: AppRadii.borderSm,
          border: Border.all(
            color: selected
                ? p.color.withValues(alpha: 0.55)
                : AppColors.borderDark,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              p.iconData,
              size: 14,
              color: selected ? p.color : AppColors.textTertiaryDark,
            ),
            const SizedBox(width: 7),
            Text(
              p.displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? p.color
                    : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdd() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _errorMessage = 'Please paste your API key first.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isAdding = true;
      _errorMessage = null;
      _errorTechnicalDetail = null;
      _successMessage = null;
    });

    try {
      await ref.read(apiKeyNotifierProvider.notifier).addKey(
            provider: _selectedProvider,
            rawKey: key,
          );
      if (mounted) {
        setState(() {
          _successMessage =
              '${_selectedConfig.displayName} connected successfully!';
          _keyController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        // AppException subtype → use structured message; other exceptions get a
        // generic fallback per §8.4 (no raw exception strings shown to users).
        final appEx = e is AppException ? e : null;
        setState(() {
          _errorMessage = appEx?.message ??
              'Failed to save the API key. Check the key format and try again.';
          _errorTechnicalDetail = appEx?.technicalDetail;
        });
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }
}

// ──────────────────────────────────────────────────────────
// Connected keys list
// ──────────────────────────────────────────────────────────

class _ConnectedKeysList extends StatelessWidget {
  const _ConnectedKeysList({required this.keysAsync});

  final AsyncValue<List<ApiKeyModel>> keysAsync;

  @override
  Widget build(BuildContext context) {
    return keysAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Text(
          'Could not load saved keys: $e',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.error),
        ),
      ),
      data: (keys) {
        if (keys.isEmpty) return _EmptyKeysState();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONNECTED PROVIDERS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryDark,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...keys.map(
              (model) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ApiKeyCard(model: model),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────
// Empty state
// ──────────────────────────────────────────────────────────

class _EmptyKeysState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: AppRadii.borderLg,
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.borderDark.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.key_off_outlined,
              color: AppColors.textTertiaryDark,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No API keys yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first key above. '
            'DeepSeek + Gemini is the recommended starter combo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryDark,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Success banner
// ──────────────────────────────────────────────────────────

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppRadii.borderSm,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

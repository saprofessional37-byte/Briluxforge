// lib/features/delegation/providers/delegation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';
import 'package:briluxforge/features/delegation/data/engine/delegation_engine.dart';
import 'package:briluxforge/features/delegation/data/engine/fallback_handler.dart';
import 'package:briluxforge/features/delegation/data/models/delegation_result.dart';
import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';
import 'package:briluxforge/features/settings/providers/settings_provider.dart';
import 'package:briluxforge/services/secure_storage_service.dart';

part 'delegation_provider.g.dart';

/// Convenience provider: list of provider IDs that have verified API keys.
@riverpod
List<String> connectedProviders(Ref ref) {
  final keys = ref.watch(apiKeyNotifierProvider).valueOrNull ?? [];
  return keys
      .where((k) => k.status == VerificationStatus.verified)
      .map((k) => k.provider)
      .toList();
}

/// Manages the active delegation result for the current message being composed.
///
/// Flow for the chat screen:
///   1. Call [tryLayer1] — returns a result if confident, null if uncertain.
///   2. If null, show [DelegationFailureDialog].
///   3. Based on user choice call [resolveDefault] or [resolveWithAI].
///   4. Use the returned [DelegationResult] for the API call.
///   5. Call [applyManualOverride] if the user changes the model via the badge.
///   6. Call [clearResult] when starting a new message.
@riverpod
class DelegationNotifier extends _$DelegationNotifier {
  @override
  DelegationResult? build() => null;

  // ── Layer 1 ────────────────────────────────────────────────────────────────

  /// Runs the local rule engine synchronously. Returns null when confidence is
  /// below the threshold — the caller should then show [DelegationFailureDialog].
  DelegationResult? tryLayer1(String prompt) {
    final profiles = ref.read(modelProfilesProvider).valueOrNull;
    if (profiles == null) {
      AppLogger.w('DelegationNotifier',
          'Model profiles not yet loaded — cannot run Layer 1.');
      return null;
    }

    final connected = ref.read(connectedProvidersProvider);
    const engine = DelegationEngine();

    final result = engine.delegate(
      prompt: prompt,
      availableModels: profiles.routeableModels,
      connectedProviders: connected,
    );

    if (result != null) state = result;
    return result;
  }

  // ── Layer 3 — user chose "Use Default" ────────────────────────────────────

  Future<DelegationResult> resolveDefault(String prompt) async {
    final profiles = ref.read(modelProfilesProvider).valueOrNull!;
    final settings = await ref.read(settingsNotifierProvider.future);
    final connected = ref.read(connectedProvidersProvider);

    final handler = FallbackHandler(
      secureStorage: ref.read(secureStorageServiceProvider),
    );

    final result = handler.layer3Default(
      defaultModelId: settings.defaultModelId,
      availableModels: profiles.routeableModels,
      connectedProviders: connected,
      userChoseDefault: true,
    );

    state = result;
    return result;
  }

  // ── Layer 2 → Layer 3 — user chose "Let AI Decide" ────────────────────────

  Future<DelegationResult> resolveWithAI(String prompt) async {
    final profiles = ref.read(modelProfilesProvider).valueOrNull!;
    final settings = await ref.read(settingsNotifierProvider.future);
    final connected = ref.read(connectedProvidersProvider);

    final handler = FallbackHandler(
      secureStorage: ref.read(secureStorageServiceProvider),
    );

    // Try Layer 2 first.
    final layer2 = await handler.layer2Classify(
      prompt: prompt,
      availableModels: profiles.routeableModels,
      connectedProviders: connected,
      defaultModelId: settings.defaultModelId,
    );

    if (layer2 != null) {
      state = layer2;
      return layer2;
    }

    // Layer 2 failed — fall through to Layer 3 and surface a notification banner.
    AppLogger.w('DelegationNotifier',
        'Layer 2 classification failed — falling back to Layer 3.');

    final layer3 = handler.layer3Default(
      defaultModelId: settings.defaultModelId,
      availableModels: profiles.routeableModels,
      connectedProviders: connected,
    );

    state = layer3;
    return layer3;
  }

  // ── Manual override ────────────────────────────────────────────────────────

  /// Records that the user manually changed the model after delegation decided.
  DelegationResult applyManualOverride({
    required DelegationResult original,
    required ModelProfile chosenModel,
  }) {
    final overridden = original.copyWith(
      selectedModelId: chosenModel.id,
      selectedProvider: chosenModel.provider,
      wasOverridden: true,
      reasoning: 'Manual override: you selected ${chosenModel.displayName}.',
    );
    state = overridden;
    return overridden;
  }

  void clearResult() => state = null;
}

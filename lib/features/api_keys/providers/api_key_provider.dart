// lib/features/api_keys/providers/api_key_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/data/repositories/api_key_repository.dart';
import 'package:briluxforge/services/secure_storage_service.dart';
import 'package:briluxforge/services/shared_prefs_provider.dart';

part 'api_key_provider.g.dart';

@riverpod
Future<ApiKeyRepository> apiKeyRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ApiKeyRepository(
    secureStorage: ref.watch(secureStorageServiceProvider),
    prefs: prefs,
  );
}

@riverpod
class ApiKeyNotifier extends _$ApiKeyNotifier {
  @override
  Future<List<ApiKeyModel>> build() async {
    final repo = await ref.watch(apiKeyRepositoryProvider.future);
    return repo.loadAll();
  }

  /// Saves the key and immediately runs verification.
  /// State transitions: existing list → adds model with [verifying] status →
  /// updates to [verified] or [failed] based on result.
  Future<void> addKey({
    required String provider,
    required String rawKey,
  }) async {
    final config = kSupportedProviders.firstWhere((p) => p.id == provider);
    final repo = await ref.read(apiKeyRepositoryProvider.future);

    final verifyingModel = ApiKeyModel(
      provider: provider,
      displayName: config.displayName,
      status: VerificationStatus.verifying,
    );

    // Persist key to secure storage immediately so verifyKey can read it.
    await repo.save(verifyingModel, rawKey);

    // Show verifying status in UI before network call.
    _upsertInState(verifyingModel);

    try {
      await repo.verifyKey(provider);
      final verified = verifyingModel.copyWith(
        status: VerificationStatus.verified,
        lastVerifiedAt: DateTime.now(),
      );
      await repo.updateMeta(verified);
      _upsertInState(verified);
    } catch (e) {
      final failed = verifyingModel.copyWith(status: VerificationStatus.failed);
      await repo.updateMeta(failed);
      _upsertInState(failed);
      rethrow;
    }
  }

  /// Re-runs verification for an already-saved key.
  Future<void> verifyKey(String provider) async {
    final config = kSupportedProviders.firstWhere((p) => p.id == provider);
    final repo = await ref.read(apiKeyRepositoryProvider.future);

    final verifying = ApiKeyModel(
      provider: provider,
      displayName: config.displayName,
      status: VerificationStatus.verifying,
    );
    _upsertInState(verifying);

    try {
      await repo.verifyKey(provider);
      final verified = verifying.copyWith(
        status: VerificationStatus.verified,
        lastVerifiedAt: DateTime.now(),
      );
      await repo.updateMeta(verified);
      _upsertInState(verified);
    } catch (e) {
      final failed = verifying.copyWith(status: VerificationStatus.failed);
      await repo.updateMeta(failed);
      _upsertInState(failed);
      rethrow;
    }
  }

  Future<void> removeKey(String provider) async {
    final repo = await ref.read(apiKeyRepositoryProvider.future);
    await repo.delete(provider);
    final current = List<ApiKeyModel>.from(state.valueOrNull ?? []);
    current.removeWhere((k) => k.provider == provider);
    state = AsyncData(current);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _upsertInState(ApiKeyModel model) {
    final current = List<ApiKeyModel>.from(state.valueOrNull ?? []);
    final index = current.indexWhere((k) => k.provider == model.provider);
    if (index == -1) {
      current.add(model);
    } else {
      current[index] = model;
    }
    state = AsyncData(current);
  }
}

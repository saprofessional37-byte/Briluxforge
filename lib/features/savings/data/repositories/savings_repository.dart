// lib/features/savings/data/repositories/savings_repository.dart

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/savings/data/models/savings_model.dart';
import 'package:briluxforge/services/shared_prefs_provider.dart';

part 'savings_repository.g.dart';

const String _savingsKey = 'savings_model_v1';

class SavingsRepository {
  const SavingsRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  Future<SavingsModel> loadModel() async {
    final String? raw = _prefs.getString(_savingsKey);
    if (raw == null) return SavingsModel.empty();
    try {
      return SavingsModel.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (e) {
      AppLogger.w(
        'SavingsRepository',
        'Failed to parse savings data — resetting. $e',
      );
      return SavingsModel.empty();
    }
  }

  Future<void> _save(SavingsModel model) async {
    await _prefs.setString(_savingsKey, jsonEncode(model.toJson()));
  }

  /// Records a successful API call and returns the updated [SavingsModel].
  ///
  /// If both token counts are zero (streaming edge case where the provider
  /// omitted usage fields), the call is skipped and the existing model is
  /// returned unchanged. A warning is logged.
  Future<SavingsModel> recordCall({
    required String modelId,
    required int inputTokens,
    required int outputTokens,
  }) async {
    if (inputTokens <= 0 && outputTokens <= 0) {
      AppLogger.w(
        'SavingsRepository',
        'Skipping savings record for $modelId — provider returned zero token counts.',
      );
      return loadModel();
    }

    final SavingsModel current = await loadModel();
    final SavingsModel updated = current.addCall(
      modelId: modelId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
    await _save(updated);
    return updated;
  }

  Future<void> clear() async {
    await _prefs.remove(_savingsKey);
  }
}

@riverpod
Future<SavingsRepository> savingsRepository(Ref ref) async {
  final SharedPreferences prefs =
      await ref.watch(sharedPreferencesProvider.future);
  return SavingsRepository(prefs: prefs);
}

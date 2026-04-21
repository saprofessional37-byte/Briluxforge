// lib/features/savings/providers/savings_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';
import 'package:briluxforge/features/savings/data/models/savings_model.dart';
import 'package:briluxforge/features/savings/data/repositories/savings_calculator.dart';
import 'package:briluxforge/features/savings/data/repositories/savings_repository.dart';

part 'savings_provider.g.dart';

const _calculator = SavingsCalculator();

/// Manages the savings state and exposes a [SavingsSnapshot] derived from
/// locally-stored per-model token counts and current model pricing.
///
/// Kept alive for the lifetime of the app — savings data must never be dropped.
@Riverpod(keepAlive: true)
class SavingsNotifier extends _$SavingsNotifier {
  @override
  Future<SavingsSnapshot> build() async {
    final SavingsRepository repo =
        await ref.watch(savingsRepositoryProvider.future);
    final ModelProfilesData profiles =
        await ref.watch(modelProfilesProvider.future);

    final SavingsModel model = await repo.loadModel();
    return _calculator.compute(
      model: model,
      allProfiles: profiles.allModels,
      benchmarkModel: profiles.benchmarkModel,
    );
  }

  /// Records a successful API call and updates the savings snapshot.
  ///
  /// Called by [ChatNotifier] after every [ApiStreamComplete] event.
  /// Uses exact token counts from the API response — never estimated values.
  Future<void> recordCall({
    required String modelId,
    required int inputTokens,
    required int outputTokens,
  }) async {
    try {
      final SavingsRepository repo =
          await ref.read(savingsRepositoryProvider.future);
      final ModelProfilesData profiles =
          await ref.read(modelProfilesProvider.future);

      final SavingsModel updated = await repo.recordCall(
        modelId: modelId,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      );

      final SavingsSnapshot snapshot = _calculator.compute(
        model: updated,
        allProfiles: profiles.allModels,
        benchmarkModel: profiles.benchmarkModel,
      );

      state = AsyncValue.data(snapshot);
    } catch (e, st) {
      AppLogger.e('SavingsNotifier', 'Failed to record call savings', e, st);
      // Do not update state on error — existing snapshot is preserved.
    }
  }

  /// Clears all savings data. Exposed for testing and the Settings reset option.
  Future<void> clear() async {
    try {
      final SavingsRepository repo =
          await ref.read(savingsRepositoryProvider.future);
      await repo.clear();
      state = const AsyncValue.data(SavingsSnapshot.zero);
    } catch (e, st) {
      AppLogger.e('SavingsNotifier', 'Failed to clear savings', e, st);
    }
  }
}

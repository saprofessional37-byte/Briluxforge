// lib/features/updater/providers/feature_flags_provider.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §7.4

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/features/updater/data/models/feature_flags_model.dart';
import 'package:briluxforge/features/updater/domain/updater_service.dart';

part 'feature_flags_provider.g.dart';

/// Exposes the latest [FeatureFlagsModel] from the most recent manifest check.
///
/// Feature flags are sourced from the manifest itself (§7.4), not the brain
/// payload, so they update on every successful 6-hour check regardless of
/// whether the brain version advanced.
///
/// Default value for any unknown flag is `false` (§4.1 — FeatureFlagsModel
/// enforces this via its `getFlag` method).
///
/// keepAlive: flags must survive route changes.
@Riverpod(keepAlive: true)
class FeatureFlags extends _$FeatureFlags {
  @override
  Stream<FeatureFlagsModel> build() {
    return UpdaterService.instance.featureFlagsStream;
  }

  /// Returns the current flags synchronously, defaulting to empty if the
  /// first manifest check has not yet completed.
  FeatureFlagsModel get current =>
      state.valueOrNull ?? const FeatureFlagsModel.empty();
}

// Remember: `dart run build_runner build --delete-conflicting-outputs`

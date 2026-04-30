// lib/features/updater/providers/kill_switches_provider.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §7.4

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:briluxforge/features/updater/data/models/kill_switches_model.dart';
import 'package:briluxforge/features/updater/domain/updater_service.dart';

part 'kill_switches_provider.g.dart';

/// Exposes the latest [KillSwitchesModel] from the most recent manifest check.
///
/// Kill switches are sourced from the manifest itself (§7.4), evaluated on
/// every successful check. A killed model is filtered from delegation
/// candidates before scoring ([DelegationEngine]) and from the model-selector
/// UI. If the user's active default is killed, [DefaultModelReconciler] runs
/// and selects a safe fallback.
///
/// keepAlive: switches must survive route changes.
@Riverpod(keepAlive: true)
class KillSwitches extends _$KillSwitches {
  @override
  Stream<KillSwitchesModel> build() {
    return UpdaterService.instance.killSwitchesStream;
  }

  /// Returns the current switches synchronously, defaulting to empty if the
  /// first manifest check has not yet completed.
  KillSwitchesModel get current =>
      state.valueOrNull ?? const KillSwitchesModel.empty();
}

// Remember: `dart run build_runner build --delete-conflicting-outputs`

// lib/features/updater/providers/updater_provider.dart
//
// Phase 11 — OTA Update System
// See CLAUDE_PHASE_11.md §6.4

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:briluxforge/features/delegation/data/models/model_profile.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';
import 'package:briluxforge/features/updater/data/models/update_state.dart';
import 'package:briluxforge/features/updater/domain/updater_service.dart';

part 'updater_provider.g.dart';

// ── Main updater state provider ───────────────────────────────────────────────

/// Exposes the [UpdateState] stream and user-initiated actions.
///
/// keepAlive: the stream must survive route changes and never dispose.
@Riverpod(keepAlive: true)
class Updater extends _$Updater {
  @override
  Stream<UpdateState> build() {
    return UpdaterService.instance.stateStream;
  }

  Future<void> checkNow() => UpdaterService.instance.checkNow();
  Future<void> startInstall() => UpdaterService.instance.startInstall();
  Future<void> cancelStaged() =>
      UpdaterService.instance.cancelStagedUpdate();
}

// ── Brain version provider ────────────────────────────────────────────────────

/// Emits the installed brain version each time a hot-sync completes (§7.1).
///
/// Providers watching this (e.g. [liveModelProfilesProvider]) rebuild
/// automatically, driving the hot-reload of delegation data.
@Riverpod(keepAlive: true)
Stream<int> brainVersion(Ref ref) {
  return UpdaterService.instance.brainVersionStream;
}

// ── Live model profiles provider (§7.2) ──────────────────────────────────────

/// Provides [ModelProfilesData] with the brain path precedence from §7.2:
///   1. `<appSupportDir>/Briluxforge/brain/current.json` — if present and parseable.
///   2. Bundled `assets/brain/model_profiles.json` — always-present fallback.
///
/// Rebuilds whenever [brainVersionProvider] emits (i.e. after every hot-sync).
/// Downstream consumers — [DelegationNotifier], savings calculator, model
/// selector — all rebuild with fresh data without an app restart.
@Riverpod(keepAlive: true)
Future<ModelProfilesData> liveModelProfiles(Ref ref) async {
  // Watching brainVersionProvider causes this provider to rebuild on each
  // brain hot-sync, triggering a fresh file load from the filesystem.
  ref.watch(brainVersionProvider);

  final appSupport = await getApplicationSupportDirectory();
  final brainFile = File(
    p.join(appSupport.path, 'Briluxforge', 'brain', 'current.json'),
  );

  if (brainFile.existsSync()) {
    try {
      final rawJson =
          jsonDecode(brainFile.readAsStringSync()) as Map<String, Object?>;
      return _parseModelProfilesData(rawJson);
    } catch (e) {
      // Corrupted live brain file — fall through to bundled assets.
    }
  }

  // Fallback: bundled assets (always available).
  return ref.watch(modelProfilesProvider.future);
}

// ── Parser (mirrors logic in model_profiles_provider.dart) ───────────────────

ModelProfilesData _parseModelProfilesData(Map<String, Object?> raw) {
  final allModels = (raw['models'] as List<dynamic>)
      .map((e) => ModelProfile.fromJson(e as Map<String, Object?>))
      .toList();

  final benchmark = allModels.where((m) => m.isBenchmark).firstOrNull;
  final routeable = allModels.where((m) => !m.isBenchmark).toList();

  final safeFallbacks = (raw['safeFallbacks'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['gemini-2.0-flash', 'deepseek-chat', 'claude-sonnet-4-20250514'];

  return ModelProfilesData(
    allModels: allModels,
    routeableModels: routeable,
    benchmarkModel: benchmark,
    safeFallbacks: safeFallbacks,
    version: raw['version'] as String? ?? '1.0.0',
  );
}

// Remember: `dart run build_runner build --delete-conflicting-outputs`

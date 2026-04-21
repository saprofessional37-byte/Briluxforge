// lib/features/settings/providers/settings_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:briluxforge/core/utils/logger.dart';
import 'package:briluxforge/features/api_keys/data/models/api_key_model.dart';
import 'package:briluxforge/features/api_keys/providers/api_key_provider.dart';
import 'package:briluxforge/features/delegation/data/engine/default_model_reconciler.dart';
import 'package:briluxforge/features/delegation/providers/model_profiles_provider.dart';
import 'package:briluxforge/services/shared_prefs_provider.dart';

part 'settings_provider.g.dart';

abstract final class _PrefsKeys {
  static const String defaultModelId = 'default_model_id';

  /// Current key — stores one of 'light' | 'dark' | 'system'.
  static const String themeMode = 'settings.themeMode';

  /// Legacy bool key from the pre-ThemeMode era. Read once during migration.
  static const String legacyIsDarkTheme = 'is_dark_theme';

  static const String reconcilerNotification = 'reconciler_notification';
}

ThemeMode _parseThemeMode(String? value) => switch (value) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

String _serializeThemeMode(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark || _ => 'dark',
    };

@immutable
class SettingsState {
  const SettingsState({
    required this.defaultModelId,
    required this.themeMode,
    this.reconcilerNotification,
  });

  final String defaultModelId;
  final ThemeMode themeMode;

  /// Non-null when the DefaultModelReconciler changed the default on this
  /// launch. Shown once on the home screen, then cleared.
  final String? reconcilerNotification;

  SettingsState copyWith({
    String? defaultModelId,
    ThemeMode? themeMode,
    String? reconcilerNotification,
    bool clearNotification = false,
  }) =>
      SettingsState(
        defaultModelId: defaultModelId ?? this.defaultModelId,
        themeMode: themeMode ?? this.themeMode,
        reconcilerNotification: clearNotification
            ? null
            : reconcilerNotification ?? this.reconcilerNotification,
      );
}

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  Future<SettingsState> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);

    // ── Migration from legacy boolean key ──────────────────────────────────
    // If the old key exists, convert its value to the new string key once and
    // remove the old key. This runs on the first launch after the upgrade.
    final legacyBool = prefs.getBool(_PrefsKeys.legacyIsDarkTheme);
    if (legacyBool != null) {
      final migrated = legacyBool ? 'dark' : 'light';
      await prefs.setString(_PrefsKeys.themeMode, migrated);
      await prefs.remove(_PrefsKeys.legacyIsDarkTheme);
    }

    return SettingsState(
      defaultModelId:
          prefs.getString(_PrefsKeys.defaultModelId) ?? 'deepseek-chat',
      themeMode: _parseThemeMode(prefs.getString(_PrefsKeys.themeMode)),
      reconcilerNotification:
          prefs.getString(_PrefsKeys.reconcilerNotification),
    );
  }

  Future<void> setDefaultModelId(String id) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_PrefsKeys.defaultModelId, id);
    state = AsyncData(state.value!.copyWith(defaultModelId: id));
    AppLogger.i('SettingsProvider', 'Default model set to: $id');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_PrefsKeys.themeMode, _serializeThemeMode(mode));
    state = AsyncData(state.value!.copyWith(themeMode: mode));
  }

  Future<void> clearReconcilerNotification() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_PrefsKeys.reconcilerNotification);
    state = AsyncData(state.value!.copyWith(clearNotification: true));
  }
}

/// Runs the [DefaultModelReconciler] once per app launch, immediately after
/// [modelProfilesProvider] and [apiKeyNotifierProvider] are available.
///
/// Must complete before the chat UI becomes interactive (enforced in app.dart).
/// Returns true if the default was changed, false if no change was needed.
@Riverpod(keepAlive: true)
Future<bool> defaultModelReconciler(Ref ref) async {
  final profilesData = await ref.watch(modelProfilesProvider.future);
  final apiKeys = await ref.watch(apiKeyNotifierProvider.future);
  final prefs = await ref.watch(sharedPreferencesProvider.future);

  final currentDefaultId = prefs.getString(_PrefsKeys.defaultModelId);

  final connectedProviders = apiKeys
      .where((k) => k.status == VerificationStatus.verified)
      .map((k) => k.provider)
      .toList();

  const reconciler = DefaultModelReconciler();
  final result = reconciler.reconcile(
    currentDefaultId: currentDefaultId,
    availableModels: profilesData.routeableModels,
    connectedProviders: connectedProviders,
  );

  if (!result.changed) return false;

  await prefs.setString(_PrefsKeys.defaultModelId, result.newModelId);
  if (result.notificationMessage != null) {
    await prefs.setString(
      _PrefsKeys.reconcilerNotification,
      result.notificationMessage!,
    );
  }

  ref.invalidate(settingsNotifierProvider);

  AppLogger.w('Reconciler',
      'Default changed to ${result.newModelId} (reason: ${result.reason?.name}).');

  return true;
}

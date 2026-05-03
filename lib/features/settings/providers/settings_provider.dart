// lib/features/settings/providers/settings_provider.dart
// Phase 13 §13.6: themeMode field deprecated and frozen at ThemeMode.dark.
// setThemeMode is a no-op. The persisted SharedPreferences key remains
// readable so old installs upgrading to this build do not crash.
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

  /// Legacy theme key — readable for backwards compat but never written.
  // ignore: unused_field
  static const String themeMode = 'settings.themeMode';

  /// Legacy bool key from the pre-ThemeMode era. Read once during migration.
  static const String legacyIsDarkTheme = 'is_dark_theme';

  static const String reconcilerNotification = 'reconciler_notification';
}

@immutable
class SettingsState {
  const SettingsState({
    required this.defaultModelId,
    @Deprecated('Phase 13: locked to dark. Use AppTheme.darkTheme directly.')
    this.themeMode = ThemeMode.dark,
    this.reconcilerNotification,
  });

  final String defaultModelId;

  @Deprecated('Phase 13: locked to dark. Use AppTheme.darkTheme directly.')
  final ThemeMode themeMode;

  /// Non-null when the DefaultModelReconciler changed the default on this
  /// launch. Shown once on the home screen, then cleared.
  final String? reconcilerNotification;

  SettingsState copyWith({
    String? defaultModelId,
    // ignore: deprecated_member_use_from_same_package
    ThemeMode? themeMode,
    String? reconcilerNotification,
    bool clearNotification = false,
  }) =>
      SettingsState(
        defaultModelId: defaultModelId ?? this.defaultModelId,
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

    // Migration from legacy boolean key (one-time, forward-compat).
    final legacyBool = prefs.getBool(_PrefsKeys.legacyIsDarkTheme);
    if (legacyBool != null) {
      await prefs.remove(_PrefsKeys.legacyIsDarkTheme);
    }

    return SettingsState(
      defaultModelId:
          prefs.getString(_PrefsKeys.defaultModelId) ?? 'deepseek-chat',
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

  /// No-op: theme is locked to dark in Phase 13.
  @Deprecated('Phase 13: theme is locked to dark. Call has no effect.')
  Future<void> setThemeMode(ThemeMode mode) async {
    AppLogger.w('Settings',
        'setThemeMode called but theme is locked to dark in Phase 13');
  }

  Future<void> clearReconcilerNotification() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_PrefsKeys.reconcilerNotification);
    state = AsyncData(state.value!.copyWith(clearNotification: true));
  }
}

/// Runs the [DefaultModelReconciler] once per app launch.
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

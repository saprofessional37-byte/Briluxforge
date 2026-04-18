// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$defaultModelReconcilerHash() =>
    r'8dd112001e01255a635fa023cbb08824cc97a916';

/// Runs the [DefaultModelReconciler] once per app launch, immediately after
/// [modelProfilesProvider] and [apiKeyNotifierProvider] are available.
///
/// Must complete before the chat UI becomes interactive (enforced in app.dart).
/// Returns true if the default was changed, false if no change was needed.
///
/// Copied from [defaultModelReconciler].
@ProviderFor(defaultModelReconciler)
final defaultModelReconcilerProvider = FutureProvider<bool>.internal(
  defaultModelReconciler,
  name: r'defaultModelReconcilerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$defaultModelReconcilerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DefaultModelReconcilerRef = FutureProviderRef<bool>;
String _$settingsNotifierHash() => r'c4595521703cf6db20dfd745eb3a2719de7422d1';

/// See also [SettingsNotifier].
@ProviderFor(SettingsNotifier)
final settingsNotifierProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>.internal(
      SettingsNotifier.new,
      name: r'settingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SettingsNotifier = AsyncNotifier<SettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

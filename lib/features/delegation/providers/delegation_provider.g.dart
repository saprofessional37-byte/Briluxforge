// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectedProvidersHash() =>
    r'399b81cd05b81498f37eabe99c2078cdc8b577c6';

/// Convenience provider: list of provider IDs that have verified API keys.
///
/// Copied from [connectedProviders].
@ProviderFor(connectedProviders)
final connectedProvidersProvider = AutoDisposeProvider<List<String>>.internal(
  connectedProviders,
  name: r'connectedProvidersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectedProvidersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectedProvidersRef = AutoDisposeProviderRef<List<String>>;
String _$delegationNotifierHash() =>
    r'0d9981b2dbef4da4e9b87818d367669076faa616';

/// Manages the active delegation result for the current message being composed.
///
/// Flow for the chat screen:
///   1. Call [tryLayer1] — returns a result if confident, null if uncertain.
///   2. If null, show [DelegationFailureDialog].
///   3. Based on user choice call [resolveDefault] or [resolveWithAI].
///   4. Use the returned [DelegationResult] for the API call.
///   5. Call [applyManualOverride] if the user changes the model via the badge.
///   6. Call [clearResult] when starting a new message.
///
/// Copied from [DelegationNotifier].
@ProviderFor(DelegationNotifier)
final delegationNotifierProvider =
    AutoDisposeNotifierProvider<DelegationNotifier, DelegationResult?>.internal(
      DelegationNotifier.new,
      name: r'delegationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$delegationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DelegationNotifier = AutoDisposeNotifier<DelegationResult?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

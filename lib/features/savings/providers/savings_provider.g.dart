// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$savingsNotifierHash() => r'387756ebe281f93cf77b916bf27c610231f48b11';

/// Manages the savings state and exposes a [SavingsSnapshot] derived from
/// locally-stored per-model token counts and current model pricing.
///
/// Kept alive for the lifetime of the app — savings data must never be dropped.
///
/// Copied from [SavingsNotifier].
@ProviderFor(SavingsNotifier)
final savingsNotifierProvider =
    AsyncNotifierProvider<SavingsNotifier, SavingsSnapshot>.internal(
      SavingsNotifier.new,
      name: r'savingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$savingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SavingsNotifier = AsyncNotifier<SavingsSnapshot>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

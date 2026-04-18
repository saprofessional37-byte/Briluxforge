// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiKeyRepositoryHash() => r'a6bc6accb13a9f14dd38cbc6492c0a4bc3539512';

/// See also [apiKeyRepository].
@ProviderFor(apiKeyRepository)
final apiKeyRepositoryProvider =
    AutoDisposeFutureProvider<ApiKeyRepository>.internal(
      apiKeyRepository,
      name: r'apiKeyRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$apiKeyRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApiKeyRepositoryRef = AutoDisposeFutureProviderRef<ApiKeyRepository>;
String _$apiKeyNotifierHash() => r'c80551281569799b64bea9133520ca0aaecf208e';

/// See also [ApiKeyNotifier].
@ProviderFor(ApiKeyNotifier)
final apiKeyNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      ApiKeyNotifier,
      List<ApiKeyModel>
    >.internal(
      ApiKeyNotifier.new,
      name: r'apiKeyNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$apiKeyNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ApiKeyNotifier = AutoDisposeAsyncNotifier<List<ApiKeyModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

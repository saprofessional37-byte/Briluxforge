// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'license_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gumroadRepositoryHash() => r'828079cb1e210e5e6fcdf1d38065f978fa358c65';

/// See also [gumroadRepository].
@ProviderFor(gumroadRepository)
final gumroadRepositoryProvider =
    AutoDisposeProvider<GumroadRepository>.internal(
      gumroadRepository,
      name: r'gumroadRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$gumroadRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GumroadRepositoryRef = AutoDisposeProviderRef<GumroadRepository>;
String _$licenseNotifierHash() => r'23309b0971f5d3a83422236ba1a678f209b69e25';

/// See also [LicenseNotifier].
@ProviderFor(LicenseNotifier)
final licenseNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LicenseNotifier, LicenseModel>.internal(
      LicenseNotifier.new,
      name: r'licenseNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$licenseNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LicenseNotifier = AutoDisposeAsyncNotifier<LicenseModel>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

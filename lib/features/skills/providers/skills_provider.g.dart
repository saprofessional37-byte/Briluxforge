// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skills_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allSkillsHash() => r'fc5fdc66c933f5e8365bf937d0cd744620df03fc';

/// See also [allSkills].
@ProviderFor(allSkills)
final allSkillsProvider = AutoDisposeStreamProvider<List<SkillModel>>.internal(
  allSkills,
  name: r'allSkillsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allSkillsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllSkillsRef = AutoDisposeStreamProviderRef<List<SkillModel>>;
String _$enabledSkillsHash() => r'7747ce6cf87d9a773490efad0bf6a93820cd1625';

/// See also [enabledSkills].
@ProviderFor(enabledSkills)
final enabledSkillsProvider = AutoDisposeProvider<List<SkillModel>>.internal(
  enabledSkills,
  name: r'enabledSkillsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$enabledSkillsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EnabledSkillsRef = AutoDisposeProviderRef<List<SkillModel>>;
String _$skillsNotifierHash() => r'25797296bcb36b20961c59f29b059edfc471c674';

/// See also [SkillsNotifier].
@ProviderFor(SkillsNotifier)
final skillsNotifierProvider =
    NotifierProvider<SkillsNotifier, SkillsState>.internal(
      SkillsNotifier.new,
      name: r'skillsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$skillsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SkillsNotifier = Notifier<SkillsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

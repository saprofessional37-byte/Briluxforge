// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_conversation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$activeConversationNotifierHash() =>
    r'9f7ee380315ae879238371deee25c8fa6486eeb0';

/// Holds the ID of the currently open conversation. Null = empty state (no chat open).
///
/// Copied from [ActiveConversationNotifier].
@ProviderFor(ActiveConversationNotifier)
final activeConversationNotifierProvider =
    NotifierProvider<ActiveConversationNotifier, String?>.internal(
      ActiveConversationNotifier.new,
      name: r'activeConversationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeConversationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveConversationNotifier = Notifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

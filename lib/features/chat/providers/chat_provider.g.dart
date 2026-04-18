// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$conversationsHash() => r'7a8daee0ce02c393a5091d84c05839912cbb660b';

/// See also [conversations].
@ProviderFor(conversations)
final conversationsProvider =
    AutoDisposeStreamProvider<List<ConversationModel>>.internal(
      conversations,
      name: r'conversationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationsRef =
    AutoDisposeStreamProviderRef<List<ConversationModel>>;
String _$chatNotifierHash() => r'942acbf95b7e7fa0da82aa6e723f3c8120447d6c';

/// See also [ChatNotifier].
@ProviderFor(ChatNotifier)
final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>.internal(
  ChatNotifier.new,
  name: r'chatNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ChatNotifier = Notifier<ChatState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

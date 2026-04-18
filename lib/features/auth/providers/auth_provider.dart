// lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:briluxforge/features/auth/data/models/user_model.dart';
import 'package:briluxforge/features/auth/data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

/// Streams the current signed-in user. Null means no user is logged in.
/// State type: AsyncValue<UserModel?>
@riverpod
Stream<UserModel?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

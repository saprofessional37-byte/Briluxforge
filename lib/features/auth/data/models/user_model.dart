// lib/features/auth/data/models/user_model.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromFirebaseUser(User user) => UserModel(
        uid: user.uid,
        email: user.email ?? '',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      );

  final String uid;
  final String email;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

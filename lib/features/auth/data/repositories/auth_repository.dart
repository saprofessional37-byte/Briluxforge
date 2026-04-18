// lib/features/auth/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:briluxforge/core/errors/app_exception.dart';
import 'package:briluxforge/features/auth/data/models/user_model.dart';

/// The ONLY file that imports firebase_auth.
/// All Firebase Auth operations are channelled through this class.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().map(
        (user) => user == null ? null : UserModel.fromFirebaseUser(user),
      );

  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : UserModel.fromFirebaseUser(user);
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<void> logOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' =>
        'This email is already registered. Try logging in instead.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'user-not-found' =>
        'No account found with this email. Check the address or sign up.',
      'invalid-email' => 'Please enter a valid email address.',
      'weak-password' =>
        'Password is too weak. Use at least 6 characters.',
      'network-request-failed' =>
        'Connection error. Check your internet and try again.',
      'too-many-requests' =>
        'Too many failed attempts. Please wait a moment and try again.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'invalid-credential' =>
        'Email or password is incorrect. Please try again.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parent_auth_remote_data_source.dart';
import '../data/parent_auth_repository.dart';
import 'parent_auth_state.dart';

final authRepositoryProvider = Provider<ParentAuthRepository>((ref) {
  return ParentAuthRepository(
    ParentAuthRemoteDataSource(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    ),
  );
});

final parentAuthControllerProvider =
    StateNotifierProvider<ParentAuthController, ParentAuthState>(
  (ref) {
    return ParentAuthController(
      ref.read(authRepositoryProvider),
    );
  },
);

class ParentAuthController extends StateNotifier<ParentAuthState> {
  final ParentAuthRepository repository;

  ParentAuthController(this.repository)
      : super(const ParentAuthState());

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      success: false,
      clearError: true,
    );

    try {
      await repository.signup(
        name: name,
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        success: true,
        clearError: true,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: _getFirebaseErrorMessage(e),
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: 'Unable to create your account. Please try again.',
      );

      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      success: false,
      clearError: true,
    );

    try {
      await repository.login(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        success: true,
        clearError: true,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: _getFirebaseErrorMessage(e),
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: 'Unable to login. Please try again.',
      );

      return false;
    }
  }

  /// Sends a Firebase password reset email.
  Future<bool> resetPassword({
    required String email,
  }) async {
    state = state.copyWith(
      isLoading: true,
      success: false,
      clearError: true,
    );

    try {
      await repository.resetPassword(email: email);

      state = state.copyWith(
        isLoading: false,
        success: true,
        clearError: true,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: _getFirebaseErrorMessage(e),
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: 'Unable to send the reset email. Please try again.',
      );

      return false;
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();

      state = const ParentAuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error: 'Unable to logout. Please try again.',
      );
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid. Please check it.';

      case 'user-not-found':
        return 'No account was found with this email address.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'The email address or password is incorrect.';

      case 'email-already-in-use':
        return 'This email address is already registered.';

      case 'weak-password':
        return 'Your password is too weak. Use at least 6 characters.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled for this project.';

      case 'requires-recent-login':
        return 'Please login again and retry this operation.';

      default:
        return 'Authentication failed. Please check your details and try again.';
    }
  }
}

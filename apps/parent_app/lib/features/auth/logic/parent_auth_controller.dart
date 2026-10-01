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
        error: 'Account create karte waqt error aa gaya.',
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
        error: 'Login ke waqt error aa gaya.',
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
        error: 'Logout nahi ho saka.',
      );
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email address valid nahi hai.';

      case 'user-not-found':
        return 'Is email se koi account nahi mila.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ya password ghalat hai.';

      case 'email-already-in-use':
        return 'Ye email pehle se registered hai.';

      case 'weak-password':
        return 'Password bohat weak hai. Kam az kam 6 characters use karein.';

      case 'network-request-failed':
        return 'Internet connection check karein.';

      case 'too-many-requests':
        return 'Bohat zyada attempts ho gaye hain. Kuch dair baad dobara try karein.';

      default:
        return e.message ?? 'Authentication error aa gaya.';
    }
  }
}
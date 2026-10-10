
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/staff_auth_repository.dart';
import 'staff_auth_state.dart';

final staffAuthControllerProvider =
    NotifierProvider<StaffAuthController, StaffAuthState>(
  StaffAuthController.new,
);

class StaffAuthController extends Notifier<StaffAuthState> {
  @override
  StaffAuthState build() => const StaffAuthState();

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final profile = await ref.read(staffAuthRepositoryProvider).signIn(
            email: email,
            password: password,
          );

      state = StaffAuthState(profile: profile);
      return true;
    } catch (error) {
      state = StaffAuthState(
        errorMessage: _friendlyError(error),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await ref.read(staffAuthRepositoryProvider).signOut();
      state = const StaffAuthState();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Email ya password ghalat hai.';
    }

    if (message.contains('network-request-failed')) {
      return 'Network connection check karein.';
    }

    if (message.contains('permission-denied')) {
      return 'Staff profile access nahi ho saka. Firestore Rules check karein.';
    }

    if (message.contains('email-already-in-use')) {
      return 'Yeh email pehle se registered hai.';
    }

    return message.replaceFirst('Exception: ', '');
  }
}

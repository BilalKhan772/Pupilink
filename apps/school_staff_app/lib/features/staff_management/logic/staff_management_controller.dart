
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/staff_repository.dart';
import 'staff_management_state.dart';

final staffManagementControllerProvider =
    NotifierProvider<StaffManagementController, StaffManagementState>(
  StaffManagementController.new,
);

class StaffManagementController extends Notifier<StaffManagementState> {
  @override
  StaffManagementState build() => const StaffManagementState();

  Future<void> loadStaff({required String schoolId}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final staff = await ref.read(staffRepositoryProvider).getStaff(
            schoolId: schoolId,
          );

      state = state.copyWith(isLoading: false, staff: staff);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<bool> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
  }) async {
    if (role == 'schoolAdmin') {
      state = state.copyWith(
        errorMessage: 'Is form se School Admin account create nahi hota.',
        clearSuccess: true,
      );
      return false;
    }

    if (schoolId.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'School ID available nahi hai.',
        clearSuccess: true,
      );
      return false;
    }

    state = state.copyWith(
      isCreating: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await ref.read(staffRepositoryProvider).createStaff(
            name: name.trim(),
            email: email.trim(),
            password: password,
            role: role,
          );

      state = state.copyWith(
        isCreating: false,
        successMessage: 'Staff account successfully create ho gaya.',
      );

      await loadStaff(schoolId: schoolId);

      state = state.copyWith(
        isCreating: false,
        successMessage: 'Staff account successfully create ho gaya.',
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: _message(error),
        clearSuccess: true,
      );
      return false;
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}

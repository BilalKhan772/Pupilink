
class StaffManagementState {
  const StaffManagementState({
    this.isLoading = false,
    this.isCreating = false,
    this.staff = const [],
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isCreating;
  final List<Map<String, dynamic>> staff;
  final String? errorMessage;
  final String? successMessage;

  StaffManagementState copyWith({
    bool? isLoading,
    bool? isCreating,
    List<Map<String, dynamic>>? staff,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return StaffManagementState(
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      staff: staff ?? this.staff,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

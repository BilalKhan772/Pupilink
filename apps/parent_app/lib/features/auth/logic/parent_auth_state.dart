class ParentAuthState {
  final bool isLoading;
  final String? error;
  final bool success;

  const ParentAuthState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  ParentAuthState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
    bool clearError = false,
  }) {
    return ParentAuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      success: success ?? this.success,
    );
  }
}
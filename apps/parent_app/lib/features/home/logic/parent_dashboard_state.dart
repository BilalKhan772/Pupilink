class ParentDashboardState {
  final bool isLoading;
  final String? parentEmail;
  final String? error;

  const ParentDashboardState({
    this.isLoading = false,
    this.parentEmail,
    this.error,
  });

  ParentDashboardState copyWith({
    bool? isLoading,
    String? parentEmail,
    String? error,
    bool clearError = false,
  }) {
    return ParentDashboardState(
      isLoading: isLoading ?? this.isLoading,
      parentEmail: parentEmail ?? this.parentEmail,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
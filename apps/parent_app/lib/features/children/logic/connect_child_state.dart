class ConnectChildState {
  final bool isLoading;
  final bool success;
  final String? error;
  final String? linkId;
  final String? studentId;
  final String? studentName;

  const ConnectChildState({
    this.isLoading = false,
    this.success = false,
    this.error,
    this.linkId,
    this.studentId,
    this.studentName,
  });

  ConnectChildState copyWith({
    bool? isLoading,
    bool? success,
    String? error,
    String? linkId,
    String? studentId,
    String? studentName,
    bool clearError = false,
  }) {
    return ConnectChildState(
      isLoading:
          isLoading ?? this.isLoading,
      success:
          success ?? this.success,
      error: clearError
          ? null
          : (error ?? this.error),
      linkId:
          linkId ?? this.linkId,
      studentId:
          studentId ?? this.studentId,
      studentName:
          studentName ?? this.studentName,
    );
  }
}
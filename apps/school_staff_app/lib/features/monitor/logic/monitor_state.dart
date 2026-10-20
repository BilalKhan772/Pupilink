
class MonitorState {
  const MonitorState({
    this.isLoading = false,
    this.isSaving = false,
    this.monitors = const [],
    this.sections = const [],
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final List<Map<String, dynamic>> monitors;
  final List<Map<String, dynamic>> sections;
  final String? errorMessage;
  final String? successMessage;

  MonitorState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<Map<String, dynamic>>? monitors,
    List<Map<String, dynamic>>? sections,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return MonitorState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      monitors: monitors ?? this.monitors,
      sections: sections ?? this.sections,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

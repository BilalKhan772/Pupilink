
class HomeworkState {
  const HomeworkState({
    this.isLoading = false,
    this.isSaving = false,
    this.schoolId = '',
    this.classId = '',
    this.className = '',
    this.sectionId = '',
    this.sectionName = '',
    this.monitorName = '',
    this.recentHomework = const [],
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final String schoolId;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String monitorName;
  final List<Map<String, dynamic>> recentHomework;
  final String? errorMessage;
  final String? successMessage;

  bool get hasAssignment =>
      schoolId.isNotEmpty && sectionId.isNotEmpty;

  HomeworkState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? schoolId,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    String? monitorName,
    List<Map<String, dynamic>>? recentHomework,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return HomeworkState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      schoolId: schoolId ?? this.schoolId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      monitorName: monitorName ?? this.monitorName,
      recentHomework: recentHomework ?? this.recentHomework,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

import 'package:school_models/school_models.dart';

class AttendanceState {
  const AttendanceState({
    this.isLoading = false,
    this.isSaving = false,
    this.students = const [],
    this.records = const [],
    this.sessions = const [],
    this.studentStatuses = const {},
    this.selectedDate,
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final List<Student> students;
  final List<AttendanceRecord> records;
  final List<AttendanceSession> sessions;
  final Map<String, String> studentStatuses;
  final DateTime? selectedDate;
  final String? errorMessage;
  final String? successMessage;

  AttendanceState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<Student>? students,
    List<AttendanceRecord>? records,
    List<AttendanceSession>? sessions,
    Map<String, String>? studentStatuses,
    DateTime? selectedDate,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      students: students ?? this.students,
      records: records ?? this.records,
      sessions: sessions ?? this.sessions,
      studentStatuses: studentStatuses ?? this.studentStatuses,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

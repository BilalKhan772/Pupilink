
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../data/attendance_summary_repository.dart';

class AttendanceSummaryState {
  const AttendanceSummaryState({
    this.isLoading = false,
    this.summaries = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<AttendanceSummary> summaries;
  final String? errorMessage;

  AttendanceSummaryState copyWith({
    bool? isLoading,
    List<AttendanceSummary>? summaries,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AttendanceSummaryState(
      isLoading: isLoading ?? this.isLoading,
      summaries: summaries ?? this.summaries,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final attendanceSummaryControllerProvider =
    NotifierProvider<AttendanceSummaryController, AttendanceSummaryState>(
  AttendanceSummaryController.new,
);

class AttendanceSummaryController
    extends Notifier<AttendanceSummaryState> {
  late AttendanceSummaryRepository _repository;

  @override
  AttendanceSummaryState build() {
    _repository = ref.read(attendanceSummaryRepositoryProvider);
    return const AttendanceSummaryState();
  }

  Future<void> loadSummaries({
    required String schoolId,
    String? studentId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final summaries = await _repository.getSummaries(
        schoolId: schoolId,
        studentId: studentId,
      );

      state = state.copyWith(
        isLoading: false,
        summaries: summaries,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Attendance summary load nahi hui: $error',
      );
    }
  }
}

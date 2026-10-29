import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parent_results_repository.dart';
import 'parent_results_state.dart';

final parentResultsRepositoryProvider =
    Provider<ParentResultsRepository>((ref) {
  return ParentResultsRepository();
});

final parentResultsControllerProvider =
    StateNotifierProvider<ParentResultsController, ParentResultsState>(
  (ref) {
    return ParentResultsController(
      ref.read(parentResultsRepositoryProvider),
    );
  },
);

class ParentResultsController extends StateNotifier<ParentResultsState> {
  final ParentResultsRepository repository;

  ParentResultsController(this.repository) : super(const ParentResultsState());

  Future<void> loadResults({
    required String studentId,
    required String schoolId,
  }) async {
    if (studentId.trim().isEmpty || schoolId.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Student ID or School ID is missing.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      // Temporary results exclude expired records and are scope-validated.
      final recordsFuture = repository.getResults(
        studentId: studentId,
        schoolId: schoolId,
      );

      // Permanent averages remain available after individual tests expire.
      final subjectAveragesFuture = repository.getSubjectAverages(
        studentId: studentId,
        schoolId: schoolId,
      );

      final studentAverageFuture = repository.getStudentAverage(
        studentId: studentId,
        schoolId: schoolId,
      );

      final results = await Future.wait<dynamic>([
        recordsFuture,
        subjectAveragesFuture,
        studentAverageFuture,
      ]);

      state = state.copyWith(
        isLoading: false,
        records: results[0] as List<Map<String, dynamic>>,
        subjectAverages: results[1] as List<Map<String, dynamic>>,
        studentAverage: results[2] as Map<String, dynamic>?,
        clearStudentAverage: results[2] == null,
        clearError: true,
      );
    } catch (error, stackTrace) {
      // Keep previous data if a refresh fails; the screen displays the error.
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load results and saved averages. Please try again.',
      );

      // Useful for local development diagnostics.
      // ignore: avoid_print
      print('Parent results loading error: $error');
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}

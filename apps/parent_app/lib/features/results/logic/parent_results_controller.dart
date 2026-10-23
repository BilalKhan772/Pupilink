
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parent_results_repository.dart';
import 'parent_results_state.dart';

final parentResultsRepositoryProvider =
    Provider<ParentResultsRepository>((ref) {
  return ParentResultsRepository();
});

final parentResultsControllerProvider =
    StateNotifierProvider<
        ParentResultsController,
        ParentResultsState>(
  (ref) {
    return ParentResultsController(
      ref.read(parentResultsRepositoryProvider),
    );
  },
);

class ParentResultsController
    extends StateNotifier<ParentResultsState> {
  final ParentResultsRepository repository;

  ParentResultsController(this.repository)
      : super(const ParentResultsState());

  Future<void> loadResults({
    required String studentId,
    required String schoolId,
  }) async {
    if (studentId.isEmpty || schoolId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Student ID ya School ID available nahi hai.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      // Load temporary, unexpired test results.
      final recordsFuture = repository.getResults(
        studentId: studentId,
      );

      // Load permanent subject averages.
      final subjectAveragesFuture =
          repository.getSubjectAverages(
        studentId: studentId,
        schoolId: schoolId,
      );

      // Load permanent overall average.
      final studentAverageFuture =
          repository.getStudentAverage(
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
        subjectAverages:
            results[1] as List<Map<String, dynamic>>,
        studentAverage:
            results[2] as Map<String, dynamic>?,
        clearStudentAverage: results[2] == null,
        clearError: true,
      );
    } catch (e, stackTrace) {
      // Keep previously loaded data if refreshing fails.
      state = state.copyWith(
        isLoading: false,
        error: 'Results aur averages load nahi ho sake.',
      );

      // Useful for debugging in the development console.
      print('Parent results loading error: $e');
      print(stackTrace);
    }
  }
}

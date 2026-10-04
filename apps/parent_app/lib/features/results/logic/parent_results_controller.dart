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
      ref.read(
        parentResultsRepositoryProvider,
      ),
    );
  },
);

class ParentResultsController
    extends StateNotifier<ParentResultsState> {
  final ParentResultsRepository repository;

  ParentResultsController(
    this.repository,
  ) : super(
          const ParentResultsState(),
        );

  Future<void> loadResults({
    required String studentId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final records =
          await repository.getResults(
        studentId: studentId,
      );

      state = state.copyWith(
        isLoading: false,
        records: records,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Results load nahi ho sake.',
      );
    }
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/upcoming_tests_repository.dart';
import 'upcoming_tests_state.dart';

final upcomingTestsRepositoryProvider =
    Provider<UpcomingTestsRepository>((ref) {
  return UpcomingTestsRepository();
});

final upcomingTestsControllerProvider =
    StateNotifierProvider<
        UpcomingTestsController,
        UpcomingTestsState>(
  (ref) {
    return UpcomingTestsController(
      ref.read(
        upcomingTestsRepositoryProvider,
      ),
    );
  },
);

class UpcomingTestsController
    extends StateNotifier<UpcomingTestsState> {
  final UpcomingTestsRepository repository;

  UpcomingTestsController(
    this.repository,
  ) : super(
          const UpcomingTestsState(),
        );

  Future<void> loadUpcomingTests({
    required String studentId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final records =
          await repository.getUpcomingTests(
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
            'Upcoming tests load nahi ho sake.',
      );
    }
  }

  Future<void> refresh({
    required String studentId,
  }) async {
    await loadUpcomingTests(
      studentId: studentId,
    );
  }
}
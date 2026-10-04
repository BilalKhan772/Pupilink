import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parent_homework_repository.dart';
import 'parent_homework_state.dart';

final parentHomeworkRepositoryProvider =
    Provider<ParentHomeworkRepository>((ref) {
  return ParentHomeworkRepository();
});

final parentHomeworkControllerProvider =
    StateNotifierProvider<
        ParentHomeworkController,
        ParentHomeworkState>(
  (ref) {
    return ParentHomeworkController(
      ref.read(
        parentHomeworkRepositoryProvider,
      ),
    );
  },
);

class ParentHomeworkController
    extends StateNotifier<ParentHomeworkState> {
  final ParentHomeworkRepository repository;

  ParentHomeworkController(
    this.repository,
  ) : super(
          const ParentHomeworkState(),
        );

  Future<void> loadHomework({
    required String studentId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final records =
          await repository.getHomework(
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
            'Homework load nahi ho saka.',
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(
      selectedFilter: filter,
    );
  }

  void clearFilter() {
    state = state.copyWith(
      selectedFilter: 'All',
    );
  }
}
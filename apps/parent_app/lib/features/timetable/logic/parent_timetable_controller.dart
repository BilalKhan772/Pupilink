import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parent_timetable_repository.dart';
import 'parent_timetable_state.dart';

final parentTimetableRepositoryProvider =
    Provider<ParentTimetableRepository>((ref) {
  return ParentTimetableRepository();
});

final parentTimetableControllerProvider =
    StateNotifierProvider<
        ParentTimetableController,
        ParentTimetableState>(
  (ref) {
    return ParentTimetableController(
      ref.read(
        parentTimetableRepositoryProvider,
      ),
    );
  },
);

class ParentTimetableController
    extends StateNotifier<ParentTimetableState> {
  final ParentTimetableRepository repository;

  ParentTimetableController(
    this.repository,
  ) : super(
          const ParentTimetableState(),
        );

  Future<void> loadTimetable({
    required String studentId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final records =
          await repository.getTimetable(
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
            'Timetable load nahi ho saka.',
      );
    }
  }

  void selectDay(String day) {
    state = state.copyWith(
      selectedDay: day,
    );
  }
}
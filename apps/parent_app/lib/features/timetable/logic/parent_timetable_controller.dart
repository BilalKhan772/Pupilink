
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
      ref.read(parentTimetableRepositoryProvider),
    );
  },
);

class ParentTimetableController
    extends StateNotifier<ParentTimetableState> {
  ParentTimetableController(this.repository)
      : super(const ParentTimetableState());

  final ParentTimetableRepository repository;

  Future<void> loadTimetable({
    required String schoolId,
    required String sectionId,
  }) async {
    if (schoolId.trim().isEmpty || sectionId.trim().isEmpty) {
      state = state.copyWith(
        isLoading: false,
        error: 'Student ka school ya section ID available nahi hai.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final records = await repository.getTimetable(
        schoolId: schoolId,
        sectionId: sectionId,
      );

      state = state.copyWith(
        isLoading: false,
        records: records,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Timetable load nahi ho saka: $e',
      );
    }
  }

  void selectDay(String day) {
    state = state.copyWith(selectedDay: day);
  }
}

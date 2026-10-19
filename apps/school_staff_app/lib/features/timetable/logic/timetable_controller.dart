
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/timetable_repository.dart';
import 'timetable_state.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository();
});

final timetableControllerProvider =
    NotifierProvider<TimetableController, TimetableState>(
  TimetableController.new,
);

class TimetableController extends Notifier<TimetableState> {
  late final TimetableRepository repository;

  @override
  TimetableState build() {
    repository = ref.read(timetableRepositoryProvider);
    return const TimetableState();
  }

  Future<void> loadTimetable({
    required String schoolId,
    required String sectionId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
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
    state = state.copyWith(
      selectedDay: day,
      clearError: true,
    );
  }

  Future<bool> saveEntry({
    String? entryId,
    required String schoolId,
    required String classId,
    required String className,
    required String sectionId,
    required String sectionName,
    required String day,
    required String subject,
    required String teacherName,
    required String startTime,
    required String endTime,
    String room = '',
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.saveTimetableEntry(
        entryId: entryId,
        schoolId: schoolId,
        classId: classId,
        className: className,
        sectionId: sectionId,
        sectionName: sectionName,
        day: day,
        subject: subject,
        teacherName: teacherName,
        startTime: startTime,
        endTime: endTime,
        room: room,
      );

      await loadTimetable(
        schoolId: schoolId,
        sectionId: sectionId,
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Timetable successfully save ho gaya.',
        clearError: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    }
  }

  Future<bool> deleteEntry({
    required String entryId,
    required String schoolId,
    required String sectionId,
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await repository.deleteTimetableEntry(
        entryId: entryId,
        schoolId: schoolId,
        sectionId: sectionId,
      );

      await loadTimetable(
        schoolId: schoolId,
        sectionId: sectionId,
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Timetable entry delete ho gayi.',
        clearError: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    }
  }
}


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

  // ---------------------------------------------------------------------------
  // Load timetable
  // ---------------------------------------------------------------------------

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
        error: 'Unable to load timetable. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Select weekday
  // ---------------------------------------------------------------------------

  void selectDay(String day) {
    state = state.copyWith(
      selectedDay: day,
      clearError: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Save timetable entry
  // ---------------------------------------------------------------------------

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
        successMessage: 'Timetable saved successfully.',
        clearError: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _getReadableError(
          e,
          fallback: 'Unable to save timetable. Please try again.',
        ),
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete timetable entry
  // ---------------------------------------------------------------------------

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
        successMessage: 'Timetable period deleted successfully.',
        clearError: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _getReadableError(
          e,
          fallback: 'Unable to delete timetable period. Please try again.',
        ),
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // User-friendly error messages
  // ---------------------------------------------------------------------------

  String _getReadableError(
    Object error, {
    required String fallback,
  }) {
    if (error is ArgumentError) {
      final message = error.message;

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (error is Exception) {
      final message = error
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Bad state: ', '')
          .trim();

      if (message.isNotEmpty &&
          !message.startsWith('Instance of')) {
        return message;
      }
    }

    return fallback;
  }
}

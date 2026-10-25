import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/parent_attendance_repository.dart';
import 'parent_attendance_state.dart';
import 'package:flutter/foundation.dart';

final parentAttendanceRepositoryProvider =
    Provider<ParentAttendanceRepository>((ref) {
  return ParentAttendanceRepository();
});

final parentAttendanceControllerProvider =
    StateNotifierProvider<
        ParentAttendanceController,
        ParentAttendanceState>(
  (ref) {
    return ParentAttendanceController(
      ref.read(parentAttendanceRepositoryProvider),
    );
  },
);

class ParentAttendanceController
    extends StateNotifier<ParentAttendanceState> {
  final ParentAttendanceRepository repository;

  ParentAttendanceController(this.repository)
      : super(const ParentAttendanceState());

  Future<void> loadAttendance({
    required String studentId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final records = await repository.getAttendance(
        studentId: studentId,
      );

      state = state.copyWith(
        isLoading: false,
        records: records,
        clearError: true,
      );
    } catch (e, stackTrace) {
      // Error ko debug console mein bhi show karein.
      debugPrint('Attendance load error: $e');
      debugPrintStack(stackTrace: stackTrace);

      state = state.copyWith(
        isLoading: false,
        error: 'Attendance load nahi ho saki. '
            'Internet aur Firestore permissions check karein.',
      );
    }
  }
}
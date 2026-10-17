import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../students/data/students_repository.dart';
import '../data/attendance_repository.dart';
import 'attendance_state.dart';

final attendanceControllerProvider =
    NotifierProvider<AttendanceController, AttendanceState>(
  AttendanceController.new,
);

class AttendanceController extends Notifier<AttendanceState> {
  @override
  AttendanceState build() => AttendanceState(selectedDate: DateTime.now());

  Future<void> loadAttendance({
    required String schoolId,
    required String classId,
    required String sectionId,
    DateTime? date,
  }) async {
    final chosenDate = date ?? state.selectedDate ?? DateTime.now();
    final day = DateTime(chosenDate.year, chosenDate.month, chosenDate.day);

    state = state.copyWith(
      isLoading: true,
      selectedDate: day,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final students = await ref.read(studentsRepositoryProvider).getStudents(
        schoolId,
        sectionId: sectionId,
      );
      final repository = ref.read(attendanceRepositoryProvider);
      final records = await repository.getRecords(
        schoolId: schoolId,
        sectionId: sectionId,
        date: day,
      );
      final sessions = await repository.getSessions(
        schoolId: schoolId,
        sectionId: sectionId,
      );

      final statuses = <String, String>{};
      for (final student in students) {
        statuses[student.id] = 'present';
      }
      for (final record in records) {
        if (statuses.containsKey(record.studentId)) {
          statuses[record.studentId] = record.status.toLowerCase();
        }
      }

      state = state.copyWith(
        isLoading: false,
        students: students,
        records: records,
        sessions: sessions,
        studentStatuses: statuses,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Attendance load nahi ho saki: $error',
      );
    }
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
      clearError: true,
      clearSuccess: true,
    );
  }

  void setStudentStatus(String studentId, String status) {
    const allowedStatuses = {'present', 'absent', 'late', 'leave'};
    if (!allowedStatuses.contains(status) ||
        !state.studentStatuses.containsKey(studentId)) {
      return;
    }
    state = state.copyWith(
      studentStatuses: {...state.studentStatuses, studentId: status},
      clearError: true,
      clearSuccess: true,
    );
  }

  void markAll(String status) {
    const allowedStatuses = {'present', 'absent', 'late', 'leave'};
    if (!allowedStatuses.contains(status)) return;
    state = state.copyWith(
      studentStatuses: {
        for (final student in state.students) student.id: status,
      },
      clearError: true,
      clearSuccess: true,
    );
  }

  Future<void> saveAttendance({
    required String schoolId,
    required String classId,
    required String sectionId,
    required String teacherId,
  }) async {
    final date = state.selectedDate;
    if (date == null) {
      state = state.copyWith(
        errorMessage: 'Pehle attendance ki date select karein.',
      );
      return;
    }
    if (state.students.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Is section mein koi student nahi mila.',
      );
      return;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await ref.read(attendanceRepositoryProvider).saveAttendance(
        schoolId: schoolId,
        classId: classId,
        sectionId: sectionId,
        date: date,
        markedBy: teacherId,
        studentStatuses: state.studentStatuses,
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Attendance successfully save ho gayi.',
      );

      await loadAttendance(
        schoolId: schoolId,
        classId: classId,
        sectionId: sectionId,
        date: date,
      );
      state = state.copyWith(
        successMessage: 'Attendance successfully save ho gayi.',
      );
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Attendance save nahi ho saki: $error',
      );
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/attendance_controller.dart';
import '../../logic/attendance_state.dart';
import '../widgets/attendance_date_picker.dart';
import '../widgets/attendance_student_row.dart';
import '../widgets/attendance_summary_card.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.sectionId,
    required this.staffId,
  });

  final String schoolId;
  final String classId;
  final String sectionId;
  final String staffId;

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAttendance(DateTime.now());
    });
  }

  Future<void> _loadAttendance(DateTime date) async {
    await ref.read(attendanceControllerProvider.notifier).loadAttendance(
      schoolId: widget.schoolId,
      classId: widget.classId,
      sectionId: widget.sectionId,
      date: date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AttendanceState state = ref.watch(attendanceControllerProvider);
    final controller = ref.read(attendanceControllerProvider.notifier);
    final statuses = state.studentStatuses.values;
    final presentCount = statuses.where((s) => s == 'present').length;
    final absentCount = statuses.where((s) => s == 'absent').length;
    final lateCount = statuses.where((s) => s == 'late').length;
    final leaveCount = statuses.where((s) => s == 'leave').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _loadAttendance(
                  state.selectedDate ?? DateTime.now(),
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    AttendanceDatePicker(
                      selectedDate: state.selectedDate ?? DateTime.now(),
                      onDateChanged: (date) => _loadAttendance(date),
                      enabled: !state.isSaving,
                    ),
                    const SizedBox(height: 12),
                    if (state.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (state.successMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          state.successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 145,
                          child: AttendanceSummaryCard(
                            title: 'Present',
                            count: presentCount,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        SizedBox(
                          width: 145,
                          child: AttendanceSummaryCard(
                            title: 'Absent',
                            count: absentCount,
                            icon: Icons.cancel_outlined,
                          ),
                        ),
                        SizedBox(
                          width: 145,
                          child: AttendanceSummaryCard(
                            title: 'Late',
                            count: lateCount,
                            icon: Icons.access_time,
                          ),
                        ),
                        SizedBox(
                          width: 145,
                          child: AttendanceSummaryCard(
                            title: 'Leave',
                            count: leaveCount,
                            icon: Icons.event_busy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Students (${state.students.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (state.students.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('Is section mein students nahi mile.'),
                        ),
                      )
                    else
                      ...state.students.map((student) {
                        final studentId = student.id;
                        final studentData = <String, dynamic>{
                          ...student.toMap(),
                          'id': studentId,
                        };
                        final status =
                            state.studentStatuses[studentId] ?? 'present';

                        return AttendanceStudentRow(
                          key: ValueKey(studentId),
                          student: studentData,
                          status: status,
                          enabled: !state.isSaving,
                          onStatusChanged: (newStatus) {
                            controller.setStudentStatus(
                              studentId,
                              newStatus,
                            );
                          },
                        );
                      }),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: state.isSaving || state.students.isEmpty
                          ? null
                          : () async {
                              await controller.saveAttendance(
                                schoolId: widget.schoolId,
                                classId: widget.classId,
                                sectionId: widget.sectionId,
                                teacherId: widget.staffId,
                              );
                            },
                      icon: state.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(
                        state.isSaving ? 'Saving...' : 'Save Attendance',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
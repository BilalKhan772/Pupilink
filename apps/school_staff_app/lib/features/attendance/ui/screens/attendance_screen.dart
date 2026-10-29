import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/attendance_controller.dart';
import '../../logic/attendance_state.dart';
import '../widgets/attendance_date_picker.dart';
import '../widgets/attendance_student_row.dart';
import '../widgets/attendance_summary_card.dart';

const Color _green = Color(0xFF138A4B);
const Color _darkGreen = Color(0xFF105C3B);
const Color _background = Color(0xFFF4F8F5);
const Color _border = Color(0xFFDDE9E1);
const Color _text = Color(0xFF202B25);
const Color _muted = Color(0xFF68766E);

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

  String _friendlyAttendanceMessage(String message) {
    if (message.startsWith('Attendance load nahi ho saki:')) {
      return 'Unable to load attendance. Details: ${message.substring('Attendance load nahi ho saki:'.length).trim()}';
    }
    if (message.startsWith('Attendance save nahi ho saki:')) {
      return 'Unable to save attendance. Details: ${message.substring('Attendance save nahi ho saki:'.length).trim()}';
    }
    if (message == 'Attendance successfully save ho gayi.') {
      return 'Attendance saved successfully.';
    }
    if (message == 'Pehle attendance ki date select karein.') {
      return 'Please select an attendance date first.';
    }
    if (message == 'Is section mein koi student nahi mila.') {
      return 'No students were found in this section.';
    }
    return message;
  }

  Future<void> _saveAttendance() async {
    await ref.read(attendanceControllerProvider.notifier).saveAttendance(
          schoolId: widget.schoolId,
          classId: widget.classId,
          sectionId: widget.sectionId,
          teacherId: widget.staffId,
        );
  }

  Widget _messageBanner({required String message, required bool success}) {
    final color = success ? _darkGreen : const Color(0xFFB42318);
    final background = success
        ? const Color(0xFFEAF6EF)
        : const Color(0xFFFFF1F0);
    final border = success
        ? const Color(0xFFD8EBDD)
        : const Color(0xFFF3C6C2);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _studentEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, size: 44, color: _green),
          SizedBox(height: 12),
          Text(
            'No Students Found',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'There are no students assigned to this section.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, height: 1.5, fontSize: 12),
          ),
        ],
      ),
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
      backgroundColor: _background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance'),
            Text(
              'Record and review daily attendance',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      constraints.maxWidth < 600 ? 14.0 : 26.0;
                  final contentWidth = constraints.maxWidth >= 1200
                      ? 1120.0
                      : constraints.maxWidth;
                  final summaryColumns = constraints.maxWidth >= 1000
                      ? 4
                      : constraints.maxWidth >= 560
                          ? 2
                          : 2;
                  final spacing = 12.0;
                  final summaryWidth = (contentWidth -
                          horizontalPadding * 2 -
                          spacing * (summaryColumns - 1)) /
                      summaryColumns;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      child: RefreshIndicator(
                        onRefresh: () => _loadAttendance(
                          state.selectedDate ?? DateTime.now(),
                        ),
                        color: _green,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                20,
                                horizontalPadding,
                                0,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.white, Color(0xFFEEF8F1)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(color: _border),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.fact_check_outlined, color: _green, size: 24),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Daily Attendance',
                                                style: TextStyle(
                                                  color: _darkGreen,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        AttendanceDatePicker(
                                          selectedDate: state.selectedDate ?? DateTime.now(),
                                          onDateChanged: _loadAttendance,
                                          enabled: !state.isSaving,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  if (state.errorMessage != null)
                                    _messageBanner(
                                      message: _friendlyAttendanceMessage(state.errorMessage!),
                                      success: false,
                                    ),
                                  if (state.successMessage != null)
                                    _messageBanner(
                                      message: _friendlyAttendanceMessage(state.successMessage!),
                                      success: true,
                                    ),
                                  _sectionTitle(
                                    title: 'Attendance Summary',
                                    subtitle: 'Current status for ${state.students.length} students.',
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: [
                                      SizedBox(
                                        width: summaryWidth,
                                        child: AttendanceSummaryCard(
                                          title: 'Present',
                                          count: presentCount,
                                          icon: Icons.check_circle_outline_rounded,
                                          accentColor: const Color(0xFF138A4B),
                                        ),
                                      ),
                                      SizedBox(
                                        width: summaryWidth,
                                        child: AttendanceSummaryCard(
                                          title: 'Absent',
                                          count: absentCount,
                                          icon: Icons.cancel_outlined,
                                          accentColor: const Color(0xFFB42318),
                                        ),
                                      ),
                                      SizedBox(
                                        width: summaryWidth,
                                        child: AttendanceSummaryCard(
                                          title: 'Late',
                                          count: lateCount,
                                          icon: Icons.schedule_rounded,
                                          accentColor: const Color(0xFFB7791F),
                                        ),
                                      ),
                                      SizedBox(
                                        width: summaryWidth,
                                        child: AttendanceSummaryCard(
                                          title: 'Leave',
                                          count: leaveCount,
                                          icon: Icons.event_busy_outlined,
                                          accentColor: const Color(0xFF4F46A5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 26),
                                  _sectionTitle(
                                    title: 'Students',
                                    subtitle: 'Select an attendance status for each student.',
                                  ),
                                  const SizedBox(height: 4),
                                ]),
                              ),
                            ),
                            if (state.students.isEmpty)
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  12,
                                  horizontalPadding,
                                  24,
                                ),
                                sliver: const SliverToBoxAdapter(
                                  child: _EmptyStudentsSliver(),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  12,
                                  horizontalPadding,
                                  8,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final student = state.students[index];
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
                                          controller.setStudentStatus(studentId, newStatus);
                                        },
                                      );
                                    },
                                    childCount: state.students.length,
                                    addAutomaticKeepAlives: false,
                                    addRepaintBoundaries: true,
                                  ),
                                ),
                              ),
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                10,
                                horizontalPadding,
                                28,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 600),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _green,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: const Color(0xFFB7D7C2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(13),
                                          ),
                                        ),
                                        onPressed: state.isSaving || state.students.isEmpty
                                            ? null
                                            : _saveAttendance,
                                        icon: state.isSaving
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.save_outlined),
                                        label: Text(
                                          state.isSaving ? 'Saving Attendance...' : 'Save Attendance',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyStudentsSliver extends StatelessWidget {
  const _EmptyStudentsSliver();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.groups_outlined, color: _green, size: 44),
          SizedBox(height: 12),
          Text(
            'No Students Found',
            style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          SizedBox(height: 6),
          Text(
            'There are no students assigned to this section.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

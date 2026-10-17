
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/attendance_summary_controller.dart';

class AttendanceReportScreen extends ConsumerStatefulWidget {
  const AttendanceReportScreen({
    super.key,
    required this.schoolId,
  });

  final String schoolId;

  @override
  ConsumerState<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends ConsumerState<AttendanceReportScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref
          .read(attendanceSummaryControllerProvider.notifier)
          .loadSummaries(schoolId: widget.schoolId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceSummaryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!))
              : state.summaries.isEmpty
                  ? const Center(
                      child: Text('Attendance summaries abhi available nahi hain.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.summaries.length,
                      itemBuilder: (context, index) {
                        final summary = state.summaries[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.analytics_outlined),
                            title: Text('Student: ${summary.studentId}'),
                            subtitle: Text(
                              'Present: ${summary.presentDays} | '
                              'Absent: ${summary.absentDays} | '
                              'Late: ${summary.lateDays} | '
                              'Leave: ${summary.leaveDays}',
                            ),
                            trailing: Text(
                              '${summary.attendancePercentage.toStringAsFixed(1)}%',
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

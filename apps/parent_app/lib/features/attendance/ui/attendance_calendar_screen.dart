
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:parent_app/features/attendance/logic/parent_attendance_controller.dart';
import 'package:parent_app/features/attendance/logic/parent_attendance_state.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> child;

  const AttendanceCalendarScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      ref
          .read(parentAttendanceControllerProvider.notifier)
          .loadAttendance(
            studentId: widget.child['studentId'] as String? ?? '',
          );
    });
  }

  Future<void> _refreshAttendance() {
    return ref
        .read(parentAttendanceControllerProvider.notifier)
        .loadAttendance(
          studentId: widget.child['studentId'] as String? ?? '',
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentAttendanceControllerProvider);

    final studentName = widget.child['name'] as String? ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refreshAttendance,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Attendance Record',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  if (state.error != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Attendance percentage and total records.
                  _buildPercentageCard(state),

                  const SizedBox(height: 15),

                  // Present, Absent and Late summary boxes only.
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.check_circle,
                          title: 'Present',
                          value: '${state.presentCount}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.cancel,
                          title: 'Absent',
                          value: '${state.absentCount}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.schedule,
                          title: 'Late',
                          value: '${state.lateCount}',
                        ),
                      ),
                    ],
                  ),

                  // Daily Attendance and individual records
                  // have intentionally been removed.
                ],
              ),
            ),
    );
  }

  Widget _buildPercentageCard(ParentAttendanceState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Attendance Percentage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${state.attendancePercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Total Records: ${state.totalCount}',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 5,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
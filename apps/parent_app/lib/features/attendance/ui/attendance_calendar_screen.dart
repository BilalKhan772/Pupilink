import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:parent_app/features/attendance/logic/parent_attendance_controller.dart';
import 'package:parent_app/features/attendance/logic/parent_attendance_state.dart';
class AttendanceCalendarScreen
    extends ConsumerStatefulWidget {
  final Map<String, dynamic> child;

  const AttendanceCalendarScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AttendanceCalendarScreen>
      createState() =>
          _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(
            parentAttendanceControllerProvider
                .notifier,
          )
          .loadAttendance(
            studentId:
                widget.child['studentId']
                        as String? ??
                    '',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      parentAttendanceControllerProvider,
    );

    final studentName =
        widget.child['name'] as String? ??
            'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
        ),
      ),
      body: state.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(
                      parentAttendanceControllerProvider
                          .notifier,
                    )
                    .loadAttendance(
                      studentId:
                          widget.child['studentId']
                                  as String? ??
                              '',
                    );
              },
              child: ListView(
                padding:
                    const EdgeInsets.all(20),
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Attendance Record',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (state.error != null)
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        child: Text(
                          state.error!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                  _buildPercentageCard(
                    state,
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon:
                              Icons.check_circle,
                          title: 'Present',
                          value:
                              '${state.presentCount}',
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: _summaryCard(
                          icon: Icons.cancel,
                          title: 'Absent',
                          value:
                              '${state.absentCount}',
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: _summaryCard(
                          icon: Icons.schedule,
                          title: 'Late',
                          value:
                              '${state.lateCount}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Daily Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (state.records.isEmpty)
                    _emptyAttendance()
                  else
                    ...state.records.map(
                      (record) {
                        return _attendanceCard(
                          record,
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPercentageCard(
    ParentAttendanceState state,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Attendance Percentage',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '${state.attendancePercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 34,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Total Records: ${state.totalCount}',
              style: TextStyle(
                color:
                    Colors.grey.shade700,
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
        padding:
            const EdgeInsets.symmetric(
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
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceCard(
    Map<String, dynamic> record,
  ) {
    final date =
        record['date'] as String? ?? '';

    final status =
        record['status'] as String? ??
            'unknown';

    IconData icon;
    String displayStatus;

    switch (status) {
      case 'present':
        icon = Icons.check_circle;
        displayStatus = 'Present';
        break;

      case 'absent':
        icon = Icons.cancel;
        displayStatus = 'Absent';
        break;

      case 'late':
        icon = Icons.schedule;
        displayStatus = 'Late';
        break;

      default:
        icon = Icons.help;
        displayStatus = status;
    }

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 30,
        ),
        title: Text(
          date.isEmpty
              ? 'Date not available'
              : date,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          displayStatus,
        ),
      ),
    );
  }

  Widget _emptyAttendance() {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month,
              size: 60,
            ),

            SizedBox(height: 12),

            Text(
              'No Attendance Record',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Abhi is child ki attendance '
              'available nahi hai.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
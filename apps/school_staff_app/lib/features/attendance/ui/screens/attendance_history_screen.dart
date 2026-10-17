
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/attendance_controller.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({
    super.key,
    required this.schoolId,
    required this.sectionId,
  });

  final String schoolId;
  final String sectionId;

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    return '$day $month ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : state.errorMessage != null && state.sessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : state.sessions.isEmpty
                  ? const Center(
                      child: Text(
                        'Attendance history available nahi hai.',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.sessions.length,
                      itemBuilder: (context, index) {
                        final session = state.sessions[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.event_available),
                            ),
                            title: Text(_formatDate(session.date)),
                            subtitle: Text(
                              'Status: ${session.status}',
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () async {
                              await ref
                                  .read(
                                    attendanceControllerProvider.notifier,
                                  )
                                  .loadAttendance(
                                    schoolId: schoolId,
                                    classId: session.classId,
                                    sectionId: sectionId,
                                    date: session.date,
                                  );

                              if (!context.mounted) return;

                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

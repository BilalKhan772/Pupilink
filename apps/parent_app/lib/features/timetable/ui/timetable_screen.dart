import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/parent_timetable_controller.dart';
import '../logic/parent_timetable_state.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> child;

  const TimetableScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<TimetableScreen> createState() =>
      _TimetableScreenState();
}

class _TimetableScreenState
    extends ConsumerState<TimetableScreen> {
  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final studentId =
          widget.child['studentId'] as String? ?? '';

      if (studentId.isNotEmpty) {
        ref
            .read(
              parentTimetableControllerProvider
                  .notifier,
            )
            .loadTimetable(
              studentId: studentId,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      parentTimetableControllerProvider,
    );

    final childName =
        widget.child['name'] as String? ??
            'Unknown Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timetable',
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () {
                final studentId =
                    widget.child['studentId']
                        as String? ??
                        '';

                if (studentId.isEmpty) {
                  return Future.value();
                }

                return ref
                    .read(
                      parentTimetableControllerProvider
                          .notifier,
                    )
                    .loadTimetable(
                      studentId: studentId,
                    );
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStudentHeader(
                    childName,
                  ),

                  const SizedBox(height: 20),

                  _buildDayTabs(state),

                  const SizedBox(height: 20),

                  if (state.error != null)
                    _buildError(
                      state.error!,
                    ),

                  if (state.error == null)
                    _buildTimetableContent(
                      state,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentHeader(
    String childName,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          childName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Weekly Class Timetable',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDayTabs(
    ParentTimetableState state,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          final isSelected =
              state.selectedDay == day;

          return Padding(
            padding:
                const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(day),
              selected: isSelected,
              onSelected: (_) {
                ref
                    .read(
                      parentTimetableControllerProvider
                          .notifier,
                    )
                    .selectDay(day);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimetableContent(
    ParentTimetableState state,
  ) {
    final records =
        state.selectedDayRecords;

    if (records.isEmpty) {
      return _buildEmptyState(
        state.selectedDay,
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildCurrentPeriodCard(
          state.currentPeriod,
        ),

        const SizedBox(height: 20),

        Text(
          '${state.selectedDay} Schedule',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...records.map(
          (record) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child:
                  _buildPeriodCard(record),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrentPeriodCard(
    Map<String, dynamic>? period,
  ) {
    if (period == null) {
      return const SizedBox.shrink();
    }

    final subject =
        period['subject'] as String? ??
            period['subjectName'] as String? ??
            'Subject';

    final startTime =
        period['startTime'] as String? ??
            '';

    final endTime =
        period['endTime'] as String? ??
            '';

    final teacher =
        period['teacherName'] as String? ??
            period['teacher'] as String? ??
            '';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(
                Icons.access_time,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'First Period',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$startTime - $endTime',
                  ),
                  if (teacher.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      teacher,
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCard(
    Map<String, dynamic> record,
  ) {
    final subject =
        record['subject'] as String? ??
            record['subjectName'] as String? ??
            'Subject';

    final startTime =
        record['startTime'] as String? ??
            '';

    final endTime =
        record['endTime'] as String? ??
            '';

    final teacher =
        record['teacherName'] as String? ??
            record['teacher'] as String? ??
            '';

    final room =
        record['room'] as String? ??
            '';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(
                Icons.menu_book,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$startTime - $endTime',
                  ),
                  if (teacher.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Teacher: $teacher',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                  ],
                  if (room.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Room: $room',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String day,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 50,
          horizontal: 20,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_month,
              size: 70,
            ),
            const SizedBox(height: 15),
            const Text(
              'No Timetable',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$day ke liye abhi timetable available nahi hai.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    String message,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 55,
            ),
            const SizedBox(height: 12),
            const Text(
              'Timetable Load Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
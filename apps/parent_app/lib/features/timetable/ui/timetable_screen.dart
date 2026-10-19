
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

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String get _schoolId =>
      widget.child['schoolId']?.toString() ?? '';

  String get _sectionId =>
      widget.child['sectionId']?.toString() ?? '';

  String get _childName =>
      widget.child['name']?.toString() ?? 'Unknown Student';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      _loadTimetable();
    });
  }

  Future<void> _loadTimetable() {
    return ref
        .read(parentTimetableControllerProvider.notifier)
        .loadTimetable(
          schoolId: _schoolId,
          sectionId: _sectionId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentTimetableControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        actions: [
          IconButton(
            tooltip: 'Refresh timetable',
            onPressed: state.isLoading ? null : _loadTimetable,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTimetable,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStudentHeader(_childName),
                  const SizedBox(height: 20),
                  _buildDayTabs(state),
                  const SizedBox(height: 20),
                  if (state.error != null)
                    _buildError(state.error!)
                  else
                    _buildTimetableContent(state),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentHeader(String childName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildDayTabs(ParentTimetableState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: days.map((day) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(day),
              selected: state.selectedDay == day,
              onSelected: (_) {
                ref
                    .read(parentTimetableControllerProvider.notifier)
                    .selectDay(day);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimetableContent(ParentTimetableState state) {
    final records = state.selectedDayRecords;

    if (records.isEmpty) {
      return _buildEmptyState(state.selectedDay);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCurrentPeriodCard(state.currentPeriod),
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
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPeriodCard(record),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentPeriodCard(Map<String, dynamic>? period) {
    if (period == null) return const SizedBox.shrink();

    final subject =
        period['subject']?.toString() ??
        period['subjectName']?.toString() ??
        'Subject';

    final startTime = period['startTime']?.toString() ?? '';
    final endTime = period['endTime']?.toString() ?? '';
    final teacher =
        period['teacherName']?.toString() ??
        period['teacher']?.toString() ??
        '';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.access_time, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text('$startTime - $endTime'),
                  if (teacher.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Teacher: $teacher',
                      style: TextStyle(color: Colors.grey.shade700),
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

  Widget _buildPeriodCard(Map<String, dynamic> record) {
    final subject =
        record['subject']?.toString() ??
        record['subjectName']?.toString() ??
        'Subject';

    final startTime = record['startTime']?.toString() ?? '';
    final endTime = record['endTime']?.toString() ?? '';
    final teacher =
        record['teacherName']?.toString() ??
        record['teacher']?.toString() ??
        '';
    final room = record['room']?.toString() ?? '';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              child: Icon(Icons.menu_book),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('$startTime - $endTime'),
                  if (teacher.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Teacher: $teacher',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  if (room.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Room: $room',
                      style: TextStyle(color: Colors.grey.shade700),
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

  Widget _buildEmptyState(String day) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 50,
          horizontal: 20,
        ),
        child: Column(
          children: [
            const Icon(Icons.calendar_month, size: 70),
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

  Widget _buildError(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 55),
            const SizedBox(height: 12),
            const Text(
              'Timetable Load Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadTimetable,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

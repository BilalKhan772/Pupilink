import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/timetable_controller.dart';
import 'add_timetable_screen.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
  });

  final String schoolId;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  static const List<String> _days = [
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
    Future.microtask(_load);
  }

  Future<void> _load() {
    return ref.read(timetableControllerProvider.notifier).loadTimetable(
          schoolId: widget.schoolId,
          sectionId: widget.sectionId,
        );
  }

  Future<void> _openEditor({Map<String, dynamic>? entry}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddTimetableScreen(
          schoolId: widget.schoolId,
          classId: widget.classId,
          className: widget.className,
          sectionId: widget.sectionId,
          sectionName: widget.sectionName,
          entry: entry,
          initialDay: entry?['day'] as String? ??
              ref.read(timetableControllerProvider).selectedDay,
        ),
      ),
    );

    if (result == true && mounted) {
      await _load();
    }
  }

  Future<void> _deleteEntry(Map<String, dynamic> entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete timetable entry?'),
        content: Text(
          '${entry['subject'] ?? 'This subject'} ki entry delete ho jayegi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final id = entry['id'] as String? ?? '';
    if (id.isEmpty) return;

    final success = await ref
        .read(timetableControllerProvider.notifier)
        .deleteEntry(
          entryId: id,
          schoolId: widget.schoolId,
          sectionId: widget.sectionId,
        );

    if (!mounted) return;

    final error = ref.read(timetableControllerProvider).error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Timetable entry delete ho gayi.'
              : error ?? 'Entry delete nahi ho saki.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Timetable — ${widget.sectionName}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add Period'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.calendar_month_outlined),
              ),
              title: Text(
                widget.className,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Section ${widget.sectionName}'),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _days.map((day) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(day),
                      selected: state.selectedDay == day,
                      onSelected: (_) {
                        ref
                            .read(timetableControllerProvider.notifier)
                            .selectDay(day);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: Builder(
                        builder: (context) {
                          final records = state.selectedDayRecords;

                          if (state.error != null && state.records.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24),
                              children: [
                                const Icon(Icons.error_outline, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  state.error!,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: OutlinedButton(
                                    onPressed: _load,
                                    child: const Text('Retry'),
                                  ),
                                ),
                              ],
                            );
                          }

                          if (records.isEmpty) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(32),
                              children: [
                                const SizedBox(height: 50),
                                const Icon(
                                  Icons.event_busy_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No periods added',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${state.selectedDay} ke liye Add Period par click karein.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          }

                          return ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final entry = records[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        child: Icon(Icons.menu_book_outlined),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry['subject'] as String? ??
                                                  'Subject',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              '${entry['startTime'] ?? ''} – ${entry['endTime'] ?? ''}',
                                            ),
                                            if ((entry['teacherName'] as String? ??
                                                    '')
                                                .isNotEmpty)
                                              Text(
                                                'Teacher: ${entry['teacherName']}',
                                              ),
                                            if ((entry['room'] as String? ?? '')
                                                .isNotEmpty)
                                              Text('Room: ${entry['room']}'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _openEditor(entry: entry);
                                          } else if (value == 'delete') {
                                            _deleteEntry(entry);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
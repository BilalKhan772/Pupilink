import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/timetable_controller.dart';

class AddTimetableScreen extends ConsumerStatefulWidget {
  const AddTimetableScreen({
    super.key,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    this.entry,
    this.initialDay = 'Monday',
  });

  final String schoolId;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final Map<String, dynamic>? entry;
  final String initialDay;

  @override
  ConsumerState<AddTimetableScreen> createState() =>
      _AddTimetableScreenState();
}

class _AddTimetableScreenState extends ConsumerState<AddTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _teacherController;
  late final TextEditingController _roomController;

  late String _day;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  bool get _isEditing => widget.entry != null;

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

    final entry = widget.entry;

    _subjectController = TextEditingController(
      text: entry?['subject'] as String? ??
          entry?['subjectName'] as String? ??
          '',
    );
    _teacherController = TextEditingController(
      text: entry?['teacherName'] as String? ?? '',
    );
    _roomController = TextEditingController(
      text: entry?['room'] as String? ?? '',
    );

    final existingDay = entry?['day'] as String? ?? widget.initialDay;
    _day = _days.contains(existingDay) ? existingDay : 'Monday';

    _startTime = _parseTime(entry?['startTime'] as String?) ??
        const TimeOfDay(hour: 8, minute: 0);
    _endTime = _parseTime(entry?['endTime'] as String?) ??
        const TimeOfDay(hour: 8, minute: 40);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;

    final parts = value.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _chooseTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (selected == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_minutes(_endTime) <= _minutes(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time, start time ke baad hona chahiye.'),
        ),
      );
      return;
    }

    final saved = await ref
        .read(timetableControllerProvider.notifier)
        .saveEntry(
          entryId: widget.entry?['id'] as String?,
          schoolId: widget.schoolId,
          classId: widget.classId,
          className: widget.className,
          sectionId: widget.sectionId,
          sectionName: widget.sectionName,
          day: _day,
          subject: _subjectController.text.trim(),
          teacherName: _teacherController.text.trim(),
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          room: _roomController.text.trim(),
        );

    if (!mounted) return;

    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(timetableControllerProvider).error;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Timetable save nahi ho saka.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Timetable' : 'Add Timetable'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.grid_view_rounded),
                  title: Text('Section ${widget.sectionName}'),
                  subtitle: Text(widget.className),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _day,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                ),
                items: _days
                    .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text(day),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _day = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. Mathematics',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Subject required hai.'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _teacherController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Teacher name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseTime(isStart: true),
                      icon: const Icon(Icons.access_time),
                      label: Text('Start: ${_formatTime(_startTime)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _chooseTime(isStart: false),
                      icon: const Icon(Icons.access_time_filled),
                      label: Text('End: ${_formatTime(_endTime)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: state.isSaving ? null : _save,
                icon: state.isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(state.isSaving ? 'Saving...' : 'Save Timetable'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
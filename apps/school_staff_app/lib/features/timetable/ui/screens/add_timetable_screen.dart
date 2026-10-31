
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

class _AddTimetableScreenState
    extends ConsumerState<AddTimetableScreen> {
  static const Color _green = Color(0xFF16865A);
  static const Color _darkGreen = Color(0xFF116B46);
  static const Color _lightGreen = Color(0xFFEAF5EF);
  static const Color _background = Color(0xFFF6F9F7);
  static const Color _border = Color(0xFFE3EBE5);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF718078);

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

    final existingDay =
        entry?['day'] as String? ?? widget.initialDay;

    _day = _days.contains(existingDay)
        ? existingDay
        : 'Monday';

    _startTime = _parseTime(
          entry?['startTime'] as String?,
        ) ??
        const TimeOfDay(hour: 8, minute: 0);

    _endTime = _parseTime(
          entry?['endTime'] as String?,
        ) ??
        const TimeOfDay(hour: 8, minute: 40);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Time helpers
  // ---------------------------------------------------------------------------

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

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  int _minutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // ---------------------------------------------------------------------------
  // Choose time
  // ---------------------------------------------------------------------------

  Future<void> _chooseTime({
    required bool isStart,
  }) async {
    final theme = Theme.of(context);

    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: _green,
              secondary: _green,
            ),
          ),
          child: child!,
        );
      },
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

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? const Color(0xFFB93838) : _darkGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_minutes(_endTime) <= _minutes(_startTime)) {
      _showMessage(
        'End time must be later than start time.',
        isError: true,
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
      final error =
          ref.read(timetableControllerProvider).error;

      _showMessage(
        error ?? 'Unable to save timetable. Please try again.',
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Input decoration
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required String hint,
    IconData? icon,
  }) {
    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: _muted,
              size: 21,
            ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: border(_border),
      enabledBorder: border(_border),
      focusedBorder: border(_green, width: 1.5),
      errorBorder: border(
        Theme.of(context).colorScheme.error,
      ),
      focusedErrorBorder: border(
        Theme.of(context).colorScheme.error,
        width: 1.5,
      ),
      labelStyle: const TextStyle(color: _muted),
      hintStyle: const TextStyle(color: _muted),
    );
  }

  // ---------------------------------------------------------------------------
  // Form section heading
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: _lightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: _green,
            size: 23,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Class information header
  // ---------------------------------------------------------------------------

  Widget _buildClassCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: _green,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.className,
                  style: const TextStyle(
                    color: _darkGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Section ${widget.sectionName}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isEditing ? 'Editing' : 'New Period',
              style: const TextStyle(
                color: _darkGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Day selector
  // ---------------------------------------------------------------------------

  Widget _buildDayField() {
    return DropdownButtonFormField<String>(
      value: _day,
      isExpanded: true,
      decoration: _inputDecoration(
        context: context,
        label: 'Day',
        hint: 'Select a day',
        icon: Icons.calendar_today_outlined,
      ),
      items: _days.map((day) {
        return DropdownMenuItem<String>(
          value: day,
          child: Text(day),
        );
      }).toList(),
      onChanged: ref.watch(timetableControllerProvider).isSaving
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  _day = value;
                });
              }
            },
    );
  }

  // ---------------------------------------------------------------------------
  // Time selection card
  // ---------------------------------------------------------------------------

  Widget _buildTimeCard({
    required bool isStart,
  }) {
    final selectedTime = isStart ? _startTime : _endTime;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: ref.watch(timetableControllerProvider).isSaving
            ? null
            : () => _chooseTime(isStart: isStart),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isStart
                      ? Icons.play_arrow_rounded
                      : Icons.flag_outlined,
                  color: _green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStart ? 'Start Time' : 'End Time',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatTime(selectedTime),
                      style: const TextStyle(
                        color: _darkGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.access_time_rounded,
                size: 18,
                color: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableControllerProvider);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEditing ? 'Edit Timetable Period' : 'Add Timetable Period',
          style: const TextStyle(
            color: _darkGreen,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: _border,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 24,
                  vertical: 20,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 760,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildClassCard(),

                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeading(
                                  icon: Icons.edit_calendar_outlined,
                                  title: 'Period Details',
                                  subtitle:
                                      'Enter the subject and schedule information.',
                                ),

                                const SizedBox(height: 24),

                                const Text(
                                  'Day',
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                _buildDayField(),

                                const SizedBox(height: 18),

                                const Text(
                                  'Subject',
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                TextFormField(
                                  controller: _subjectController,
                                  enabled: !state.isSaving,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDecoration(
                                    context: context,
                                    label: 'Subject name',
                                    hint: 'e.g. Mathematics',
                                    icon: Icons.menu_book_outlined,
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Please enter a subject name.';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 18),

                                const Text(
                                  'Teacher',
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                TextFormField(
                                  controller: _teacherController,
                                  enabled: !state.isSaving,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  decoration: _inputDecoration(
                                    context: context,
                                    label: 'Teacher name (optional)',
                                    hint: 'Enter teacher name',
                                    icon: Icons.person_outline,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                _buildSectionHeading(
                                  icon: Icons.schedule_outlined,
                                  title: 'Period Timing',
                                  subtitle:
                                      'Choose when this period starts and ends.',
                                ),

                                const SizedBox(height: 16),

                                LayoutBuilder(
                                  builder: (context, timeConstraints) {
                                    if (timeConstraints.maxWidth < 430) {
                                      return Column(
                                        children: [
                                          _buildTimeCard(
                                            isStart: true,
                                          ),
                                          const SizedBox(height: 12),
                                          _buildTimeCard(
                                            isStart: false,
                                          ),
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(
                                          child: _buildTimeCard(
                                            isStart: true,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTimeCard(
                                            isStart: false,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 22),

                                const Text(
                                  'Room',
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                TextFormField(
                                  controller: _roomController,
                                  enabled: !state.isSaving,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
                                  decoration: _inputDecoration(
                                    context: context,
                                    label: 'Room (optional)',
                                    hint: 'e.g. Room 04',
                                    icon: Icons.meeting_room_outlined,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton.icon(
                                    onPressed:
                                        state.isSaving ? null : _save,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _green,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          _green.withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: state.isSaving
                                        ? const SizedBox(
                                            width: 19,
                                            height: 19,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.save_outlined,
                                          ),
                                    label: Text(
                                      state.isSaving
                                          ? 'Saving...'
                                          : _isEditing
                                              ? 'Update Timetable'
                                              : 'Save Timetable',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

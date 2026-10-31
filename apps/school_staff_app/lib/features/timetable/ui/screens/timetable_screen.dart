
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
  ConsumerState<TimetableScreen> createState() =>
      _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  static const Color _green = Color(0xFF16865A);
  static const Color _darkGreen = Color(0xFF116B46);
  static const Color _lightGreen = Color(0xFFEAF5EF);
  static const Color _background = Color(0xFFF6F9F7);
  static const Color _border = Color(0xFFE3EBE5);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF718078);

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

    Future.microtask(() {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() {
    return ref.read(timetableControllerProvider.notifier).loadTimetable(
          schoolId: widget.schoolId,
          sectionId: widget.sectionId,
        );
  }

  // ---------------------------------------------------------------------------
  // Add / Edit timetable entry
  // ---------------------------------------------------------------------------

  Future<void> _openEditor({
    Map<String, dynamic>? entry,
  }) async {
    final selectedDay =
        ref.read(timetableControllerProvider).selectedDay;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddTimetableScreen(
          schoolId: widget.schoolId,
          classId: widget.classId,
          className: widget.className,
          sectionId: widget.sectionId,
          sectionName: widget.sectionName,
          entry: entry,
          initialDay: entry?['day'] as String? ?? selectedDay,
        ),
      ),
    );

    if (result == true && mounted) {
      await _load();
    }
  }

  // ---------------------------------------------------------------------------
  // Delete timetable entry
  // ---------------------------------------------------------------------------

  Future<void> _deleteEntry(
    Map<String, dynamic> entry,
  ) async {
    final subject = _value(entry, 'subject').isEmpty
        ? 'this subject'
        : _value(entry, 'subject');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete timetable period?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'The timetable entry for "$subject" will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: _muted),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB93838),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final id = entry['id'] as String? ?? '';

    if (id.isEmpty) {
      _showMessage(
        'Timetable entry ID is unavailable.',
        isError: true,
      );
      return;
    }

    final success = await ref
        .read(timetableControllerProvider.notifier)
        .deleteEntry(
          entryId: id,
          schoolId: widget.schoolId,
          sectionId: widget.sectionId,
        );

    if (!mounted) return;

    final error = ref.read(timetableControllerProvider).error;

    _showMessage(
      success
          ? 'Timetable period deleted successfully.'
          : error ?? 'Unable to delete timetable period.',
      isError: !success,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _value(
    Map<String, dynamic> entry,
    String key,
  ) {
    final value = entry[key];
    return value is String ? value.trim() : '';
  }

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
              Expanded(
                child: Text(message),
              ),
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
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildClassHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF5EF),
            Color(0xFFF5FAF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: _green,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.className.isEmpty
                      ? 'Class'
                      : widget.className,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Section ${widget.sectionName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Weekly Schedule',
              style: TextStyle(
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

  Widget _buildDaySelector(
    BuildContext context,
    String selectedDay,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Day',
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 9,
            children: _days.map((day) {
              final selected = selectedDay == day;

              return ChoiceChip(
                label: Text(day),
                selected: selected,
                showCheckmark: true,
                checkmarkColor: Colors.white,
                onSelected: (_) {
                  ref
                      .read(timetableControllerProvider.notifier)
                      .selectDay(day);
                },
                selectedColor: _green,
                backgroundColor: const Color(0xFFF7FAF8),
                side: BorderSide(
                  color: selected ? _green : _border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _text,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Schedule heading
  // ---------------------------------------------------------------------------

  Widget _buildScheduleHeading(
    BuildContext context,
    String selectedDay,
    int periodCount,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$selectedDay Schedule',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                periodCount == 0
                    ? 'No periods scheduled'
                    : '$periodCount ${periodCount == 1 ? 'period' : 'periods'} scheduled',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        if (periodCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$periodCount ${periodCount == 1 ? 'Period' : 'Periods'}',
              style: const TextStyle(
                color: _darkGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Period card
  // ---------------------------------------------------------------------------

  Widget _buildPeriodCard(
    BuildContext context,
    Map<String, dynamic> entry,
    int index,
    bool isSaving,
  ) {
    final subject = _value(entry, 'subject').isEmpty
        ? 'Untitled Subject'
        : _value(entry, 'subject');

    final startTime = _value(entry, 'startTime');
    final endTime = _value(entry, 'endTime');
    final teacher = _value(entry, 'teacherName');
    final room = _value(entry, 'room');

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 49,
              height: 49,
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: _green,
                size: 25,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildDetailTag(
                        icon: Icons.access_time_rounded,
                        label: startTime.isEmpty && endTime.isEmpty
                            ? 'Time not set'
                            : '$startTime – $endTime',
                        filled: true,
                      ),
                      if (room.isNotEmpty)
                        _buildDetailTag(
                          icon: Icons.meeting_room_outlined,
                          label: room,
                        ),
                    ],
                  ),

                  if (teacher.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 17,
                          color: _muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            teacher,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 4),

            PopupMenuButton<String>(
              tooltip: 'Period options',
              enabled: !isSaving,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: _muted,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _openEditor(entry: entry);
                } else if (value == 'delete') {
                  _deleteEntry(entry);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text('Edit Period'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Color(0xFFB93838),
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Delete Period',
                        style: TextStyle(
                          color: Color(0xFFB93838),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTag({
    required IconData icon,
    required String label,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: filled ? _lightGreen : const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: filled ? _border : const Color(0xFFEDF0ED),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: _darkGreen,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(
    BuildContext context,
    String selectedDay,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 38,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: const BoxDecoration(
              color: _lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: _green,
              size: 37,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            'No Periods Scheduled',
            style: theme.textTheme.titleLarge?.copyWith(
              color: _text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no timetable periods for $selectedDay yet. '
            'Add a period to create the daily schedule.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 19),
          OutlinedButton.icon(
            onPressed: () => _openEditor(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: const BorderSide(color: _green),
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Period'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorCard(
    BuildContext context,
    String message,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F0),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFF2D4D0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFB93838),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9F3030),
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: _load,
            child: const Text(
              'Retry',
              style: TextStyle(color: _darkGreen),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timetableControllerProvider);

    final records = state.selectedDayRecords;

    final isInitialLoading =
        state.isLoading && state.records.isEmpty;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Timetable',
              style: TextStyle(
                color: _darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${widget.className} · Section ${widget.sectionName}',
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: _border,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh timetable',
            onPressed: state.isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSaving ? null : () => _openEditor(),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Period',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _green,
          onRefresh: _load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 24,
                  vertical: isMobile ? 16 : 24,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1050,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildClassHeader(context),
                          const SizedBox(height: 17),
                          _buildDaySelector(
                            context,
                            state.selectedDay,
                          ),
                          const SizedBox(height: 25),
                          _buildScheduleHeading(
                            context,
                            state.selectedDay,
                            records.length,
                          ),
                          const SizedBox(height: 14),

                          if (state.isLoading && state.records.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 14),
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: _green,
                              ),
                            ),

                          if (state.error != null)
                            _buildErrorCard(
                              context,
                              state.error!,
                            ),

                          if (isInitialLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 55),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _green,
                                ),
                              ),
                            )
                          else if (records.isEmpty)
                            _buildEmptyState(
                              context,
                              state.selectedDay,
                            )
                          else
                            ...records.asMap().entries.map((item) {
                              return _buildPeriodCard(
                                context,
                                item.value,
                                item.key,
                                state.isSaving,
                              );
                            }),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

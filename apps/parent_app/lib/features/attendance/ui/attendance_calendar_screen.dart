
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
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

  String get _studentId =>
      widget.child['studentId'] as String? ?? '';

  Future<void> _loadAttendance() async {
    await ref
        .read(parentAttendanceControllerProvider.notifier)
        .loadAttendance(studentId: _studentId);
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      _loadAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ParentAttendanceState state =
        ref.watch(parentAttendanceControllerProvider);

    final studentName =
        (widget.child['name'] as String? ?? '').trim().isEmpty
            ? 'Student'
            : (widget.child['name'] as String).trim();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _darkGreen,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Review your child\'s attendance',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: _muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh attendance',
            onPressed: state.isLoading ? null : _loadAttendance,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: _border,
          ),
        ),
      ),
      body: SafeArea(
        child: state.isLoading && state.records.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _green),
                    SizedBox(height: 14),
                    Text(
                      'Loading attendance...',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final horizontalPadding =
                      screenWidth < 600 ? 16.0 : 24.0;
                  final contentWidth = screenWidth >= 1200
                      ? 1040.0
                      : screenWidth;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      child: RefreshIndicator(
                        onRefresh: _loadAttendance,
                        color: _green,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            22,
                            horizontalPadding,
                            36,
                          ),
                          children: [
                            _buildStudentHeader(studentName),
                            if (state.isLoading) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(
                                minHeight: 3,
                                color: _green,
                                backgroundColor:
                                    Color(0xFFDCEBE1),
                              ),
                            ],
                            if (state.error != null) ...[
                              const SizedBox(height: 16),
                              _buildErrorCard(state.error!),
                            ],
                            const SizedBox(height: 24),
                            _buildSectionHeading(
                              title: 'Attendance Overview',
                              subtitle:
                                  'A summary of your child\'s recorded attendance.',
                            ),
                            const SizedBox(height: 14),
                            _buildPercentageCard(state),
                            const SizedBox(height: 26),
                            _buildSectionHeading(
                              title: 'Attendance Summary',
                              subtitle:
                                  'Current status for ${state.totalCount} '
                                  '${state.totalCount == 1 ? 'record' : 'records'}.',
                            ),
                            const SizedBox(height: 14),
                            _buildSummaryGrid(
                              context: context,
                              state: state,
                            ),
                            if (state.records.isEmpty &&
                                state.error == null) ...[
                              const SizedBox(height: 20),
                              _buildEmptyState(),
                            ],
                            const SizedBox(height: 12),
                            const _InformationNote(
                              message:
                                  'Attendance percentages are calculated '
                                  'from the records available for this student. '
                                  'Present and Late count towards attendance.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildStudentHeader(String studentName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFEAF6EF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF1E4),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: _darkGreen,
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Attendance Record',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: _green,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageCard(ParentAttendanceState state) {
    final percentage = state.attendancePercentage;
    final progress =
        (percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F3E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: _darkGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Percentage',
                      style: TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Overall attendance',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: _darkGreen,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: _green,
              backgroundColor: const Color(0xFFDCEBE1),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: _muted,
                size: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Total records: ${state.totalCount}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                state.totalCount == 0
                    ? 'No records yet'
                    : 'Present + Late',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid({
    required BuildContext context,
    required ParentAttendanceState state,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 12.0;

        final cardWidth = width >= 760
            ? (width - (spacing * 2)) / 3
            : width >= 400
                ? (width - spacing) / 2
                : width;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Present',
                count: state.presentCount,
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF138A4B),
                background: const Color(0xFFE7F5EC),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Absent',
                count: state.absentCount,
                icon: Icons.cancel_outlined,
                color: const Color(0xFFC62828),
                background: const Color(0xFFFCEAEA),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _summaryCard(
                title: 'Late',
                count: state.lateCount,
                icon: Icons.schedule_rounded,
                color: const Color(0xFFB76A08),
                background: const Color(0xFFFFF3E2),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        border: Border.all(color: const Color(0xFFF3C6C2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to Load Attendance',
                  style: TextStyle(
                    color: Color(0xFF912018),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF912018),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _loadAttendance,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF912018),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 17,
                    ),
                    label: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFE4F3E9),
            child: Icon(
              Icons.event_available_outlined,
              color: _darkGreen,
              size: 30,
            ),
          ),
          SizedBox(height: 15),
          Text(
            'No Attendance Records',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Attendance records will appear here once they are recorded by the school.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationNote extends StatelessWidget {
  const _InformationNote({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFD8EBDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF267344),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF315B40),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';

import '../../../attendance/ui/attendance_calendar_screen.dart';
import '../../../homework/ui/homework_screen.dart';
import '../../../results/ui/test_results_screen.dart';
import '../../../timetable/ui/timetable_screen.dart';

class ChildProfileScreen extends StatelessWidget {
  const ChildProfileScreen({
    super.key,
    required this.child,
  });

  final Map<String, dynamic> child;

  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);

  @override
  Widget build(BuildContext context) {
    final name = child['name'] as String? ?? 'Unknown Student';
    final admissionNumber =
        child['admissionNumber'] as String? ?? '';
    final schoolName = child['schoolName'] as String? ?? '';
    final className = child['className'] as String? ?? '';
    final section = child['section'] as String? ?? '';
    final city = child['city'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        title: const Text('Child Profile'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Color(0xFFE1EAE3),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding =
              constraints.maxWidth < 600 ? 16.0 : 28.0;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 950),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(name),
                      const SizedBox(height: 24),

                      const Text(
                        'Student Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F3328),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildInformationGrid(
                        context: context,
                        maxWidth: constraints.maxWidth,
                        items: [
                          _ProfileInfo(
                            label: 'Admission Number',
                            value: admissionNumber,
                            icon: Icons.badge_outlined,
                          ),
                          _ProfileInfo(
                            label: 'School',
                            value: schoolName,
                            icon: Icons.school_outlined,
                          ),
                          _ProfileInfo(
                            label: 'City',
                            value: city,
                            icon: Icons.location_city_outlined,
                          ),
                          _ProfileInfo(
                            label: 'Class',
                            value: className,
                            icon: Icons.class_outlined,
                          ),
                          _ProfileInfo(
                            label: 'Section',
                            value: section,
                            icon: Icons.groups_outlined,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Academic Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F3328),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select a service to view your child’s academic information.',
                        style: TextStyle(
                          color: Color(0xFF718078),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final wide = gridConstraints.maxWidth >= 650;
                          final spacing = 12.0;
                          final itemWidth = wide
                              ? (gridConstraints.maxWidth - spacing) / 2
                              : gridConstraints.maxWidth;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              SizedBox(
                                width: itemWidth,
                                child: _featureCard(
                                  icon: Icons.menu_book_rounded,
                                  title: 'Homework',
                                  subtitle:
                                      'View assigned homework and instructions.',
                                  onTap: () => _openHomework(context),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _featureCard(
                                  icon: Icons.fact_check_outlined,
                                  title: 'Attendance',
                                  subtitle:
                                      'Review your child’s attendance record.',
                                  onTap: () => _openAttendance(context),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _featureCard(
                                  icon: Icons.assessment_outlined,
                                  title: 'Results',
                                  subtitle:
                                      'View academic results and performance.',
                                  onTap: () => _openResults(context),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: _featureCard(
                                  icon: Icons.calendar_month_rounded,
                                  title: 'Timetable',
                                  subtitle:
                                      'View the current class timetable.',
                                  onTap: () => _openTimetable(context),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFEAF5ED),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE9DF)),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF0E3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 36,
              color: _darkGreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _darkGreen,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Student Profile',
                  style: TextStyle(
                    color: Color(0xFF718078),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationGrid({
    required BuildContext context,
    required double maxWidth,
    required List<_ProfileInfo> items,
  }) {
    final wide = maxWidth >= 700;
    const spacing = 12.0;
    final width = wide
        ? (maxWidth - 28 - spacing) / 2
        : double.infinity;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: items.map((item) {
        return SizedBox(
          width: width,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE0EAE3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F3E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: _green,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718078),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value.trim().isEmpty
                            ? 'Not available'
                            : item.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF24372B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE0EAE3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F3E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: _green,
                  size: 24,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF718078),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHomework(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeworkScreen(child: child),
      ),
    );
  }

  void _openAttendance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceCalendarScreen(child: child),
      ),
    );
  }

  void _openResults(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TestResultsScreen(child: child),
      ),
    );
  }

  void _openTimetable(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TimetableScreen(child: child),
      ),
    );
  }
}

class _ProfileInfo {
  const _ProfileInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

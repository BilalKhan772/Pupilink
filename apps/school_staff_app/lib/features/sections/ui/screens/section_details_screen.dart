
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../../students/data/students_repository.dart';
import '../../../students/ui/screens/all_students_screen.dart';
import '../../../timetable/ui/screens/timetable_screen.dart';
import '../../../monitor/ui/add_monitor_screen.dart';
import '../../data/subjects_teacher_repository.dart';
import 'subjects_teacher_screen.dart';

class SectionDetailsScreen extends ConsumerStatefulWidget {
  const SectionDetailsScreen({
    super.key,
    required this.section,
    required this.className,
    required this.onEdit,
    required this.onToggleActive,
  });

  final SchoolSection section;
  final String className;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  ConsumerState<SectionDetailsScreen> createState() =>
      _SectionDetailsScreenState();
}

class _SectionDetailsScreenState
    extends ConsumerState<SectionDetailsScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF7F9F7);
  static const Color _text = Color(0xFF172B24);
  static const Color _muted = Color(0xFF758078);

  int? _studentCount;
  bool _isLoadingStudents = true;
  String? _studentCountError;

  int? _subjectsCount;
  int? _teachersCount;
  bool _isLoadingSectionSummary = true;
  String? _sectionSummaryError;

  String? _monitorName;
  String? _monitorEmail;
  bool _isLoadingMonitor = true;
  String? _monitorError;

  @override
  void initState() {
    super.initState();
    _loadStudentCount();
    _loadSectionSummary();
    _loadMonitor();
  }

  Future<void> _loadStudentCount() async {
    if (mounted) {
      setState(() {
        _isLoadingStudents = true;
        _studentCountError = null;
      });
    }

    try {
      final count = await ref
          .read(studentsRepositoryProvider)
          .getStudentCountForSection(
            schoolId: widget.section.schoolId,
            sectionId: widget.section.id,
          );

      if (!mounted) return;

      setState(() {
        _studentCount = count;
        _isLoadingStudents = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _studentCountError = 'Students count load nahi ho saki.';
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _loadSectionSummary() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSectionSummary = true;
      _sectionSummaryError = null;
    });

    try {
      final repository = SubjectsTeacherRepository();

      final assignments = await repository.getAssignments(
        schoolId: widget.section.schoolId,
        sectionId: widget.section.id,
      );

      if (!mounted) return;

      final activeAssignments = assignments
          .where((assignment) => assignment.isActive)
          .toList();

      final subjectIds = activeAssignments
          .map((assignment) => assignment.subjectId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      final teacherIds = activeAssignments
          .map((assignment) => assignment.teacherId)
          .where((id) => id.isNotEmpty)
          .toSet();

      setState(() {
        _subjectsCount = subjectIds.length;
        _teachersCount = teacherIds.length;
        _isLoadingSectionSummary = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _sectionSummaryError =
            'Subjects aur teachers ka data load nahi ho saka.';
        _isLoadingSectionSummary = false;
      });
    }
  }

  Future<void> _loadMonitor() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMonitor = true;
      _monitorError = null;
    });

    try {
      final document = await FirebaseFirestore.instance
          .collection('sections')
          .doc(widget.section.id)
          .get();

      if (!mounted) return;

      if (!document.exists || document.data() == null) {
        setState(() {
          _monitorName = null;
          _monitorEmail = null;
          _isLoadingMonitor = false;
        });
        return;
      }

      final data = document.data()!;

      final monitorId = (data['monitorId'] as String? ?? '').trim();
      final monitorName = (data['monitorName'] as String? ?? '').trim();
      final monitorEmail = (data['monitorEmail'] as String? ?? '').trim();

      setState(() {
        _monitorName =
            monitorId.isEmpty || monitorName.isEmpty ? null : monitorName;
        _monitorEmail =
            monitorId.isEmpty || monitorEmail.isEmpty ? null : monitorEmail;
        _isLoadingMonitor = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _monitorError = 'Monitor information load nahi ho saki.';
        _isLoadingMonitor = false;
      });
    }
  }

  Future<void> _openAddMonitor() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AddMonitorScreen(
          section: widget.section,
          className: widget.className,
        ),
      ),
    );

    if (!mounted) return;

    await _loadMonitor();
  }

  void _showNotConnectedMessage(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature screen abhi connect nahi hui hai.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openAllStudents() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AllStudentsScreen(
          sectionId: widget.section.id,
          sectionName: widget.section.name,
          className: widget.className,
        ),
      ),
    );

    if (mounted) {
      await _loadStudentCount();
    }
  }

  Future<void> _openSubjectsTeacher() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SubjectsTeacherScreen(
          section: widget.section,
          className: widget.className,
          repository: SubjectsTeacherRepository(),
        ),
      ),
    );

    if (mounted) {
      await _loadSectionSummary();
    }
  }

  Future<void> _openTimetable() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TimetableScreen(
          schoolId: widget.section.schoolId,
          classId: widget.section.classId,
          className: widget.className,
          sectionId: widget.section.id,
          sectionName: widget.section.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final isActive = section.isActive;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _darkGreen,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section ${section.name}',
              style: const TextStyle(
                color: _darkGreen,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'Section Details',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(
              Icons.more_vert_rounded,
              color: _darkGreen,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                widget.onEdit();
              } else if (value == 'status') {
                widget.onToggleActive();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit section'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem<String>(
                value: 'status',
                child: ListTile(
                  leading: Icon(
                    isActive
                        ? Icons.pause_circle_outline
                        : Icons.check_circle_outline,
                  ),
                  title: Text(
                    isActive ? 'Deactivate section' : 'Activate section',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;
            final horizontalPadding = isWide ? 32.0 : 20.0;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                32,
              ),
              children: [
                _SectionHeaderCard(
                  sectionName: section.name,
                  isActive: isActive,
                  onEdit: widget.onEdit,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Manage Section',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Manage attendance, students and other section activities.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _ManagementGrid(
                  onTap: (feature) {
                    if (feature == 'All Students') {
                      _openAllStudents();
                    } else if (feature == 'Subjects & Teacher') {
                      _openSubjectsTeacher();
                    } else if (feature == 'Time Table') {
                      _openTimetable();
                    } else if (feature == 'Add Monitor') {
                      _openAddMonitor();
                    } else {
                      _showNotConnectedMessage(feature);
                    }
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Section Summary',
                  style: TextStyle(
                    color: _darkGreen,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _SectionSummary(
                  studentCount: _studentCount,
                  isLoadingStudents: _isLoadingStudents,
                  studentCountError: _studentCountError,
                  onRetry: _loadStudentCount,
                  subjectsCount: _subjectsCount,
                  teachersCount: _teachersCount,
                  isLoadingSectionSummary: _isLoadingSectionSummary,
                  sectionSummaryError: _sectionSummaryError,
                  onRetrySectionSummary: _loadSectionSummary,
                  monitorName: _monitorName,
                  monitorEmail: _monitorEmail,
                  isLoadingMonitor: _isLoadingMonitor,
                  monitorError: _monitorError,
                  onRetryMonitor: _loadMonitor,
                ),
                const SizedBox(height: 24),
                if (_monitorName != null)
                  _MonitorInformationCard(
                    name: _monitorName!,
                    email: _monitorEmail,
                    onManage: _openAddMonitor,
                  ),
                if (_monitorName != null) const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE4ECE6),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        color: _green,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class Information',
                              style: TextStyle(
                                color: _text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Class: ${widget.className.isEmpty ? 'Not available' : widget.className}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Capacity: ${section.capacity?.toString() ?? 'Not set'} students',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonitorInformationCard extends StatelessWidget {
  const _MonitorInformationCard({
    required this.name,
    required this.email,
    required this.onManage,
  });

  final String name;
  final String? email;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECE6)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF138A4B),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Monitor',
                  style: TextStyle(
                    color: Color(0xFF758078),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF172B24),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email!,
                    style: const TextStyle(
                      color: Color(0xFF758078),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Manage monitor',
            onPressed: onManage,
            icon: const Icon(
              Icons.edit_outlined,
              color: Color(0xFF138A4B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderCard extends StatelessWidget {
  const _SectionHeaderCard({
    required this.sectionName,
    required this.isActive,
    required this.onEdit,
  });

  final String sectionName;
  final bool isActive;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EEE8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173C27).withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;

          final identity = Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6EF),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  sectionName.isEmpty
                      ? '?'
                      : sectionName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF138A4B),
                    fontSize: 35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section $sectionName',
                      style: const TextStyle(
                        color: Color(0xFF105C3B),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: isActive
                              ? const Color(0xFF138A4B)
                              : const Color(0xFF8A9290),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF138A4B)
                                : const Color(0xFF707975),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final editButton = FilledButton.icon(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEAF6EF),
              foregroundColor: const Color(0xFF138A4B),
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text(
              'Edit Section',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: editButton,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              editButton,
            ],
          );
        },
      ),
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid({required this.onTap});

  final ValueChanged<String> onTap;

  static const List<_ManagementItem> _items = [
    _ManagementItem(
      title: 'Attendance',
      subtitle: 'Mark and manage attendance',
      icon: Icons.fact_check_outlined,
    ),
    _ManagementItem(
      title: 'Add Monitor',
      subtitle: 'Assign or manage section monitor',
      icon: Icons.person_outline_rounded,
    ),
    _ManagementItem(
      title: 'Subjects & Teacher',
      subtitle: 'Manage subjects and assigned teachers',
      icon: Icons.school_outlined,
    ),
    _ManagementItem(
      title: 'Time Table',
      subtitle: 'Create and manage the class timetable',
      icon: Icons.calendar_month_outlined,
    ),
    _ManagementItem(
      title: 'Exam Date Sheet',
      subtitle: 'Manage exam dates for this section',
      icon: Icons.description_outlined,
    ),
    _ManagementItem(
      title: 'All Students',
      subtitle: 'View and manage students in this section',
      icon: Icons.groups_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050 ? 2 : 1;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _ManagementCard(
                item: item,
                onTap: () => onTap(item.title),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ManagementItem {
  const _ManagementItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.item,
    required this.onTap,
  });

  final _ManagementItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE7EEE9)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item.icon,
                  color: const Color(0xFF138A4B),
                  size: 29,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Color(0xFF172B24),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF758078),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8A948D),
                size: 27,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionSummary extends StatelessWidget {
  const _SectionSummary({
    required this.studentCount,
    required this.isLoadingStudents,
    required this.studentCountError,
    required this.onRetry,
    required this.subjectsCount,
    required this.teachersCount,
    required this.isLoadingSectionSummary,
    required this.sectionSummaryError,
    required this.onRetrySectionSummary,
    required this.monitorName,
    required this.monitorEmail,
    required this.isLoadingMonitor,
    required this.monitorError,
    required this.onRetryMonitor,
  });

  final int? studentCount;
  final bool isLoadingStudents;
  final String? studentCountError;
  final VoidCallback onRetry;

  final int? subjectsCount;
  final int? teachersCount;
  final bool isLoadingSectionSummary;
  final String? sectionSummaryError;
  final VoidCallback onRetrySectionSummary;

  final String? monitorName;
  final String? monitorEmail;
  final bool isLoadingMonitor;
  final String? monitorError;
  final VoidCallback onRetryMonitor;

  @override
  Widget build(BuildContext context) {
    const items = [
      _SummaryItem(
        title: 'Students',
        icon: Icons.groups_outlined,
      ),
      _SummaryItem(
        title: 'Subjects',
        icon: Icons.menu_book_outlined,
      ),
      _SummaryItem(
        title: 'Teachers',
        icon: Icons.co_present_outlined,
      ),
      _SummaryItem(
        title: 'Monitor',
        icon: Icons.verified_user_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE4EEE6),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 650 ? 4 : 2;
          const spacing = 12.0;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: 20,
            children: items.map((item) {
              final isStudents = item.title == 'Students';
              final isSubjects = item.title == 'Subjects';
              final isTeachers = item.title == 'Teachers';
              final isMonitor = item.title == 'Monitor';

              final isLoading = isStudents
                  ? isLoadingStudents
                  : (isSubjects || isTeachers)
                      ? isLoadingSectionSummary
                      : isMonitor
                          ? isLoadingMonitor
                          : false;

              final hasError = isStudents
                  ? studentCountError != null
                  : (isSubjects || isTeachers)
                      ? sectionSummaryError != null
                      : isMonitor
                          ? monitorError != null
                          : false;

              final int? count = isStudents
                  ? studentCount
                  : isSubjects
                      ? subjectsCount
                      : isTeachers
                          ? teachersCount
                          : null;

              final displayMonitorName =
                  isMonitor && monitorName != null && monitorName!.isNotEmpty;

              return SizedBox(
                width: itemWidth,
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF2E4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        item.icon,
                        color: const Color(0xFF138A4B),
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isLoading)
                      const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                        ),
                      )
                    else if (hasError)
                      IconButton(
                        tooltip: 'Retry loading information',
                        onPressed: isStudents
                            ? onRetry
                            : (isSubjects || isTeachers)
                                ? onRetrySectionSummary
                                : onRetryMonitor,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF138A4B),
                        ),
                      )
                    else
                      SizedBox(
                        height: 28,
                        child: Center(
                          child: Text(
                            isMonitor
                                ? (displayMonitorName ? monitorName! : 'Not assigned')
                                : '${count ?? 0}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: displayMonitorName
                                  ? const Color(0xFF138A4B)
                                  : const Color(0xFF172B24),
                              fontSize: isMonitor ? 12 : 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF59665E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasError)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Tap retry',
                          style: TextStyle(
                            color: Color(0xFF758078),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;
}

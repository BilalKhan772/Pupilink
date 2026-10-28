import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_models/school_models.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../../attendance/ui/screens/attendance_screen.dart';
import '../data/staff_dashboard_repository.dart';
import '../data/subject_teacher_work_repository.dart';
import 'subject_teacher_marks_screen.dart';

class StaffTeacherDashboardScreen extends ConsumerWidget {
  const StaffTeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(staffAuthControllerProvider);

    if (!auth.isLoggedIn) {
      return const Scaffold(
        body: _CenteredMessage(
          icon: Icons.lock_outline_rounded,
          title: 'Session expired',
          message: 'Please sign in again to continue.',
        ),
      );
    }

    // Class-teacher and subject-teacher responsibilities are assigned per
    // section/subject. Route either base staff role to the combined workspace
    // so one account can see its class sections and subject assignments.
    if (auth.role == 'subjectTeacher' || auth.role == 'classTeacher') {
      return ClassTeacherWorkspace(
        schoolId: auth.schoolId,
        teacherId: auth.uid,
        teacherName: auth.name,
      );
    }

    return const Scaffold(
      body: _CenteredMessage(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Dashboard unavailable',
        message: 'Your account does not have a supported teacher role.',
      ),
    );
  }
}

// ============================================================================
// SHARED HELPERS AND THEME
// ============================================================================

class _DashboardStyle {
  static const Color green = Color(0xFF138A4B);
  static const Color darkGreen = Color(0xFF105C3B);
  static const Color background = Color(0xFFF5F8F6);
  static const Color border = Color(0xFFE2EAE5);
  static const Color text = Color(0xFF1F2937);
  static const Color muted = Color(0xFF6B7280);
  static const Color paleGreen = Color(0xFFE8F5EC);
}

ThemeData _dashboardTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: _DashboardStyle.green,
      secondary: _DashboardStyle.darkGreen,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: _DashboardStyle.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: _DashboardStyle.darkGreen,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _DashboardStyle.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _DashboardStyle.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _DashboardStyle.darkGreen,
        side: const BorderSide(color: Color(0xFFB8D8C2)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

Future<String> _getClassName({
  required FirebaseFirestore db,
  required String classId,
}) async {
  if (classId.trim().isEmpty) return 'Class not available';

  final doc = await db
      .collection(FirestoreCollections.classes)
      .doc(classId)
      .get();

  if (!doc.exists) return classId;

  final data = doc.data();
  final name = data?['name'];
  if (name is String && name.trim().isNotEmpty) return name.trim();

  return classId;
}

Future<SchoolSection?> _getSection({
  required FirebaseFirestore db,
  required String sectionId,
  required String schoolId,
}) async {
  if (sectionId.trim().isEmpty) return null;

  final doc = await db
      .collection(FirestoreCollections.sections)
      .doc(sectionId)
      .get();

  if (!doc.exists) return null;

  final data = doc.data();
  if (data == null || data['schoolId'] != schoolId) return null;

  return SchoolSection.fromMap(doc.id, data);
}

String _friendlyError(Object error) {
  final message = error.toString();
  if (message.contains('permission-denied')) {
    return 'You do not have permission to view this information.';
  }
  if (message.contains('unavailable') || message.contains('network')) {
    return 'The service is temporarily unavailable. Check your connection and try again.';
  }
  return message;
}

Future<String> _loadSubjectName({
  required WidgetRef ref,
  required String schoolId,
  required TeacherAssignment assignment,
}) async {
  final subjectId = assignment.subjectId ?? '';
  if (subjectId.trim().isEmpty) return 'Subject not assigned';

  try {
    return await ref
        .read(subjectTeacherWorkRepositoryProvider)
        .getSubjectName(schoolId: schoolId, subjectId: subjectId);
  } catch (_) {
    return 'Subject unavailable';
  }
}

// ============================================================================
// SUBJECT TEACHER WORKSPACE
// ============================================================================

class SubjectTeacherWorkspace extends ConsumerStatefulWidget {
  const SubjectTeacherWorkspace({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.teacherName,
  });

  final String schoolId;
  final String teacherId;
  final String teacherName;

  @override
  ConsumerState<SubjectTeacherWorkspace> createState() =>
      _SubjectTeacherWorkspaceState();
}

class _SubjectTeacherWorkspaceState
    extends ConsumerState<SubjectTeacherWorkspace> {
  late Future<List<TeacherAssignment>> _assignmentsFuture;
  final Map<String, Future<String>> _subjectNameCache = {};

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _loadAssignments() {
    _subjectNameCache.clear();
    _assignmentsFuture = ref
        .read(staffDashboardRepositoryProvider)
        .getTeacherAssignments(
          schoolId: widget.schoolId,
          teacherId: widget.teacherId,
        );
  }

  Future<String> _subjectName(TeacherAssignment assignment) {
    final key = assignment.subjectId ?? '';
    return _subjectNameCache.putIfAbsent(
      key,
      () => _loadSubjectName(
        ref: ref,
        schoolId: widget.schoolId,
        assignment: assignment,
      ),
    );
  }

  Future<void> _refresh() async {
    setState(_loadAssignments);
    try {
      await _assignmentsFuture;
    } catch (_) {
      // FutureBuilder displays the error state.
    }
  }

  Future<void> _logout() async {
    await ref.read(staffAuthControllerProvider.notifier).signOut();
  }

  Future<List<String>> _loadAssignmentNames(
    TeacherAssignment assignment,
  ) async {
    final db = FirebaseFirestore.instance;
    final className = await _getClassName(
      db: db,
      classId: assignment.classId,
    );
    final section = await _getSection(
      db: db,
      sectionId: assignment.sectionId ?? '',
      schoolId: widget.schoolId,
    );
    return [className, section?.name ?? 'Section not available'];
  }

  Future<void> _openSubjectAssignment(
    TeacherAssignment assignment, {
    bool openMarks = false,
  }) async {
    final sectionId = assignment.sectionId ?? '';
    final subjectId = assignment.subjectId ?? '';

    if (sectionId.trim().isEmpty || subjectId.trim().isEmpty) {
      _showMessage('A valid subject and section assignment is required.');
      return;
    }

    final subjectName = await _subjectName(assignment);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectTeacherMarksScreen(
          schoolId: widget.schoolId,
          teacherId: widget.teacherId,
          assignment: assignment,
          subjectName: subjectName,
          openMarks: openMarks,
        ),
      ),
    );

    if (mounted) await _refresh();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dashboardTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Subject Teacher Dashboard'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _DashboardStyle.border),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth >= 1200
                ? 1120.0
                : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: _DashboardStyle.green,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(
                      constraints.maxWidth < 600 ? 16 : 28,
                    ),
                    children: [
                      _WelcomeCard(
                        name: widget.teacherName,
                        subtitle:
                            'Manage your assigned subjects and academic work.',
                      ),
                      const SizedBox(height: 26),
                      const _SectionHeading(
                        title: 'My Subject Assignments',
                        subtitle:
                            'View tests and enter marks for your assigned subjects.',
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<TeacherAssignment>>(
                        future: _assignmentsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _LoadingPanel();
                          }
                          if (snapshot.hasError) {
                            return _MessageCard(
                              icon: Icons.cloud_off_outlined,
                              title: 'Assignments could not be loaded',
                              message: _friendlyError(snapshot.error!),
                              onRetry: _refresh,
                            );
                          }

                          final assignments = (snapshot.data ?? [])
                              .where((a) =>
                                  a.isActive &&
                                  (a.subjectId ?? '').trim().isNotEmpty &&
                                  (a.sectionId ?? '').trim().isNotEmpty)
                              .toList();

                          if (assignments.isEmpty) {
                            return const _MessageCard(
                              icon: Icons.menu_book_outlined,
                              title: 'No active subject assignments',
                              message:
                                  'Ask your school administrator to review your subject assignments.',
                            );
                          }

                          return _ResponsiveCardGrid(
                            itemCount: assignments.length,
                            itemBuilder: (index) {
                              final assignment = assignments[index];
                              return _SubjectAssignmentCard(
                                assignment: assignment,
                                loadAssignmentNames: _loadAssignmentNames,
                                loadSubjectName: _subjectName,
                                onTests: () =>
                                    _openSubjectAssignment(assignment),
                                onMarks: () => _openSubjectAssignment(
                                  assignment,
                                  openMarks: true,
                                ),
                              );
                            },
                          );
                        },
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
}

// ============================================================================
// CLASS TEACHER WORKSPACE
// ============================================================================

class ClassTeacherWorkspace extends ConsumerStatefulWidget {
  const ClassTeacherWorkspace({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.teacherName,
  });

  final String schoolId;
  final String teacherId;
  final String teacherName;

  @override
  ConsumerState<ClassTeacherWorkspace> createState() =>
      _ClassTeacherWorkspaceState();
}

class _ClassTeacherWorkspaceState
    extends ConsumerState<ClassTeacherWorkspace> {
  late Future<List<SchoolSection>> _sectionsFuture;
  late Future<List<TeacherAssignment>> _assignmentsFuture;
  final Map<String, Future<String>> _subjectNameCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadSections();
    _loadAssignments();
  }

  // Keep older section documents that have no isActive field, but exclude
  // explicitly inactive sections.
  void _loadSections() {
    _sectionsFuture = FirebaseFirestore.instance
        .collection(FirestoreCollections.sections)
        .where('schoolId', isEqualTo: widget.schoolId)
        .where('classTeacherId', isEqualTo: widget.teacherId)
        .get()
        .then((snapshot) {
      final sections = snapshot.docs
          .where((doc) => doc.data()['isActive'] != false)
          .map((doc) => SchoolSection.fromMap(doc.id, doc.data()))
          .toList();

      sections.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return sections;
    });
  }

  void _loadAssignments() {
    _subjectNameCache.clear();
    _assignmentsFuture = ref
        .read(staffDashboardRepositoryProvider)
        .getTeacherAssignments(
          schoolId: widget.schoolId,
          teacherId: widget.teacherId,
        );
  }

  Future<String> _subjectName(TeacherAssignment assignment) {
    final key = assignment.subjectId ?? '';
    return _subjectNameCache.putIfAbsent(
      key,
      () => _loadSubjectName(
        ref: ref,
        schoolId: widget.schoolId,
        assignment: assignment,
      ),
    );
  }

  Future<void> _refresh() async {
    setState(_loadData);
    try {
      await Future.wait([_sectionsFuture, _assignmentsFuture]);
    } catch (_) {
      // FutureBuilder widgets display errors.
    }
  }

  Future<void> _logout() async {
    await ref.read(staffAuthControllerProvider.notifier).signOut();
  }

  Future<void> _openAttendance(SchoolSection section) async {
    if (section.id.trim().isEmpty ||
        section.classId.trim().isEmpty ||
        widget.schoolId.trim().isEmpty ||
        widget.teacherId.trim().isEmpty) {
      _showMessage('Required school, class, section, or teacher information is missing.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceScreen(
          schoolId: widget.schoolId,
          classId: section.classId,
          sectionId: section.id,
          staffId: widget.teacherId,
        ),
      ),
    );

    if (mounted) await _refresh();
  }

  Future<List<String>> _loadAssignmentNames(
    TeacherAssignment assignment,
  ) async {
    final db = FirebaseFirestore.instance;
    final className = await _getClassName(
      db: db,
      classId: assignment.classId,
    );
    final section = await _getSection(
      db: db,
      sectionId: assignment.sectionId ?? '',
      schoolId: widget.schoolId,
    );
    return [className, section?.name ?? 'Section not available'];
  }

  Future<void> _openSubjectAssignment(
    TeacherAssignment assignment, {
    bool openMarks = false,
  }) async {
    final sectionId = assignment.sectionId ?? '';
    final subjectId = assignment.subjectId ?? '';

    if (sectionId.trim().isEmpty || subjectId.trim().isEmpty) {
      _showMessage('A valid subject and section assignment is required.');
      return;
    }

    final subjectName = await _subjectName(assignment);
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectTeacherMarksScreen(
          schoolId: widget.schoolId,
          teacherId: widget.teacherId,
          assignment: assignment,
          subjectName: subjectName,
          openMarks: openMarks,
        ),
      ),
    );

    if (mounted) await _refresh();
  }

  Future<void> _openClassTeacherTestsMarks(SchoolSection section) async {
    if (widget.schoolId.trim().isEmpty ||
        widget.teacherId.trim().isEmpty ||
        section.id.trim().isEmpty) {
      _showMessage('Required school, teacher, or section information is missing.');
      return;
    }

    try {
      final assignments = await ref
          .read(staffDashboardRepositoryProvider)
          .getSectionAssignments(
            schoolId: widget.schoolId,
            sectionId: section.id,
          );

      final myAssignments = assignments.where((assignment) {
        return assignment.teacherId == widget.teacherId &&
            assignment.isActive &&
            (assignment.subjectId ?? '').trim().isNotEmpty &&
            (assignment.sectionId ?? '').trim() == section.id;
      }).toList();

      if (!mounted) return;

      if (myAssignments.isEmpty) {
        _showMessage(
          'No active subject assignment was found for this section. '
          'Ask your school administrator to assign a subject to you.',
        );
        return;
      }

      TeacherAssignment? selectedAssignment;

      if (myAssignments.length == 1) {
        selectedAssignment = myAssignments.first;
      } else {
        selectedAssignment = await showModalBottomSheet<TeacherAssignment>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (sheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      'Select a Subject',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _DashboardStyle.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...myAssignments.map((assignment) {
                      return FutureBuilder<String>(
                        future: _subjectName(assignment),
                        builder: (context, subjectSnapshot) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: _DashboardStyle.paleGreen,
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: _DashboardStyle.darkGreen,
                                ),
                              ),
                              title: Text(
                                subjectSnapshot.data ?? 'Loading subject…',
                              ),
                              subtitle: const Text('Tests and marks'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.pop(sheetContext, assignment);
                              },
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      }

      if (!mounted || selectedAssignment == null) return;
      await _openSubjectAssignment(selectedAssignment);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to open Tests & Marks: ${_friendlyError(error)}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _dashboardTheme(context),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _DashboardStyle.border),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth >= 1200
                ? 1120.0
                : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: _DashboardStyle.green,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(
                      constraints.maxWidth < 600 ? 16 : 28,
                    ),
                    children: [
                      _WelcomeCard(
                        name: widget.teacherName,
                        subtitle:
                            'Manage your classes, attendance, and subject assignments.',
                      ),
                      const SizedBox(height: 26),
                      const _SectionHeading(
                        title: 'My Sections',
                        subtitle:
                            'Your assigned classes, subjects, and attendance tools.',
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<SchoolSection>>(
                        future: _sectionsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _LoadingPanel();
                          }
                          if (snapshot.hasError) {
                            return _MessageCard(
                              icon: Icons.cloud_off_outlined,
                              title: 'Sections could not be loaded',
                              message: _friendlyError(snapshot.error!),
                              onRetry: _refresh,
                            );
                          }

                          final sections = snapshot.data ?? [];
                          if (sections.isEmpty) {
                            return const _MessageCard(
                              icon: Icons.class_outlined,
                              title: 'No class sections assigned',
                              message:
                                  'Ask your school administrator to assign you as the Class Teacher of a section. After the assignment is saved, refresh this page.',
                            );
                          }

                          return _ResponsiveCardGrid(
                            itemCount: sections.length,
                            itemBuilder: (index) {
                              final section = sections[index];
                              return _ClassSectionCard(
                                section: section,
                                teacherAssignmentsFuture: _assignmentsFuture,
                                loadSubjectName: _subjectName,
                                onAttendance: () => _openAttendance(section),
                                onTestsMarks: () =>
                                    _openClassTeacherTestsMarks(section),
                                loadClassName: () => _getClassName(
                                  db: FirebaseFirestore.instance,
                                  classId: section.classId,
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      const _SectionHeading(
                        title: 'My Subject Assignments',
                        subtitle:
                            'Access tests and enter marks for subjects assigned to you across sections.',
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<TeacherAssignment>>(
                        future: _assignmentsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const _LoadingPanel();
                          }
                          if (snapshot.hasError) {
                            return _MessageCard(
                              icon: Icons.cloud_off_outlined,
                              title: 'Subject assignments could not be loaded',
                              message: _friendlyError(snapshot.error!),
                              onRetry: _refresh,
                            );
                          }

                          final assignments = (snapshot.data ?? [])
                              .where((assignment) =>
                                  assignment.isActive &&
                                  (assignment.subjectId ?? '').trim().isNotEmpty &&
                                  (assignment.sectionId ?? '').trim().isNotEmpty)
                              .toList();

                          if (assignments.isEmpty) {
                            return const _MessageCard(
                              icon: Icons.menu_book_outlined,
                              title: 'No active subject assignments',
                              message:
                                  'Your section may still be assigned to you. Ask your school administrator to assign the subjects you teach.',
                            );
                          }

                          return _ResponsiveCardGrid(
                            itemCount: assignments.length,
                            itemBuilder: (index) {
                              final assignment = assignments[index];
                              return _SubjectAssignmentCard(
                                assignment: assignment,
                                loadAssignmentNames: _loadAssignmentNames,
                                loadSubjectName: _subjectName,
                                onTests: () =>
                                    _openSubjectAssignment(assignment),
                                onMarks: () => _openSubjectAssignment(
                                  assignment,
                                  openMarks: true,
                                ),
                              );
                            },
                          );
                        },
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
}

// ============================================================================
// RESPONSIVE CARDS
// ============================================================================

class _ClassSectionCard extends StatelessWidget {
  const _ClassSectionCard({
    required this.section,
    required this.teacherAssignmentsFuture,
    required this.loadSubjectName,
    required this.onAttendance,
    required this.onTestsMarks,
    required this.loadClassName,
  });

  final SchoolSection section;
  final Future<List<TeacherAssignment>> teacherAssignmentsFuture;
  final Future<String> Function(TeacherAssignment) loadSubjectName;
  final VoidCallback onAttendance;
  final VoidCallback onTestsMarks;
  final Future<String> Function() loadClassName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _IconTile(icon: Icons.class_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Section ${section.name}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _DashboardStyle.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      FutureBuilder<String>(
                        future: loadClassName(),
                        builder: (context, snapshot) => Text(
                          'Class: ${snapshot.data ?? section.classId}',
                          style: const TextStyle(
                            color: _DashboardStyle.muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const _StatusPill(label: 'Active'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Assigned Subjects',
              style: TextStyle(
                fontSize: 12,
                color: _DashboardStyle.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<TeacherAssignment>>(
              future: teacherAssignmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: _DashboardStyle.green,
                    ),
                  );
                }

                final assignments = (snapshot.data ?? [])
                    .where((assignment) =>
                        assignment.isActive &&
                        assignment.sectionId == section.id &&
                        (assignment.subjectId ?? '').trim().isNotEmpty)
                    .toList();

                if (assignments.isEmpty) {
                  return const Text(
                    'No subjects have been assigned to you in this section.',
                    style: TextStyle(
                      color: _DashboardStyle.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  );
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: assignments.map((assignment) {
                    return FutureBuilder<String>(
                      future: loadSubjectName(assignment),
                      builder: (context, subjectSnapshot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _DashboardStyle.paleGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.menu_book_outlined,
                                size: 15,
                                color: _DashboardStyle.darkGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                subjectSnapshot.data ?? 'Loading subject…',
                                style: const TextStyle(
                                  color: _DashboardStyle.darkGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                OutlinedButton.icon(
                  onPressed: onAttendance,
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Attendance'),
                ),
                FilledButton.icon(
                  onPressed: onTestsMarks,
                  icon: const Icon(Icons.edit_note_rounded, size: 19),
                  label: const Text('Tests & Marks'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectAssignmentCard extends StatelessWidget {
  const _SubjectAssignmentCard({
    required this.assignment,
    required this.loadAssignmentNames,
    required this.loadSubjectName,
    required this.onTests,
    required this.onMarks,
  });

  final TeacherAssignment assignment;
  final Future<List<String>> Function(TeacherAssignment) loadAssignmentNames;
  final Future<String> Function(TeacherAssignment) loadSubjectName;
  final VoidCallback onTests;
  final VoidCallback onMarks;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconTile(icon: Icons.menu_book_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<String>(
                    future: loadSubjectName(assignment),
                    builder: (context, snapshot) => Text(
                      snapshot.data ?? 'Loading subject…',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _DashboardStyle.text,
                      ),
                    ),
                  ),
                ),
                const _StatusPill(label: 'Active'),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: loadAssignmentNames(assignment),
              builder: (context, snapshot) {
                final className = snapshot.data != null
                    ? snapshot.data![0]
                    : assignment.classId;
                final sectionName = snapshot.data != null
                    ? snapshot.data![1]
                    : 'Loading section…';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(label: 'Class', value: className),
                    const SizedBox(height: 5),
                    _DetailLine(label: 'Section', value: sectionName),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                OutlinedButton.icon(
                  onPressed: onTests,
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: const Text('Tests'),
                ),
                FilledButton.icon(
                  onPressed: onMarks,
                  icon: const Icon(Icons.edit_note_rounded, size: 19),
                  label: const Text('Enter Marks'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED DASHBOARD WIDGETS
// ============================================================================

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF0F8F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DashboardStyle.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF0E3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: _DashboardStyle.darkGreen,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${name.trim().isEmpty ? 'Teacher' : name}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: _DashboardStyle.darkGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _DashboardStyle.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _DashboardStyle.text,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _DashboardStyle.muted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _DashboardStyle.paleGreen,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: _DashboardStyle.darkGreen, size: 23),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F5E9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _DashboardStyle.darkGreen,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: _DashboardStyle.muted,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _DashboardStyle.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 34),
      child: Center(
        child: CircularProgressIndicator(color: _DashboardStyle.green),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DashboardStyle.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5ED),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _DashboardStyle.darkGreen, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _DashboardStyle.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _DashboardStyle.muted,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: _DashboardStyle.darkGreen),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveCardGrid extends StatelessWidget {
  const _ResponsiveCardGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final columns = constraints.maxWidth >= 900
            ? 2
            : 1;
        final itemWidth = columns == 2
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(itemCount, (index) {
            return SizedBox(
              width: itemWidth,
              child: itemBuilder(index),
            );
          }),
        );
      },
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_models/school_models.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../../students/ui/screens/all_students_screen.dart';
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
        body: Center(child: Text('Please login again.')),
      );
    }

    if (auth.role == 'subjectTeacher') {
      return SubjectTeacherWorkspace(
        schoolId: auth.schoolId,
        teacherId: auth.uid,
        teacherName: auth.name,
      );
    }

    if (auth.role == 'classTeacher') {
      return ClassTeacherWorkspace(
        schoolId: auth.schoolId,
        teacherId: auth.uid,
        teacherName: auth.name,
      );
    }

    return const Scaffold(
      body: Center(
        child: Text('Is role ke liye dashboard available nahi hai.'),
      ),
    );
  }
}

// ============================================================
// SHARED HELPERS
// ============================================================

Future<String> _getClassName({
  required FirebaseFirestore db,
  required String classId,
}) async {
  if (classId.trim().isEmpty) return classId;

  final doc = await db
      .collection(FirestoreCollections.classes)
      .doc(classId)
      .get();

  if (!doc.exists) return classId;

  final data = doc.data();
  final name = data?['name'];

  if (name is String && name.trim().isNotEmpty) {
    return name.trim();
  }

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

  if (data == null || data['schoolId'] != schoolId) {
    return null;
  }

  return SchoolSection.fromMap(doc.id, data);
}

Future<void> _openStudents({
  required BuildContext context,
  required String sectionId,
  required String sectionName,
  required String className,
}) async {
  if (sectionId.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Is assignment ke saath section assign nahi hai.',
        ),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AllStudentsScreen(
        sectionId: sectionId,
        sectionName: sectionName,
        className: className,
      ),
    ),
  );
}

// ============================================================
// SUBJECT TEACHER WORKSPACE
// ============================================================

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

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _loadAssignments() {
    _assignmentsFuture = ref
        .read(staffDashboardRepositoryProvider)
        .getTeacherAssignments(
          schoolId: widget.schoolId,
          teacherId: widget.teacherId,
        );
  }

  Future<void> _refresh() async {
    setState(_loadAssignments);

    try {
      await _assignmentsFuture;
    } catch (_) {
      // FutureBuilder error display karega.
    }
  }

  Future<void> _logout() async {
    await ref
        .read(staffAuthControllerProvider.notifier)
        .signOut();
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

    return [
      className,
      section?.name ?? assignment.sectionId ?? 'Not set',
    ];
  }

  Future<String> _loadSubjectName(
    TeacherAssignment assignment,
  ) async {
    final subjectId = assignment.subjectId ?? '';

    if (subjectId.trim().isEmpty) {
      return 'Subject not assigned';
    }

    try {
      return await ref
          .read(subjectTeacherWorkRepositoryProvider)
          .getSubjectName(
            schoolId: widget.schoolId,
            subjectId: subjectId,
          );
    } catch (_) {
      return 'Subject unavailable';
    }
  }

  Future<void> _openTestScreen(
    TeacherAssignment assignment, {
    bool openMarks = false,
  }) async {
    final sectionId = assignment.sectionId ?? '';
    final subjectId = assignment.subjectId ?? '';

    if (sectionId.trim().isEmpty || subjectId.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Test aur marks ke liye subject aur section assignment required hai.',
          ),
        ),
      );
      return;
    }

    String subjectName;

    try {
      subjectName = await _loadSubjectName(assignment);
    } catch (_) {
      subjectName = 'Subject';
    }

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

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _openAssignmentStudents(
    TeacherAssignment assignment,
    String sectionName,
    String className,
  ) async {
    await _openStudents(
      context: context,
      sectionId: assignment.sectionId ?? '',
      sectionName: sectionName,
      className: className,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Teacher Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WelcomeCard(
              name: widget.teacherName,
              subtitle:
                  'Apne assigned subjects aur sections manage karein.',
            ),
            const SizedBox(height: 20),
            const Text(
              'My Assignments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<TeacherAssignment>>(
              future: _assignmentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _MessageCard(
                    message:
                        'Assignments load nahi ho sakin.\n'
                        '${snapshot.error}',
                    onRetry: _refresh,
                  );
                }

                final assignments = snapshot.data ?? [];

                if (assignments.isEmpty) {
                  return const _MessageCard(
                    message:
                        'Abhi aapko koi active subject assignment nahi mili. '
                        'School Admin se assignment check karwaein.',
                  );
                }

                return Column(
                  children: assignments.map((assignment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FutureBuilder<List<String>>(
                          future: _loadAssignmentNames(assignment),
                          builder: (context, namesSnapshot) {
                            final names = namesSnapshot.data;

                            final className = names != null
                                ? names[0]
                                : assignment.classId;

                            final sectionName = names != null
                                ? names[1]
                                : assignment.sectionId ?? 'Not set';

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.menu_book,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FutureBuilder<String>(
                                        future: _loadSubjectName(
                                          assignment,
                                        ),
                                        builder: (context, subjectSnapshot) {
                                          final subjectName =
                                              subjectSnapshot.data ??
                                                  (subjectSnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting
                                                      ? 'Loading subject...'
                                                      : 'Subject unavailable');

                                          return Text(
                                            'Subject: $subjectName',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('Class: $className'),
                                Text('Section: $sectionName'),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _openTestScreen(assignment),
                                      icon: const Icon(
                                        Icons.quiz_outlined,
                                      ),
                                      label: const Text('Tests'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _openTestScreen(
                                        assignment,
                                        openMarks: true,
                                      ),
                                      icon: const Icon(Icons.edit_note),
                                      label: const Text('Enter Marks'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed:
                                          namesSnapshot.connectionState ==
                                                  ConnectionState.waiting
                                              ? null
                                              : () => _openAssignmentStudents(
                                                    assignment,
                                                    sectionName,
                                                    className,
                                                  ),
                                      icon: const Icon(
                                        Icons.people_outline,
                                      ),
                                      label: const Text('Students'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CLASS TEACHER WORKSPACE
// ============================================================

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

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  void _loadSections() {
    _sectionsFuture = FirebaseFirestore.instance
        .collection(FirestoreCollections.sections)
        .where('schoolId', isEqualTo: widget.schoolId)
        .where('classTeacherId', isEqualTo: widget.teacherId)
        .where('isActive', isEqualTo: true)
        .get()
        .then(
          (snapshot) => snapshot.docs
              .map(
                (doc) => SchoolSection.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> _refresh() async {
    setState(_loadSections);

    try {
      await _sectionsFuture;
    } catch (_) {
      // FutureBuilder error display karega.
    }
  }

  Future<void> _logout() async {
    await ref
        .read(staffAuthControllerProvider.notifier)
        .signOut();
  }

  Future<void> _openSectionStudents(
    SchoolSection section,
  ) async {
    final className = await _getClassName(
      db: FirebaseFirestore.instance,
      classId: section.classId,
    );

    if (!mounted) return;

    await _openStudents(
      context: context,
      sectionId: section.id,
      sectionName: section.name,
      className: className,
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature ka module abhi connect nahi hua hai.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Teacher Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WelcomeCard(
              name: widget.teacherName,
              subtitle:
                  'Apni assigned class aur attendance manage karein.',
            ),
            const SizedBox(height: 20),
            const Text(
              'My Sections',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<SchoolSection>>(
              future: _sectionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _MessageCard(
                    message:
                        'Sections load nahi ho sakein.\n'
                        '${snapshot.error}',
                    onRetry: _refresh,
                  );
                }

                final sections = snapshot.data ?? [];

                if (sections.isEmpty) {
                  return const _MessageCard(
                    message:
                        'Aapke naam par koi active section assign nahi hai. '
                        'School Admin se class-teacher assignment check karwaein.',
                  );
                }

                return Column(
                  children: sections.map((section) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FutureBuilder<String>(
                          future: _getClassName(
                            db: FirebaseFirestore.instance,
                            classId: section.classId,
                          ),
                          builder: (context, classSnapshot) {
                            final className =
                                classSnapshot.data ?? section.classId;

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.class_outlined,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Section: ${section.name}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text('Class: $className'),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _openSectionStudents(section),
                                      icon: const Icon(
                                        Icons.people_outline,
                                      ),
                                      label: const Text('Students'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _showComingSoon('Attendance'),
                                      icon: const Icon(
                                        Icons.fact_check_outlined,
                                      ),
                                      label: const Text('Attendance'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _showComingSoon('Tests and marks'),
                                      icon: const Icon(Icons.edit_note),
                                      label: const Text('Tests & Marks'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHARED UI
// ============================================================

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${name.isEmpty ? 'Teacher' : name}',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
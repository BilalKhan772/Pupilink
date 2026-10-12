
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../../auth/logic/staff_auth_controller.dart';
import '../../logic/students_controller.dart';
import '../widgets/student_card.dart';
import '../widgets/student_summary_card.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';
import 'student_overview_screen.dart';
import 'student_search_screen.dart';

class AllStudentsScreen extends ConsumerStatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  ConsumerState<AllStudentsScreen> createState() =>
      _AllStudentsScreenState();
}

class _AllStudentsScreenState
    extends ConsumerState<AllStudentsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String? _loadedSchoolId;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      final schoolId =
          ref.read(staffAuthControllerProvider).schoolId.trim();

      if (schoolId.isNotEmpty) {
        _loadedSchoolId = schoolId;
        ref.read(studentsControllerProvider.notifier).load(schoolId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh(String schoolId) async {
    await ref.read(studentsControllerProvider.notifier).load(schoolId);
  }

  Future<void> _add(String schoolId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AddStudentScreen(),
      ),
    );

    if (result == true && mounted) {
      await _refresh(schoolId);
    }
  }

  Future<void> _edit(Student student, String schoolId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditStudentScreen(student: student),
      ),
    );

    if (result == true && mounted) {
      await _refresh(schoolId);
    }
  }

  Future<void> _toggle(Student student, String schoolId) async {
    // Student ke current status ko ulta karein.
    final bool nextActive = !student.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          nextActive ? 'Activate student?' : 'Deactivate student?',
        ),
        content: Text(
          'Kya aap "${student.name}" ka status change karna chahte hain?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(studentsControllerProvider.notifier)
        .setActive(student, nextActive);

    if (!mounted) return;

    final error =
        ref.read(studentsControllerProvider).errorMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Student status update ho gaya.'
              : error ?? 'Student status update nahi ho saka.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(staffAuthControllerProvider);
    final state = ref.watch(studentsControllerProvider);
    final schoolId = auth.schoolId.trim();

    if (!auth.isLoggedIn || schoolId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Students')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'School profile ya School ID nahi mili. '
              'Please dobara login karein.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Agar logged-in school badal jaye to uska data reload karein.
    if (_loadedSchoolId != schoolId) {
      _loadedSchoolId = schoolId;

      Future.microtask(() {
        if (!mounted) return;

        ref.read(studentsControllerProvider.notifier).load(schoolId);
      });
    }

    final students = state.filteredStudents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            tooltip: 'Search by admission number',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentSearchScreen(),
                ),
              );
            },
            icon: const Icon(Icons.manage_search),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading
                ? null
                : () => _refresh(schoolId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSaving ? null : () => _add(schoolId),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Student'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(schoolId),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Student management',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apne school ke students manage karein.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // Summary cards.
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 650;

                final cards = [
                  const _SummaryItem(
                    title: 'Total students',
                    icon: Icons.groups_outlined,
                    color: Color(0xFF2563EB),
                  ),
                  const _SummaryItem(
                    title: 'Active',
                    icon: Icons.check_circle_outline,
                    color: Color(0xFF16A34A),
                  ),
                  const _SummaryItem(
                    title: 'Inactive',
                    icon: Icons.pause_circle_outline,
                    color: Color(0xFF64748B),
                  ),
                ];

                final values = [
                  state.students.length,
                  state.activeCount,
                  state.inactiveCount,
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (var i = 0; i < cards.length; i++)
                        StudentSummaryCard(
                          title: cards[i].title,
                          value: values[i],
                          icon: cards[i].icon,
                          color: cards[i].color,
                        ),
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      Expanded(
                        child: StudentSummaryCard(
                          title: cards[i].title,
                          value: values[i],
                          icon: cards[i].icon,
                          color: cards[i].color,
                        ),
                      ),
                      if (i < cards.length - 1)
                        const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Search students.
            TextField(
              controller: _searchController,
              onChanged: (query) {
                ref
                    .read(studentsControllerProvider.notifier)
                    .search(query);

                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Name, admission number, class...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(studentsControllerProvider.notifier)
                              .search('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            if (state.isLoading && state.students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Koi student nahi mila. '
                  'Add Student se naya student banayein.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1050
                      ? 3
                      : constraints.maxWidth >= 650
                          ? 2
                          : 1;

                  final width =
                      (constraints.maxWidth - (columns - 1) * 12) /
                          columns;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final student in students)
                        SizedBox(
                          width: width,
                          child: StudentCard(
                            student: student,
                            onOpen: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StudentOverviewScreen(
                                    student: student,
                                  ),
                                ),
                              );
                            },
                            onEdit: () => _edit(student, schoolId),
                            onToggleActive: () =>
                                _toggle(student, schoolId),
                          ),
                        ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 88),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}

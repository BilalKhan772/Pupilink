import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_models/school_models.dart';

import '../data/subject_teacher_work_repository.dart';

const Color _green = Color(0xFF138A4B);
const Color _darkGreen = Color(0xFF105C3B);
const Color _background = Color(0xFFF4F8F5);
const Color _border = Color(0xFFDDE9E1);
const Color _text = Color(0xFF202B25);
const Color _muted = Color(0xFF68766E);
const Color _softGreen = Color(0xFFEAF6EF);

/// Loads readable class and section names while verifying school ownership.
Future<List<String>> _loadClassSectionNames({
  required String schoolId,
  required String classId,
  required String sectionId,
}) async {
  final db = FirebaseFirestore.instance;
  var className = classId;
  var sectionName = sectionId;

  if (classId.trim().isNotEmpty) {
    final classDoc = await db
        .collection(FirestoreCollections.classes)
        .doc(classId)
        .get();
    final data = classDoc.data();
    if (classDoc.exists && data != null && data['schoolId'] == schoolId) {
      final name = data['name'];
      if (name is String && name.trim().isNotEmpty) {
        className = name.trim();
      }
    }
  }

  if (sectionId.trim().isNotEmpty) {
    final sectionDoc = await db
        .collection(FirestoreCollections.sections)
        .doc(sectionId)
        .get();
    final data = sectionDoc.data();
    if (sectionDoc.exists && data != null && data['schoolId'] == schoolId) {
      final name = data['name'];
      if (name is String && name.trim().isNotEmpty) {
        sectionName = name.trim();
      }
    }
  }

  return [
    className.trim().isEmpty ? 'Not assigned' : className,
    sectionName.trim().isEmpty ? 'Not assigned' : sectionName,
  ];
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month - 1]} ${date.year}';
}

String _formatMarks(double marks) =>
    marks.toStringAsFixed(marks % 1 == 0 ? 0 : 1);

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: _green, size: 20),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _green, width: 1.5),
    ),
  );
}

ButtonStyle _primaryButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _green,
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color(0xFFB7D7C2),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class SubjectTeacherMarksScreen extends ConsumerStatefulWidget {
  const SubjectTeacherMarksScreen({
    super.key,
    required this.schoolId,
    required this.teacherId,
    required this.assignment,
    required this.subjectName,
    this.openMarks = false,
  });

  final String schoolId;
  final String teacherId;
  final TeacherAssignment assignment;
  final String subjectName;
  final bool openMarks;

  @override
  ConsumerState<SubjectTeacherMarksScreen> createState() =>
      _SubjectTeacherMarksScreenState();
}

class _SubjectTeacherMarksScreenState
    extends ConsumerState<SubjectTeacherMarksScreen> {
  late Future<List<SchoolTest>> _testsFuture;
  late Future<List<String>> _classSectionFuture;
  bool _creatingTest = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _testsFuture = ref.read(subjectTeacherWorkRepositoryProvider).getTests(
          schoolId: widget.schoolId,
          sectionId: widget.assignment.sectionId ?? '',
          subjectId: widget.assignment.subjectId ?? '',
        );
    _classSectionFuture = _loadClassSectionNames(
      schoolId: widget.schoolId,
      classId: widget.assignment.classId,
      sectionId: widget.assignment.sectionId ?? '',
    );
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _loadData();
    });
    try {
      await Future.wait([_testsFuture, _classSectionFuture]);
    } catch (_) {
      // The appropriate FutureBuilder displays a helpful error and retry action.
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? _darkGreen : const Color(0xFFB42318),
          content: Text(message),
        ),
      );
  }

  Future<void> _createTest() async {
    if (_creatingTest) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final totalController = TextEditingController(text: '50');
    final passingController = TextEditingController(text: '20');
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final screenWidth = MediaQuery.sizeOf(dialogContext).width;
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.assignment_add, color: _green),
                  SizedBox(width: 10),
                  Expanded(child: Text('Create Test')),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.65,
                ),
                child: SizedBox(
                  width: screenWidth < 560 ? screenWidth - 80 : 440,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: titleController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _inputDecoration(
                              label: 'Test Name',
                              hint: 'e.g. Unit Test 1',
                              icon: Icons.title_rounded,
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter a test name.'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: descriptionController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: _inputDecoration(
                              label: 'Chapters / Syllabus (Optional)',
                              hint: 'Enter covered topics',
                              icon: Icons.menu_book_outlined,
                            ),
                            minLines: 2,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: _background,
                              border: Border.all(color: _border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.calendar_month_rounded,
                                color: _green,
                              ),
                              title: const Text('Test Date'),
                              subtitle: Text(_formatDate(selectedDate)),
                              trailing: const Icon(Icons.edit_calendar_outlined),
                              onTap: saving
                                  ? null
                                  : () async {
                                      final date = await showDatePicker(
                                        context: dialogContext,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (date != null) {
                                        setDialogState(() => selectedDate = date);
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 360;
                              final totalField = TextFormField(
                                controller: totalController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: _inputDecoration(
                                  label: 'Total Marks',
                                  icon: Icons.score_outlined,
                                ),
                                validator: (value) {
                                  final total = double.tryParse(value ?? '');
                                  if (total == null ||
                                      !total.isFinite ||
                                      total <= 0) {
                                    return 'Enter valid total marks.';
                                  }
                                  return null;
                                },
                              );
                              final passingField = TextFormField(
                                controller: passingController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: _inputDecoration(
                                  label: 'Passing Marks',
                                  icon: Icons.flag_outlined,
                                ),
                                validator: (value) {
                                  final passing =
                                      double.tryParse(value ?? '');
                                  final total =
                                      double.tryParse(totalController.text);
                                  if (passing == null ||
                                      !passing.isFinite ||
                                      passing < 0 ||
                                      total == null ||
                                      passing > total) {
                                    return 'Must be between 0 and total marks.';
                                  }
                                  return null;
                                },
                              );
                              if (compact) {
                                return Column(
                                  children: [
                                    totalField,
                                    const SizedBox(height: 14),
                                    passingField,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: totalField),
                                  const SizedBox(width: 12),
                                  Expanded(child: passingField),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  style: _primaryButtonStyle(),
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final total = double.parse(totalController.text);
                          final passing = double.parse(passingController.text);
                          if (passing > total) {
                            _showDialogMessage(
                              dialogContext,
                              'Passing marks cannot exceed total marks.',
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          if (mounted) setState(() => _creatingTest = true);
                          try {
                            await ref
                                .read(subjectTeacherWorkRepositoryProvider)
                                .createTest(
                                  schoolId: widget.schoolId,
                                  teacherId: widget.teacherId,
                                  assignment: widget.assignment,
                                  subjectName: widget.subjectName,
                                  title: titleController.text.trim(),
                                  description:
                                      descriptionController.text.trim(),
                                  testDate: selectedDate,
                                  totalMarks: total,
                                  passingMarks: passing,
                                );

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            await _refresh();
                            _showMessage('Test created successfully.', success: true);
                          } catch (error) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() => saving = false);
                            _showDialogMessage(
                              dialogContext,
                              'Unable to save the test. $error',
                            );
                          } finally {
                            if (mounted) setState(() => _creatingTest = false);
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(saving ? 'Creating...' : 'Create Test'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      totalController.dispose();
      passingController.dispose();
    }
  }

  void _showDialogMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB42318),
          content: Text(message),
        ),
      );
  }

  Future<void> _openMarks(SchoolTest test) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _StudentMarksEntryScreen(
          schoolId: widget.schoolId,
          teacherId: widget.teacherId,
          assignment: widget.assignment,
          test: test,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  Widget _classSectionHeader({
    required List<String> names,
    required bool marksMode,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFEEF8F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF1E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _darkGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.subjectName,
                  style: const TextStyle(
                    color: _darkGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _InfoChip(icon: Icons.school_outlined, label: 'Class', value: names[0]),
              _InfoChip(icon: Icons.grid_view_rounded, label: 'Section', value: names[1]),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            marksMode
                ? 'Select a test and enter marks for students in this section.'
                : 'Create tests and manage assessments for your assigned class and section.',
            style: const TextStyle(color: _muted, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 20,
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
        if (_refreshing)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _green),
          ),
      ],
    );
  }

  Widget _testCard(SchoolTest test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _openMarks(test),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _softGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
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
                      test.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaText(_formatDate(test.testDate)),
                        const _MetaDot(),
                        _MetaText('Total: ${_formatMarks(test.totalMarks)} marks'),
                        const _MetaDot(),
                        _StatusPill(status: test.status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _testListMessage({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: _green),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.5, fontSize: 12),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.openMarks ? 'Enter Marks' : 'Tests'),
            Text(
              widget.openMarks ? 'Manage student assessment scores' : 'Manage subject assessments',
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creatingTest ? null : _createTest,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: _creatingTest
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(_creatingTest ? 'Creating...' : 'Create Test'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: _green,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 28.0;
              final contentWidth = constraints.maxWidth >= 1200
                  ? 1120.0
                  : constraints.maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          20,
                          horizontalPadding,
                          0,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            FutureBuilder<List<String>>(
                              future: _classSectionFuture,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return _testListMessage(
                                    icon: Icons.error_outline_rounded,
                                    title: 'Unable to Load Class Details',
                                    message: 'Please refresh and try again.',
                                    onRetry: _refresh,
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: _border),
                                    ),
                                    child: const LinearProgressIndicator(color: _green),
                                  );
                                }
                                return _classSectionHeader(
                                  names: snapshot.data!,
                                  marksMode: widget.openMarks,
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            _sectionTitle(
                              title: 'Tests',
                              subtitle: 'Select a test to view or enter student marks.',
                            ),
                            const SizedBox(height: 14),
                          ]),
                        ),
                      ),
                      FutureBuilder<List<SchoolTest>>(
                        future: _testsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(36),
                                child: Center(
                                  child: CircularProgressIndicator(color: _green),
                                ),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: _testListMessage(
                                  icon: Icons.cloud_off_outlined,
                                  title: 'Unable to Load Tests',
                                  message: 'The test list could not be loaded. Check your connection and try again.',
                                  onRetry: _refresh,
                                ),
                              ),
                            );
                          }

                          final tests = snapshot.data ?? <SchoolTest>[];
                          if (tests.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: _testListMessage(
                                  icon: Icons.assignment_outlined,
                                  title: 'No Tests Yet',
                                  message: 'Create your first test for this subject and section.',
                                ),
                              ),
                            );
                          }

                          return SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              0,
                              horizontalPadding,
                              100,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _testCard(tests[index]),
                                childCount: tests.length,
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StudentMarksEntryScreen extends ConsumerStatefulWidget {
  const _StudentMarksEntryScreen({
    required this.schoolId,
    required this.teacherId,
    required this.assignment,
    required this.test,
  });

  final String schoolId;
  final String teacherId;
  final TeacherAssignment assignment;
  final SchoolTest test;

  @override
  ConsumerState<_StudentMarksEntryScreen> createState() =>
      _StudentMarksEntryScreenState();
}

class _StudentMarksEntryScreenState
    extends ConsumerState<_StudentMarksEntryScreen> {
  late Future<List<Student>> _studentsFuture;
  late Future<List<String>> _classSectionFuture;
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  bool _initialMarksLoaded = false;

  @override
  void initState() {
    super.initState();
    _classSectionFuture = _loadClassSectionNames(
      schoolId: widget.schoolId,
      classId: widget.assignment.classId,
      sectionId: widget.assignment.sectionId ?? '',
    );
    _studentsFuture = _loadStudents();
  }

  Future<List<Student>> _loadStudents() async {
    final repo = ref.read(subjectTeacherWorkRepositoryProvider);
    final students = await repo.getSectionStudents(
      schoolId: widget.schoolId,
      sectionId: widget.test.sectionId,
    );

    if (!_initialMarksLoaded) {
      final existing = await repo.getExistingMarks(
        schoolId: widget.schoolId,
        testId: widget.test.id,
        students: students,
      );
      for (final student in students) {
        _controllers[student.id] = TextEditingController(
          text: existing[student.id]?.toString() ?? '',
        );
      }
      _initialMarksLoaded = true;
    }
    return students;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _refreshMarks() async {
    if (_saving) return;
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    setState(() {
      _initialMarksLoaded = false;
      _classSectionFuture = _loadClassSectionNames(
        schoolId: widget.schoolId,
        classId: widget.assignment.classId,
        sectionId: widget.assignment.sectionId ?? '',
      );
      _studentsFuture = _loadStudents();
    });
    try {
      await Future.wait([_studentsFuture, _classSectionFuture]);
    } catch (_) {
      // Loading errors are displayed by the corresponding FutureBuilder.
    }
  }

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? _darkGreen : const Color(0xFFB42318),
          content: Text(message),
        ),
      );
  }

  Future<void> _save(List<Student> students) async {
    final values = <String, double>{};

    for (final student in students) {
      final text = _controllers[student.id]?.text.trim() ?? '';
      // Preserve existing behavior: blank fields are saved as zero.
      final value = text.isEmpty ? 0.0 : double.tryParse(text);

      if (value == null ||
          !value.isFinite ||
          value < 0 ||
          value > widget.test.totalMarks) {
        _showMessage(
          '${student.name}: enter a valid score between 0 and ${_formatMarks(widget.test.totalMarks)}.',
        );
        return;
      }
      values[student.id] = value;
    }

    setState(() => _saving = true);
    try {
      await ref.read(subjectTeacherWorkRepositoryProvider).saveStudentMarks(
            schoolId: widget.schoolId,
            teacherId: widget.teacherId,
            test: widget.test,
            students: students,
            enteredMarks: values,
          );

      if (!mounted) return;
      _showMessage('Student marks saved and published successfully.', success: true);
      Navigator.pop(context);
    } catch (error) {
      _showMessage('Unable to save marks. $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _testDetails(List<String> names) {
    final details = <(String, String)>[
      ('Test Name', widget.test.title),
      ('Subject', widget.test.subjectName),
      ('Class', names[0]),
      ('Section', names[1]),
      ('Test Date', _formatDate(widget.test.testDate)),
      ('Total Marks', _formatMarks(widget.test.totalMarks)),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeading(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Test Details',
            subtitle: 'Review the assessment before entering marks.',
          ),
          const SizedBox(height: 16),
          ...details.map(
            (detail) => _DetailRow(label: detail.$1, value: detail.$2),
          ),
          if (widget.test.description.trim().isNotEmpty) ...[
            const Divider(height: 24, color: _border),
            const Text(
              'Chapters / Syllabus',
              style: TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(widget.test.description, style: const TextStyle(color: _text, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _studentMarkRow(Student student, int index) {
    final controller = _controllers.putIfAbsent(
      student.id,
      () => TextEditingController(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final nameBlock = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _text, fontWeight: FontWeight.w700),
              ),
              if (student.admissionNumber.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  student.admissionNumber,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ],
          ),
        );

        final markField = TextField(
          controller: controller,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          decoration: _inputDecoration(
            label: 'Marks',
            hint: '0–${_formatMarks(widget.test.totalMarks)}',
            icon: Icons.edit_note_rounded,
          ).copyWith(
            prefixIcon: null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          ),
          onChanged: (_) {
            // Keep the entered-count indicator current without rebuilding the
            // whole screen's student list (the SliverList remains lazy).
            if (mounted) setState(() {});
          },
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: compact
              ? Column(
                  children: [
                    Row(
                      children: [
                        _NumberBadge(number: index + 1),
                        const SizedBox(width: 11),
                        nameBlock,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Obtained Marks',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(width: 145, child: markField),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    _NumberBadge(number: index + 1),
                    const SizedBox(width: 12),
                    nameBlock,
                    const SizedBox(width: 20),
                    SizedBox(width: 170, child: markField),
                  ],
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter Marks'),
            Text(
              'Record and publish student scores',
              style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh students and saved marks',
            onPressed: _saving ? null : _refreshMarks,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Student>>(
          future: _studentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _green));
            }
            if (snapshot.hasError) {
              return _CenteredMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Unable to Load Students',
                message: 'Please check your connection and refresh the list.',
                actionLabel: 'Try Again',
                onPressed: _refreshMarks,
              );
            }

            final students = snapshot.data ?? <Student>[];
            if (students.isEmpty) {
              return const _CenteredMessage(
                icon: Icons.groups_outlined,
                title: 'No Active Students',
                message: 'There are no active students assigned to this section.',
              );
            }

            final enteredCount = students.where((student) {
              return _controllers[student.id]?.text.trim().isNotEmpty ?? false;
            }).length;

            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 600 ? 14.0 : 26.0;
                final contentWidth = constraints.maxWidth >= 1200
                    ? 1120.0
                    : constraints.maxWidth;

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  20,
                                  horizontalPadding,
                                  0,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    FutureBuilder<List<String>>(
                                      future: _classSectionFuture,
                                      builder: (context, namesSnapshot) {
                                        final names = namesSnapshot.data ?? [
                                          widget.assignment.classId,
                                          widget.assignment.sectionId ?? 'Not assigned',
                                        ];
                                        return _testDetails(names);
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    const _PanelHeading(
                                      icon: Icons.people_alt_outlined,
                                      title: 'Student Marks',
                                      subtitle: 'Enter each student\'s score. Blank fields are saved as zero.',
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Maximum score: ${_formatMarks(widget.test.totalMarks)} marks',
                                      style: const TextStyle(color: _muted, fontSize: 12),
                                    ),
                                    const SizedBox(height: 14),
                                  ]),
                                ),
                              ),
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => _studentMarkRow(students[index], index),
                                    childCount: students.length,
                                    addAutomaticKeepAlives: false,
                                    addRepaintBoundaries: true,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  5,
                                  horizontalPadding,
                                  24,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _softGreen,
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: _darkGreen),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Scores entered: $enteredCount of ${students.length} students',
                                            style: const TextStyle(
                                              color: _darkGreen,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SafeArea(
                          top: false,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              12,
                              horizontalPadding,
                              12,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(top: BorderSide(color: _border)),
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 600),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton.icon(
                                    style: _primaryButtonStyle(),
                                    onPressed: _saving ? null : () => _save(students),
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.cloud_upload_outlined),
                                    label: Text(_saving ? 'Saving...' : 'Save & Upload Results'),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: _green),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: _muted, fontSize: 13)),
        Text(value, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: _muted, fontSize: 11));
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();
  @override
  Widget build(BuildContext context) => const Text('•', style: TextStyle(color: _muted, fontSize: 11));
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final success = normalized == 'published' || normalized == 'completed';
    final color = success ? _darkGreen : const Color(0xFF8A6200);
    final background = success ? const Color(0xFFE4F3E9) : const Color(0xFFFFF4D6);
    final label = status.trim().isEmpty
        ? 'Unknown'
        : '${status[0].toUpperCase()}${status.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(30)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: _softGreen, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _darkGreen, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: _softGreen, shape: BoxShape.circle),
      child: Text('$number', style: const TextStyle(color: _darkGreen, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _green, size: 46),
                const SizedBox(height: 14),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.5, fontSize: 12)),
                if (onPressed != null && actionLabel != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: _primaryButtonStyle(),
                    onPressed: onPressed,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_core/school_core.dart';
import 'package:school_models/school_models.dart';

import '../data/subject_teacher_work_repository.dart';

/// Class aur section IDs ko readable names mein convert karta hai.
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

    if (classDoc.exists &&
        data != null &&
        data['schoolId'] == schoolId) {
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

    if (sectionDoc.exists &&
        data != null &&
        data['schoolId'] == schoolId) {
      final name = data['name'];
      if (name is String && name.trim().isNotEmpty) {
        sectionName = name.trim();
      }
    }
  }

  return [
    className.isEmpty ? 'Not assigned' : className,
    sectionName.isEmpty ? 'Not assigned' : sectionName,
  ];
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _formatMarks(double marks) {
  return marks.toStringAsFixed(marks % 1 == 0 ? 0 : 1);
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _testsFuture = ref
        .read(subjectTeacherWorkRepositoryProvider)
        .getTests(
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
    setState(_loadData);

    try {
      await Future.wait([
        _testsFuture,
        _classSectionFuture,
      ]);
    } catch (_) {
      // Error screen par display hoga.
    }
  }

  Future<void> _createTest() async {
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
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Create Test'),
                content: SizedBox(
                  width: 420,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Test Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Test name required hai.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Chapters / Syllabus (optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Test Date'),
                            subtitle: Text(_formatDate(selectedDate)),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (date != null) {
                                setDialogState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: totalController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Total Marks',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final total = double.tryParse(value ?? '');

                              if (total == null || total <= 0) {
                                return 'Valid total marks enter karein.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passingController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Passing Marks',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final passing =
                                  double.tryParse(value ?? '');
                              final total =
                                  double.tryParse(totalController.text);

                              if (passing == null ||
                                  passing < 0 ||
                                  total == null ||
                                  passing > total) {
                                return 'Passing marks total se zyada nahi ho sakte.';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setDialogState(() => saving = true);

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
                                    totalMarks:
                                        double.parse(totalController.text),
                                    passingMarks:
                                        double.parse(passingController.text),
                                  );

                              if (!dialogContext.mounted) return;

                              Navigator.pop(dialogContext);
                              await _refresh();

                              if (mounted) {
                                ScaffoldMessenger.of(this.context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Test successfully create ho gaya.',
                                    ),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() => saving = false);

                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('Test save nahi hua: $error'),
                                ),
                              );
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Create Test'),
                  ),
                ],
              );
            },
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

    if (mounted) {
      await _refresh();
    }
  }

  Widget _classSectionHeader({
    required BuildContext context,
    required List<String> names,
    required bool marksMode,
  }) {
    return Card(
      color: const Color(0xFFEAF6EF),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF087F4B),
                  ),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Class', value: names[0]),
            _DetailRow(label: 'Section', value: names[1]),
            const SizedBox(height: 6),
            Text(
              marksMode
                  ? 'Test select karein aur students ke marks enter karein.'
                  : 'Yahan apne assigned class aur section ke tests manage karein.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.openMarks ? 'Enter Marks' : 'Tests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTest,
        icon: const Icon(Icons.add),
        label: const Text('Create Test'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<List<String>>(
              future: _classSectionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    color: const Color(0xFFEAF6EF),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subjectName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(),
                        ],
                      ),
                    ),
                  );
                }

                final names = snapshot.data ??
                    [
                      widget.assignment.classId,
                      widget.assignment.sectionId ?? 'Not assigned',
                    ];

                return _classSectionHeader(
                  context: context,
                  names: names,
                  marksMode: widget.openMarks,
                );
              },
            ),
            const SizedBox(height: 18),
            const Text(
              'Tests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<SchoolTest>>(
              future: _testsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text('Tests load nahi ho sake: ${snapshot.error}'),
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final tests = snapshot.data ?? [];

                if (tests.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: Center(
                        child: Text(
                          'Abhi koi test nahi hai. Create Test dabayein.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: tests.map((test) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEAF6EF),
                          child: Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF087F4B),
                          ),
                        ),
                        title: Text(
                          test.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${_formatDate(test.testDate)}'
                          '  •  Total: ${_formatMarks(test.totalMarks)}'
                          '  •  ${test.status}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openMarks(test),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
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

  Future<void> _save(List<Student> students) async {
    final values = <String, double>{};

    for (final student in students) {
      final text = _controllers[student.id]?.text.trim() ?? '';

      // Existing behavior preserved: blank fields save as zero.
      final value = text.isEmpty ? 0.0 : double.tryParse(text);

      if (value == null ||
          value < 0 ||
          value > widget.test.totalMarks) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${student.name}: 0 se '
              '${_formatMarks(widget.test.totalMarks)} tak valid marks enter karein.',
            ),
          ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student marks save ho gaye.')),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marks save nahi ho sake: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _testDetails(List<String> names, BuildContext context) {
    final total = widget.test.totalMarks;

    return Card(
      color: const Color(0xFFEAF6EF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 30,
              color: Color(0xFF087F4B),
            ),
            const SizedBox(height: 8),
            Text(
              'Test Result Upload',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Test Name', value: widget.test.title),
            _DetailRow(label: 'Subject', value: widget.test.subjectName),
            _DetailRow(label: 'Class', value: names[0]),
            _DetailRow(label: 'Section', value: names[1]),
            _DetailRow(
              label: 'Test Date',
              value: _formatDate(widget.test.testDate),
            ),
            _DetailRow(
              label: 'Total Marks',
              value: _formatMarks(total),
            ),
            if (widget.test.description.isNotEmpty)
              _DetailRow(
                label: 'Chapters / Syllabus',
                value: widget.test.description,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.test.totalMarks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Marks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {
                _classSectionFuture = _loadClassSectionNames(
                  schoolId: widget.schoolId,
                  classId: widget.assignment.classId,
                  sectionId: widget.assignment.sectionId ?? '',
                );
                _studentsFuture = _loadStudents();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Student>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Students load nahi ho sake: ${snapshot.error}'),
              ),
            );
          }

          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return const Center(
              child: Text('Is section mein koi active student nahi mila.'),
            );
          }

          final enteredCount = students.where((student) {
            return _controllers[student.id]?.text.trim().isNotEmpty ?? false;
          }).length;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    FutureBuilder<List<String>>(
                      future: _classSectionFuture,
                      builder: (context, namesSnapshot) {
                        final names = namesSnapshot.data ??
                            [
                              widget.assignment.classId,
                              widget.assignment.sectionId ?? 'Not assigned',
                            ];

                        return _testDetails(names, context);
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Marks',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Har student ke obtained marks enter karein.',
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              color: const Color(0xFFEAF6EF),
                              child: const Row(
                                children: [
                                  SizedBox(width: 34, child: Text('No.')),
                                  Expanded(child: Text('Student Name')),
                                  SizedBox(
                                    width: 112,
                                    child: Text(
                                      'Marks',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...List.generate(students.length, (index) {
                              final student = students[index];
                              final controller = _controllers.putIfAbsent(
                                student.id,
                                () => TextEditingController(),
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 7),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 34,
                                      child: Text('${index + 1}'),
                                    ),
                                    Expanded(
                                      child: Text(
                                        student.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 112,
                                      child: TextField(
                                        controller: controller,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          hintText: '0 / ${_formatMarks(total)}',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF6EF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Results Entered: $enteredCount / ${students.length}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF087F4B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _save(students),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        _saving ? 'Saving...' : 'Save & Upload Results',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

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
            width: 115,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

import '../../data/subjects_teacher_repository.dart';

class SubjectsTeacherScreen extends StatefulWidget {
  const SubjectsTeacherScreen({
    super.key,
    required this.section,
    required this.className,
    required this.repository,
  });

  final SchoolSection section;
  final String className;
  final SubjectsTeacherRepository repository;

  @override
  State<SubjectsTeacherScreen> createState() =>
      _SubjectsTeacherScreenState();
}

class _SubjectsTeacherScreenState extends State<SubjectsTeacherScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF7F9F7);

  List<Subject> _subjects = [];
  List<StaffMember> _teachers = [];
  List<TeacherAssignment> _assignments = [];

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        widget.repository.getSubjects(widget.section.schoolId),
        widget.repository.getTeachers(widget.section.schoolId),
        widget.repository.getAssignments(
          schoolId: widget.section.schoolId,
          sectionId: widget.section.id,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _subjects = results[0] as List<Subject>;
        _teachers = results[1] as List<StaffMember>;
        _assignments = results[2] as List<TeacherAssignment>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  StaffMember? _teacherFor(String subjectId) {
    for (final assignment in _assignments) {
      if (assignment.subjectId != subjectId || !assignment.isActive) {
        continue;
      }

      for (final teacher in _teachers) {
        if (teacher.id == assignment.teacherId) {
          return teacher;
        }
      }
    }

    return null;
  }

  Future<void> _addSubject() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Subject name *',
                  hintText: 'e.g. Mathematics',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Subject code (optional)',
                  hintText: 'e.g. MATH',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _saving = true);

      await widget.repository.addSubject(
        schoolId: widget.section.schoolId,
        name: nameController.text,
        code: codeController.text,
      );

      await _load();
      if (mounted) _message('Subject added successfully.');
    } catch (e) {
      if (mounted) _message('Subject save nahi hua: $e');
    } finally {
      nameController.dispose();
      codeController.dispose();

      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _assignTeacher(Subject subject) async {
    final selectedTeacher = _teacherFor(subject.id);

    final choice = await showDialog<_AssignChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Assign ${subject.name}'),
        content: const Text(
          'Existing teacher select karein ya isi waqt naya teacher account '
          'create karein.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _AssignChoice.cancel),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pop(dialogContext, _AssignChoice.createNew),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Create New Teacher'),
          ),
          FilledButton(
            onPressed: _teachers.isEmpty
                ? null
                : () => Navigator.pop(
                      dialogContext,
                      _AssignChoice.existing,
                    ),
            child: const Text('Select Existing'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null || choice == _AssignChoice.cancel) {
      return;
    }

    if (choice == _AssignChoice.createNew) {
      await _createAndAssignTeacher(subject);
      return;
    }

    await _selectExistingTeacher(subject, selectedTeacher);
  }

  Future<void> _selectExistingTeacher(
    Subject subject,
    StaffMember? currentTeacher,
  ) async {
    if (_teachers.isEmpty) {
      _message('Pehle teacher account create karein.');
      return;
    }

    String? selectedTeacherId = currentTeacher?.id;

    final teacherId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign ${subject.name}'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedTeacherId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select teacher',
              border: OutlineInputBorder(),
            ),
            items: _teachers.map((teacher) {
              return DropdownMenuItem<String>(
                value: teacher.id,
                child: Text(
                  '${teacher.name} (${teacher.role})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setDialogState(() => selectedTeacherId = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedTeacherId == null
                  ? null
                  : () => Navigator.pop(
                        dialogContext,
                        selectedTeacherId,
                      ),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (teacherId == null || !mounted) return;

    await _saveAssignment(subject, teacherId);
  }

  Future<void> _createAndAssignTeacher(Subject subject) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    String role = 'subjectTeacher';
    bool obscurePassword = true;

    try {
      final details = await showDialog<_NewTeacherDetails>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Create New Teacher'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New teacher will be assigned to ${subject.name}.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Teacher name *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email address *',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Temporary password *',
                        helperText: 'Minimum 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Teacher role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'subjectTeacher',
                          child: Text('Subject Teacher'),
                        ),
                        DropdownMenuItem(
                          value: 'classTeacher',
                          child: Text('Class Teacher'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => role = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final password = passwordController.text;

                  if (name.isEmpty ||
                      email.isEmpty ||
                      !email.contains('@') ||
                      password.length < 8 ||
                      password.length > 128) {
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    _NewTeacherDetails(
                      name: name,
                      email: email,
                      password: password,
                      role: role,
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Create & Assign'),
              ),
            ],
          ),
        ),
      );

      if (details == null || !mounted) return;

      setState(() => _saving = true);

      // The trusted callable creates the Auth account and users profile.
      final teacher = await widget.repository.createTeacherAccount(
        name: details.name,
        email: details.email,
        password: details.password,
        role: details.role,
      );

      // Refresh the teacher list even if assignment subsequently fails.
      try {
        await widget.repository.assignTeacher(
          schoolId: widget.section.schoolId,
          teacherId: teacher.id,
          classId: widget.section.classId,
          sectionId: widget.section.id,
          subjectId: subject.id,
          academicYearId: widget.section.academicYearId,
        );

        await _load();

        if (mounted) {
          _message(
            'Teacher account created and ${subject.name} assigned successfully.',
          );
        }
      } catch (e) {
        await _load();

        if (mounted) {
          _message(
            'Teacher account create ho gaya, lekin assignment fail hui. '
            'Teacher list refresh kar di gayi hai. Error: $e',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _message('Teacher account create nahi hua: $e');
      }
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();

      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAssignment(
    Subject subject,
    String teacherId,
  ) async {
    setState(() => _saving = true);

    try {
      await widget.repository.assignTeacher(
        schoolId: widget.section.schoolId,
        teacherId: teacherId,
        classId: widget.section.classId,
        sectionId: widget.section.id,
        subjectId: subject.id,
        academicYearId: widget.section.academicYearId,
      );

      await _load();

      if (mounted) _message('Teacher assigned successfully.');
    } catch (e) {
      if (mounted) _message('Assignment save nahi hui: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Subjects & Teachers'),
        backgroundColor: _background,
        foregroundColor: _darkGreen,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _saving ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving || _loading ? null : _addSubject,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 42),
                          const SizedBox(height: 12),
                          const Text(
                            'Data load nahi ho saka.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            100,
                          ),
                          children: [
                            Card(
                              elevation: 0,
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.class_outlined),
                                ),
                                title: Text(
                                  '${widget.className} — Section ${widget.section.name}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_subjects.length} active subjects · '
                                  '${_assignments.length} active assignments',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_subjects.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.menu_book_outlined,
                                        size: 42,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'Abhi koi subject nahi hai.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Add Subject par click karke '
                                        'pehla subject banayein.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._subjects.map((subject) {
                                final teacher = _teacherFor(subject.id);

                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFEAF6EF),
                                      child: Icon(
                                        Icons.menu_book_outlined,
                                        color: _green,
                                      ),
                                    ),
                                    title: Text(
                                      subject.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        teacher == null
                                            ? 'Teacher not assigned'
                                            : 'Teacher: ${teacher.name}',
                                      ),
                                    ),
                                    trailing: _saving
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : TextButton(
                                            onPressed: () =>
                                                _assignTeacher(subject),
                                            child: Text(
                                              teacher == null
                                                  ? 'Assign'
                                                  : 'Change',
                                            ),
                                          ),
                                  ),
                                );
                              }),
                            if (_teachers.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'Abhi koi active teacher nahi mila. '
                                  'Subject ke saamne Assign dabakar '
                                  'Create New Teacher select karein.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_saving)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
      ),
    );
  }
}

enum _AssignChoice {
  cancel,
  existing,
  createNew,
}

class _NewTeacherDetails {
  const _NewTeacherDetails({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  final String name;
  final String email;
  final String password;
  final String role;
}

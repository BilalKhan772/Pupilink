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
  State<SubjectsTeacherScreen> createState() => _SubjectsTeacherScreenState();
}

class _SubjectsTeacherScreenState extends State<SubjectsTeacherScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF5F8F6);
  static const Color _border = Color(0xFFE2EAE5);
  static const Color _text = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF6B7280);

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
        widget.repository.getSubjects(
          widget.section.schoolId,
          sectionId: widget.section.id,
        ),
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
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'You do not have permission to access this information.';
    }
    if (message.contains('unavailable')) {
      return 'The service is temporarily unavailable. Please try again.';
    }
    if (message.contains('network')) {
      return 'Please check your internet connection and try again.';
    }
    return message;
  }

  StaffMember? _teacherFor(String subjectId) {
    for (final assignment in _assignments) {
      if (assignment.subjectId != subjectId || !assignment.isActive) {
        continue;
      }

      for (final teacher in _teachers) {
        if (teacher.id == assignment.teacherId) return teacher;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: _green),
              SizedBox(width: 10),
              Expanded(child: Text('Add Subject')),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Subject Name',
                      hint: 'e.g. Mathematics',
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDecoration(
                      label: 'Subject Code (Optional)',
                      hint: 'e.g. MATH',
                      icon: Icons.tag_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _InformationNote(
                    message:
                        'This subject will be available in the selected section only.',
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: _primaryButtonStyle(),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, true);
                }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save Subject'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
      setState(() => _saving = true);

      await widget.repository.addSubject(
        schoolId: widget.section.schoolId,
        sectionId: widget.section.id,
        name: nameController.text,
        code: codeController.text,
      );

      await _load();
      if (mounted) {
        _message('Subject added successfully.', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _message('Unable to save the subject: ${_friendlyError(e)}');
      }
    } finally {
      nameController.dispose();
      codeController.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------
  // EDIT SUBJECT
  // ------------------------------------------------------------

  Future<void> _editSubject(Subject subject) async {
    final nameController = TextEditingController(text: subject.name);
    final codeController = TextEditingController(text: subject.code ?? '');

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_outlined, color: _green),
              SizedBox(width: 10),
              Expanded(child: Text('Edit Subject')),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      label: 'Subject Name',
                      hint: 'e.g. Mathematics',
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: _inputDecoration(
                      label: 'Subject Code (Optional)',
                      hint: 'e.g. MATH',
                      icon: Icons.tag_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _InformationNote(
                    message:
                        'Only the subject name and code will be updated. '
                        'Existing teacher assignments will be preserved.',
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: _primaryButtonStyle(),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, true);
                }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _saving = true);

      await widget.repository.updateSubject(
        schoolId: widget.section.schoolId,
        sectionId: widget.section.id,
        subjectId: subject.id,
        name: nameController.text,
        code: codeController.text,
      );

      await _load();

      if (mounted) {
        _message('Subject updated successfully.', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _message('Unable to update the subject: ${_friendlyError(e)}');
      }
    } finally {
      nameController.dispose();
      codeController.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _assignTeacher(Subject subject) async {
    final currentTeacher = _teacherFor(subject.id);

    final choice = await showDialog<_AssignChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text('Assign ${subject.name}'),
        content: const Text(
          'Choose an existing teacher or create a new teacher account. '
          'You can select the role for this section.',
          style: TextStyle(height: 1.5, color: _muted),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _AssignChoice.cancel),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _darkGreen,
              side: const BorderSide(color: _border),
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, _AssignChoice.createNew),
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Create New'),
          ),
          FilledButton(
            style: _primaryButtonStyle(),
            onPressed: _teachers.isEmpty
                ? null
                : () => Navigator.pop(dialogContext, _AssignChoice.existing),
            child: const Text('Select Existing'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null || choice == _AssignChoice.cancel) return;

    if (choice == _AssignChoice.createNew) {
      await _createAndAssignTeacher(subject);
    } else {
      await _selectExistingTeacher(subject, currentTeacher);
    }
  }

  Future<void> _selectExistingTeacher(
    Subject subject,
    StaffMember? currentTeacher,
  ) async {
    if (_teachers.isEmpty) {
      _message('No active teachers were found. Create a teacher first.');
      return;
    }

    String? selectedTeacherId = currentTeacher?.id;
    String selectedRole = 'subjectTeacher';

    final selection = await showDialog<_ExistingTeacherSelection>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Assign ${subject.name}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedTeacherId,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'Select Teacher',
                      icon: Icons.person_outline_rounded,
                    ),
                    items: _teachers.map((teacher) {
                      return DropdownMenuItem<String>(
                        value: teacher.id,
                        child: Text(
                          teacher.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedTeacherId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'Role for This Section',
                      icon: Icons.badge_outlined,
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'subjectTeacher',
                        child: Text('Subject Teacher'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'classTeacher',
                        child: Text('Class Teacher'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const _InformationNote(
                    message:
                        'A Class Teacher assigned here will also retain the selected subject assignment, allowing them to manage tests and marks for that subject.',
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: _primaryButtonStyle(),
              onPressed: selectedTeacherId == null
                  ? null
                  : () => Navigator.pop(
                        dialogContext,
                        _ExistingTeacherSelection(
                          teacherId: selectedTeacherId!,
                          role: selectedRole,
                        ),
                      ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (selection == null || !mounted) return;

    await _assignSelectedTeacher(
      subject: subject,
      teacherId: selection.teacherId,
      selectedRole: selection.role,
    );
  }

  Future<void> _assignSelectedTeacher({
    required Subject subject,
    required String teacherId,
    required String selectedRole,
  }) async {
    if (selectedRole == 'classTeacher') {
      await _saveClassTeacher(subject: subject, teacherId: teacherId);
      return;
    }

    if (selectedRole == 'subjectTeacher') {
      await _saveSubjectTeacher(subject: subject, teacherId: teacherId);
      return;
    }

    _message('Please select a valid teacher role.');
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1, color: _green),
                SizedBox(width: 10),
                Expanded(child: Text('Create Teacher')),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _InformationNote(
                      message: role == 'classTeacher'
                          ? 'The teacher will be assigned as Class Teacher and will retain the ${subject.name} subject assignment in this section.'
                          : 'The teacher will be assigned to ${subject.name} in this section.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Teacher Name',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: _inputDecoration(
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: _inputDecoration(
                        label: 'Temporary Password',
                        hint: '8–128 characters',
                        icon: Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          tooltip: obscurePassword ? 'Show password' : 'Hide password',
                          onPressed: () => setDialogState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Teacher Role',
                        icon: Icons.badge_outlined,
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'subjectTeacher',
                          child: Text('Subject Teacher'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'classTeacher',
                          child: Text('Class Teacher'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => role = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                style: _primaryButtonStyle(),
                onPressed: () {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final password = passwordController.text;

                  if (name.isEmpty ||
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
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Create & Assign'),
              ),
            ],
          ),
        ),
      );

      if (details == null || !mounted) return;
      setState(() => _saving = true);

      final teacher = await widget.repository.createTeacherAccount(
        name: details.name,
        email: details.email,
        password: details.password,
        role: details.role,
      );

      if (details.role == 'classTeacher') {
        // Keep the subject assignment as well as the section class-teacher link.
        await widget.repository.assignTeacher(
          schoolId: widget.section.schoolId,
          teacherId: teacher.id,
          classId: widget.section.classId,
          sectionId: widget.section.id,
          subjectId: subject.id,
          academicYearId: widget.section.academicYearId,
        );
        await widget.repository.assignClassTeacher(
          schoolId: widget.section.schoolId,
          teacherId: teacher.id,
          classId: widget.section.classId,
          sectionId: widget.section.id,
        );
      } else {
        await widget.repository.assignTeacher(
          schoolId: widget.section.schoolId,
          teacherId: teacher.id,
          classId: widget.section.classId,
          sectionId: widget.section.id,
          subjectId: subject.id,
          academicYearId: widget.section.academicYearId,
        );
      }

      await _load();
      if (mounted) {
        _message('Teacher created and assigned successfully.', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _message('Unable to complete the assignment: ${_friendlyError(e)}');
      }
    } finally {
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveClassTeacher({
    required Subject subject,
    required String teacherId,
  }) async {
    setState(() => _saving = true);

    try {
      // Ensure the teacher can access Tests and Marks for this subject.
      await widget.repository.assignTeacher(
        schoolId: widget.section.schoolId,
        teacherId: teacherId,
        classId: widget.section.classId,
        sectionId: widget.section.id,
        subjectId: subject.id,
        academicYearId: widget.section.academicYearId,
      );

      await widget.repository.assignClassTeacher(
        schoolId: widget.section.schoolId,
        teacherId: teacherId,
        classId: widget.section.classId,
        sectionId: widget.section.id,
      );

      await _load();
      if (mounted) {
        _message(
          'Class Teacher and subject assignments saved successfully.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _message('Unable to assign Class Teacher: ${_friendlyError(e)}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveSubjectTeacher({
    required Subject subject,
    required String teacherId,
  }) async {
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

      // If this teacher was the Class Teacher of this exact section,
      // remove only that section-level assignment. Class Teacher assignments
      // in other sections remain untouched.
      await widget.repository.removeClassTeacherIfAssigned(
        schoolId: widget.section.schoolId,
        sectionId: widget.section.id,
        teacherId: teacherId,
      );

      await _load();

      if (mounted) {
        _message('Subject Teacher assignment saved successfully.', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _message('Unable to save the assignment: ${_friendlyError(e)}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // --------------------------------------------------------------------------
  // UI HELPERS
  // --------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: _green),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: _green, width: 1.6),
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: _green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _message(String message, {bool isSuccess = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isSuccess ? _darkGreen : const Color(0xFFB42318),
          content: Text(message),
        ),
      );
  }

  // --------------------------------------------------------------------------
  // SCREEN
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subjects & Teachers',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _darkGreen,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage section subjects and teacher assignments',
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
            tooltip: 'Refresh',
            onPressed: _loading || _saving ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _error != null
                ? _buildErrorState()
                : Stack(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final contentWidth = maxWidth >= 1160 ? 1120.0 : maxWidth;

                          return Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: contentWidth,
                              child: RefreshIndicator(
                                onRefresh: _load,
                                color: _green,
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: maxWidth < 600 ? 16 : 28,
                                    vertical: 24,
                                  ),
                                  children: [
                                    _buildSectionHeader(),
                                    const SizedBox(height: 28),
                                    _buildSubjectsHeader(),
                                    const SizedBox(height: 16),
                                    _buildSubjectsGrid(maxWidth: contentWidth),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_saving)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            color: _green,
                            backgroundColor: Color(0xFFDCEFE3),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF0F8F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F2E7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: _darkGreen,
                  size: 27,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.className,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Section ${widget.section.name}',
                      style: const TextStyle(fontSize: 14, color: _muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F2E7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 15, color: _darkGreen),
                    SizedBox(width: 6),
                    Text(
                      'Section',
                      style: TextStyle(
                        color: _darkGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryPill(
                icon: Icons.menu_book_outlined,
                label: '${_subjects.length} Subjects',
              ),
              _summaryPill(
                icon: Icons.assignment_ind_outlined,
                label: '${_assignments.length} Active Assignments',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _green, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Section Subjects',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Assign teachers and manage subject responsibilities.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 14),
              FilledButton.icon(
                style: _primaryButtonStyle(),
                onPressed: _saving ? null : _addSubject,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Subject'),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            FilledButton.icon(
              style: _primaryButtonStyle(),
              onPressed: _saving ? null : _addSubject,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add Subject'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectsGrid({required double maxWidth}) {
    if (_subjects.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5ED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_outlined, color: _green, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Subjects Yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _text),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a subject to get started with teacher assignments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: _primaryButtonStyle(),
              onPressed: _saving ? null : _addSubject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Subject'),
            ),
          ],
        ),
      );
    }

    const spacing = 16.0;
    final columns = maxWidth >= 800 ? 2 : 1;
    final cardWidth = columns == 2 ? (maxWidth - spacing) / 2 : maxWidth;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: _subjects.map((subject) {
        return SizedBox(
          width: cardWidth,
          child: _buildSubjectCard(
            subject: subject,
            teacher: _teacherFor(subject.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectCard({required Subject subject, required StaffMember? teacher}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.menu_book_rounded, color: _green, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _text),
                    ),
                    if (subject.code != null && subject.code!.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text('Code: ${subject.code}', style: const TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: teacher == null
                          ? const Color(0xFFFFF4E5)
                          : const Color(0xFFE4F5E9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      teacher == null ? 'Unassigned' : 'Assigned',
                      style: TextStyle(
                        color: teacher == null
                            ? const Color(0xFF9A6700)
                            : _darkGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: 'Edit subject name or code',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: _saving ? null : () => _editSubject(subject),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1, color: _border),
          ),
          const Text(
            'Assigned Teacher',
            style: TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE8F5EC),
                child: Icon(
                  teacher == null ? Icons.person_outline_rounded : Icons.person_rounded,
                  color: _darkGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  teacher?.name ?? 'No teacher assigned',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: teacher == null ? _muted : _text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkGreen,
                side: const BorderSide(color: Color(0xFFB8D8C2)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving ? null : () => _assignTeacher(subject),
              icon: Icon(
                teacher == null ? Icons.person_add_alt_1 : Icons.edit_outlined,
                size: 18,
              ),
              label: Text(
                teacher == null ? 'Assign Teacher' : 'Change Teacher',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(color: Color(0xFFFDECEC), shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318), size: 32),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Unable to Load Subjects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _text),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'An unexpected error occurred.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted, height: 1.5),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  style: _primaryButtonStyle(),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InformationNote extends StatelessWidget {
  const _InformationNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8EBDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF267344), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF315B40), fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AssignChoice { cancel, existing, createNew }

class _ExistingTeacherSelection {
  const _ExistingTeacherSelection({required this.teacherId, required this.role});

  final String teacherId;
  final String role;
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

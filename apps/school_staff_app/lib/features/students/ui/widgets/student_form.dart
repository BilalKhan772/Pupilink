
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class StudentForm extends StatefulWidget {
  const StudentForm({
    super.key,
    required this.classes,
    required this.sections,
    required this.isSaving,
    required this.onSubmit,
    this.initialStudent,
    this.initialClassId,
    this.initialSectionId,
  });

  final List<SchoolClass> classes;
  final List<SchoolSection> sections;
  final bool isSaving;
  final Student? initialStudent;
  final String? initialClassId;
  final String? initialSectionId;

  final Future<bool> Function({
    required String name,
    required String admissionNumber,
    required String city,
    required String schoolName,
    required String classId,
    required String sectionId,
  }) onSubmit;

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _admission;
  late final TextEditingController _city;
  late final TextEditingController _schoolName;

  String? _classId;
  String? _sectionId;

  List<SchoolSection> get _availableSections => widget.sections
      .where((section) =>
          section.classId == _classId && section.isActive)
      .toList();

  @override
  void initState() {
    super.initState();

    final student = widget.initialStudent;
    _name = TextEditingController(text: student?.name ?? '');
    _admission =
        TextEditingController(text: student?.admissionNumber ?? '');
    _city = TextEditingController(text: student?.city ?? '');
    _schoolName =
        TextEditingController(text: student?.schoolName ?? '');

    _classId = widget.initialClassId ??
        widget.classes
            .where((item) => item.name == student?.className)
            .map((item) => item.id)
            .firstOrNull;

    _sectionId = widget.initialSectionId ??
        widget.sections
            .where((item) =>
                item.classId == _classId &&
                item.name == student?.section)
            .map((item) => item.id)
            .firstOrNull;

    if (!widget.classes.any((item) => item.id == _classId)) {
      _classId = null;
    }

    if (!_availableSections.any((item) => item.id == _sectionId)) {
      _sectionId = null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _admission.dispose();
    _city.dispose();
    _schoolName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_classId == null || _sectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class aur section select karein.')),
      );
      return;
    }

    final success = await widget.onSubmit(
      name: _name.text.trim(),
      admissionNumber: _admission.text.trim(),
      city: _city.text.trim(),
      schoolName: _schoolName.text.trim(),
      classId: _classId!,
      sectionId: _sectionId!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Yeh field required hai.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Student name',
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _admission,
            decoration: const InputDecoration(
              labelText: 'Admission number',
              hintText: 'e.g. STU-1002',
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _city,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _schoolName,
            decoration: const InputDecoration(
              labelText: 'School name',
              border: OutlineInputBorder(),
            ),
            validator: _required,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _classId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(),
            ),
            items: widget.classes
                .where((item) => item.isActive)
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: widget.isSaving
                ? null
                : (value) {
                    setState(() {
                      _classId = value;
                      _sectionId = null;
                    });
                  },
            validator: (value) =>
                value == null ? 'Class select karein.' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _sectionId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Section',
              border: OutlineInputBorder(),
            ),
            items: _availableSections
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: widget.isSaving
                ? null
                : (value) => setState(() => _sectionId = value),
            validator: (value) =>
                value == null ? 'Section select karein.' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: widget.isSaving ? null : _submit,
              child: widget.isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.initialStudent == null
                          ? 'Add student'
                          : 'Save changes',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

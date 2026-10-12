
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class SectionForm extends StatefulWidget {
  const SectionForm({
    super.key,
    required this.classes,
    required this.isSaving,
    required this.onSubmit,
    this.initialSection,
  });

  final List<SchoolClass> classes;
  final bool isSaving;
  final SchoolSection? initialSection;

  final Future<void> Function({
    required String classId,
    required String name,
    int? capacity,
  }) onSubmit;

  @override
  State<SectionForm> createState() => _SectionFormState();
}

class _SectionFormState extends State<SectionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  String? _classId;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialSection?.name ?? '',
    );

    _capacityController = TextEditingController(
      text: widget.initialSection?.capacity?.toString() ?? '',
    );

    _classId = widget.initialSection?.classId;

    if (_classId != null &&
        !widget.classes.any((item) => item.id == _classId)) {
      _classId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedClassId = _classId;
    if (selectedClassId == null || selectedClassId.isEmpty) return;

    final capacityText = _capacityController.text.trim();

    await widget.onSubmit(
      classId: selectedClassId,
      name: _nameController.text.trim(),
      capacity: capacityText.isEmpty ? null : int.parse(capacityText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Class',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _classId,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_outlined),
            ),
            hint: const Text('Select class'),
            items: widget.classes
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Class select karein.';
              }
              return null;
            },
            onChanged: widget.isSaving
                ? null
                : (value) => setState(() => _classId = value),
          ),
          const SizedBox(height: 20),
          const Text(
            'Section name',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. A, B, C',
              prefixIcon: Icon(Icons.meeting_room_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Section ka naam enter karein.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Student capacity (optional)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 35',
              prefixIcon: Icon(Icons.people_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return null;

              final number = int.tryParse(text);
              if (number == null || number <= 0) {
                return 'Positive number enter karein.';
              }
              return null;
            },
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
                      widget.initialSection == null
                          ? 'Create section'
                          : 'Save changes',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

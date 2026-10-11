
import 'package:flutter/material.dart';
import 'package:school_models/school_models.dart';

class ClassForm extends StatefulWidget {
  const ClassForm({
    super.key,
    required this.academicYears,
    required this.isSaving,
    required this.onSubmit,
    this.initialClass,
  });

  final List<AcademicYear> academicYears;
  final bool isSaving;
  final SchoolClass? initialClass;
  final Future<void> Function({
    required String name,
    String? academicYearId,
    int? sortOrder,
  }) onSubmit;

  @override
  State<ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends State<ClassForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _orderController;
  String? _academicYearId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialClass?.name ?? '',
    );
    _orderController = TextEditingController(
      text: widget.initialClass?.sortOrder?.toString() ?? '',
    );
    _academicYearId = widget.initialClass?.academicYearId;

    if (_academicYearId != null &&
        !widget.academicYears.any((year) => year.id == _academicYearId)) {
      _academicYearId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final orderText = _orderController.text.trim();

    await widget.onSubmit(
      name: _nameController.text.trim(),
      academicYearId: _academicYearId,
      sortOrder: orderText.isEmpty ? null : int.tryParse(orderText),
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
            'Class name',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Class 5',
              prefixIcon: Icon(Icons.class_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Class ka naam enter karein.';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Academic year',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _academicYearId,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select academic year (optional)'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No academic year'),
              ),
              ...widget.academicYears.map(
                (year) => DropdownMenuItem<String?>(
                  value: year.id,
                  child: Text(year.name),
                ),
              ),
            ],
            onChanged: widget.isSaving
                ? null
                : (value) => setState(() => _academicYearId = value),
          ),
          const SizedBox(height: 20),
          const Text(
            'Display order (optional)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _orderController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 5',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return null;
              final number = int.tryParse(text);
              if (number == null || number < 0) {
                return 'Zero ya positive number enter karein.';
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
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.initialClass == null
                      ? 'Create class'
                      : 'Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}

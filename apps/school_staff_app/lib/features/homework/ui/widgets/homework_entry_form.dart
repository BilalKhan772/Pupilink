
import 'package:flutter/material.dart';

class HomeworkEntryForm extends StatefulWidget {
  const HomeworkEntryForm({
    super.key,
    required this.isSaving,
    required this.onSubmit,
  });

  final bool isSaving;

  final Future<bool> Function({
    required String title,
    required String description,
    required DateTime dueDate,
  }) onSubmit;

  @override
  State<HomeworkEntryForm> createState() => _HomeworkEntryFormState();
}

class _HomeworkEntryFormState extends State<HomeworkEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final today = DateUtils.dateOnly(DateTime.now());

    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today.add(const Duration(days: 1)),
      firstDate: today,
      lastDate: DateTime(today.year + 5),
      helpText: 'Select Homework Due Date',
    );

    if (selected != null && mounted) {
      setState(() => _dueDate = selected);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Homework ki due date select karein.'),
        ),
      );
      return;
    }

    final success = await widget.onSubmit(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _dueDate!,
    );

    if (success && mounted) {
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _dueDate = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _dueDate == null
        ? 'Select due date'
        : '${_dueDate!.day.toString().padLeft(2, '0')}/'
            '${_dueDate!.month.toString().padLeft(2, '0')}/'
            '${_dueDate!.year}';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Homework Title',
              hintText: 'e.g. Chapter 3 Questions',
              prefixIcon: Icon(Icons.menu_book_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Homework title enter karein.';
              }
              if (value.trim().length > 150) {
                return 'Title 150 characters se chhota rakhein.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Students ko batayein ke kya complete karna hai.',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description enter karein.';
              }
              if (value.trim().length > 5000) {
                return 'Description 5000 characters se chhoti rakhein.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: widget.isSaving ? null : _selectDueDate,
            icon: const Icon(Icons.calendar_month),
            label: Text('Due Date: $dateText'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.isSaving ? null : _submit,
            icon: widget.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.publish),
            label: Text(
              widget.isSaving ? 'Publishing...' : 'Publish Homework',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Publish karne par homework assigned section ke students ke parent accounts mein available hoga.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

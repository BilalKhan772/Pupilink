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
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _muted = Color(0xFF68766E);
  static const Color _text = Color(0xFF202B25);

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
    final existingDate = _dueDate ?? today.add(const Duration(days: 1));
    final initialDate = existingDate.isBefore(today) ? today : existingDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
      helpText: 'Select Homework Due Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _green,
              onPrimary: Colors.white,
              secondary: _darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _dueDate = DateUtils.dateOnly(selected));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please select a homework due date.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final success = await widget.onSubmit(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate!,
    );

    if (success && mounted) {
      _formKey.currentState!.reset();
      _titleController.clear();
      _descriptionController.clear();
      setState(() => _dueDate = null);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _green, size: 21),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: const Color(0xFFFCFDFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _green, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFB42318)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFB42318),
          width: 1.4,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateText = _dueDate == null
        ? 'Choose a due date'
        : _formatDate(_dueDate!);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            enabled: !widget.isSaving,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 150,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Homework Title',
              hint: 'e.g. Chapter 3 Questions',
              icon: Icons.menu_book_outlined,
            ).copyWith(counterText: ''),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a homework title.';
              }
              if (value.trim().length > 150) {
                return 'The title must be 150 characters or fewer.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            enabled: !widget.isSaving,
            minLines: 4,
            maxLines: 8,
            maxLength: 5000,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              label: 'Instructions and Description',
              hint: 'Explain what students need to complete.',
              icon: Icons.description_outlined,
              alignLabelWithHint: true,
            ).copyWith(counterText: ''),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter homework instructions.';
              }
              if (value.trim().length > 5000) {
                return 'The description must be 5,000 characters or fewer.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Due Date',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.isSaving ? null : _selectDueDate,
            style: OutlinedButton.styleFrom(
              foregroundColor: _darkGreen,
              side: BorderSide(
                color: _dueDate == null ? _border : const Color(0xFFB8D8C2),
              ),
              backgroundColor: const Color(0xFFFCFDFC),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F3E9),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: _green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDateText,
                        style: TextStyle(
                          color: _dueDate == null ? _muted : _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _dueDate == null
                            ? 'Select when this homework is due'
                            : 'Homework deadline selected',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: widget.isSaving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF9AC8AA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: widget.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(
                widget.isSaving ? 'Publishing Homework...' : 'Publish Homework',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 11),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: _muted,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Published homework will be available to parent accounts for students in your assigned section.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

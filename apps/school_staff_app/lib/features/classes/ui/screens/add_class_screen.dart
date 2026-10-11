
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/classes_controller.dart';
import '../widgets/class_form.dart';

class AddClassScreen extends ConsumerWidget {
  const AddClassScreen({
    super.key,
    required this.schoolId,
  });

  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classesControllerProvider);
    final controller = ref.read(classesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Class')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a class',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Class details enter karein. Academic year optional hai.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorMessage(state.errorMessage!),
                ],
                const SizedBox(height: 24),
                ClassForm(
                  academicYears: state.academicYears,
                  isSaving: state.isSaving,
                  onSubmit: ({
                    required name,
                    academicYearId,
                    sortOrder,
                  }) async {
                    final success = await controller.addClass(
                      schoolId: schoolId,
                      name: name,
                      academicYearId: academicYearId,
                      sortOrder: sortOrder,
                    );

                    if (success && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFB91C1C)),
      ),
    );
  }
}

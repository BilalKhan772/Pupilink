
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../logic/classes_controller.dart';
import '../widgets/class_form.dart';

class EditClassScreen extends ConsumerWidget {
  const EditClassScreen({
    super.key,
    required this.schoolClass,
  });

  final SchoolClass schoolClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(classesControllerProvider);
    final controller = ref.read(
      classesControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Class'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${schoolClass.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Class ki details update karein.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ClassForm(
                  initialClass: schoolClass,
                  academicYears: state.academicYears,
                  isSaving: state.isSaving,
                  onSubmit: ({
                    required String name,
                    String? academicYearId,
                    int? sortOrder,
                  }) async {
                    final success = await controller.updateClass(
                      classId: schoolClass.id,
                      schoolId: schoolClass.schoolId,
                      name: name,
                      academicYearId: academicYearId,
                      sortOrder: sortOrder,
                      isActive: schoolClass.isActive,
                    );

                    if (!context.mounted) return;

                    if (success) {
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

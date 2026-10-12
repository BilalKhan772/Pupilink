
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../logic/students_controller.dart';
import '../widgets/student_form.dart';

class EditStudentScreen extends ConsumerWidget {
  const EditStudentScreen({
    super.key,
    required this.student,
  });

  final Student student;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studentsControllerProvider);
    final controller = ref.read(studentsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Student')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.errorMessage != null) ...[
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                ],
                StudentForm(
                  initialStudent: student,
                  classes: state.classes,
                  sections: state.sections,
                  isSaving: state.isSaving,
                  onSubmit: ({
                    required name,
                    required admissionNumber,
                    required city,
                    required schoolName,
                    required classId,
                    required sectionId,
                  }) {
                    return controller.updateStudent(
                      student: student,
                      name: name,
                      admissionNumber: admissionNumber,
                      city: city,
                      schoolName: schoolName,
                      classId: classId,
                      sectionId: sectionId,
                    );
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../logic/sections_controller.dart';
import '../../logic/sections_state.dart';
import '../widgets/section_form.dart';

class EditSectionScreen extends ConsumerWidget {
  const EditSectionScreen({super.key, required this.section});

  final SchoolSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SectionsState state = ref.watch(sectionsControllerProvider);
    final controller = ref.read(sectionsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Section')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${section.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (state.classes.isEmpty)
                  const Text(
                    'Koi class available nahi hai. Pehle Classes module check karein.',
                  )
                else
                  SectionForm(
                    initialSection: section,
                    classes: state.classes,
                    isSaving: state.isSaving,

                    onSubmit:
                        ({
                          required String name,
                          required String classId,
                          String? academicYearId,
                          String? classTeacherId,
                          int? capacity,
                        }) async {
                          final success = await controller.updateSection(
                            sectionId: section.id,
                            schoolId: section.schoolId,
                            classId: classId,
                            name: name,
                            academicYearId: academicYearId,
                            classTeacherId: classTeacherId,
                            capacity: capacity,
                            isActive: section.isActive,
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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/sections_controller.dart';
import '../../logic/sections_state.dart';
import '../widgets/section_form.dart';

class AddSectionScreen extends ConsumerWidget {
  const AddSectionScreen({
    super.key,
    required this.schoolId,
  });

  final String schoolId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SectionsState state = ref.watch(sectionsControllerProvider);
    final controller = ref.read(sectionsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Section')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a section',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Class select karein aur section ki details enter karein.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ErrorMessage(message: state.errorMessage!),
                ],
                const SizedBox(height: 24),
                if (state.classes.isEmpty)
                  const Text(
                    'Koi active class nahi mili. Pehle Classes module mein class create karein.',
                  )
                else
                  SectionForm(
                    classes: state.classes,
                    isSaving: state.isSaving,
                    onSubmit: ({
                      required classId,
                      required name,
                      capacity,
                    }) async {
                      final success = await controller.addSection(
                        schoolId: schoolId,
                        classId: classId,
                        name: name,
                        capacity: capacity,
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

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

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

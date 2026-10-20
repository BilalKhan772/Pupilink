
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/homework_controller.dart';
import '../../logic/homework_state.dart';
import '../widgets/homework_entry_form.dart';

class MonitorHomeworkUploadScreen extends ConsumerStatefulWidget {
  const MonitorHomeworkUploadScreen({super.key});

  @override
  ConsumerState<MonitorHomeworkUploadScreen> createState() =>
      _MonitorHomeworkUploadScreenState();
}

class _MonitorHomeworkUploadScreenState
    extends ConsumerState<MonitorHomeworkUploadScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(homeworkControllerProvider.notifier).loadAssignment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeworkControllerProvider);

    ref.listen<HomeworkState>(homeworkControllerProvider, (previous, next) {
      if (!mounted) return;

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Homework'),
        actions: [
          IconButton(
            tooltip: 'Refresh assignment',
            onPressed: state.isLoading
                ? null
                : () => ref
                    .read(homeworkControllerProvider.notifier)
                    .loadAssignment(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && !state.hasAssignment
              ? _buildError(state)
              : !state.hasAssignment
                  ? _buildError(state)
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(homeworkControllerProvider.notifier)
                          .loadAssignment(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Assignment',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 12),
                                  _infoRow(
                                    Icons.school_outlined,
                                    'Class ID',
                                    state.classId.isEmpty
                                        ? 'Not available'
                                        : state.classId,
                                  ),
                                  const SizedBox(height: 8),
                                  _infoRow(
                                    Icons.groups_outlined,
                                    'Section',
                                    state.sectionName.isEmpty
                                        ? state.sectionId
                                        : state.sectionName,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Create New Homework',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: HomeworkEntryForm(
                                isSaving: state.isSaving,
                                onSubmit: ({
                                  required title,
                                  required subject,
                                  required description,
                                  required dueDate,
                                }) {
                                  return ref
                                      .read(
                                        homeworkControllerProvider.notifier,
                                      )
                                      .publishHomework(
                                        title: title,
                                        subject: subject,
                                        description: description,
                                        dueDate: dueDate,
                                      );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildError(HomeworkState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ??
                  'Monitor assignment available nahi hai.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(homeworkControllerProvider.notifier)
                  .loadAssignment(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

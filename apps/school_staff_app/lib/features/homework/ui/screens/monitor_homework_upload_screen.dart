
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
      if (mounted) {
        ref.read(homeworkControllerProvider.notifier).loadAssignment();
      }
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
            tooltip: 'Refresh',
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
          : !state.hasAssignment
              ? _buildError(state)
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(homeworkControllerProvider.notifier)
                      .loadAssignment(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                Icons.school_outlined,
                                'Class',
                                state.className.isNotEmpty
                                    ? state.className
                                    : 'Not available',
                              ),
                              const SizedBox(height: 8),
                              _infoRow(
                                Icons.groups_outlined,
                                'Section',
                                state.sectionName.isNotEmpty
                                    ? state.sectionName
                                    : 'Not available',
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
                              required description,
                              required dueDate,
                            }) {
                              return ref
                                  .read(homeworkControllerProvider.notifier)
                                  .publishHomework(
                                    title: title,
                                    description: description,
                                    dueDate: dueDate,
                                  );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Uploaded Homework',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (state.recentHomework.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('Abhi tak homework upload nahi hua.'),
                            ),
                          ),
                        )
                      else
                        ...state.recentHomework.map(
                          (homework) => _homeworkCard(homework),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _homeworkCard(Map<String, dynamic> homework) {
    final title = homework['title'] as String? ?? 'Homework';
    final description = homework['description'] as String? ?? '';
    final dueDate = _formatDate(homework['dueDate']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description),
            ],
            if (dueDate.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Due: $dueDate'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value is DateTime) {
      return '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
    }

    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return '${parsed.year.toString().padLeft(4, '0')}-'
            '${parsed.month.toString().padLeft(2, '0')}-'
            '${parsed.day.toString().padLeft(2, '0')}';
      }
    }

    return '';
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

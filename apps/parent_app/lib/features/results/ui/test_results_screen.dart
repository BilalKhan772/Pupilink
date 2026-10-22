
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/parent_results_controller.dart';
import '../logic/parent_results_state.dart';
import 'subject_results_screen.dart';

class TestResultsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> child;

  const TestResultsScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<TestResultsScreen> createState() =>
      _TestResultsScreenState();
}

class _TestResultsScreenState
    extends ConsumerState<TestResultsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(parentResultsControllerProvider.notifier)
          .loadResults(
            studentId: widget.child['studentId'] as String? ?? '',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentResultsControllerProvider);

    final studentName =
        widget.child['name'] as String? ?? 'Student';

    final groupedResults = _groupResultsBySubject(state.records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(parentResultsControllerProvider.notifier)
                    .loadResults(
                      studentId:
                          widget.child['studentId'] as String? ?? '',
                    );
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Academic Results',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  if (state.error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  if (state.records.isEmpty)
                    _emptyResults()
                  else ...[
                    _summaryCard(state),
                    const SizedBox(height: 24),
                    const Text(
                      'Subject Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...groupedResults.entries.map((entry) {
                      final results = entry.value;
                      final totalObtained = _totalObtained(results);
                      final totalPossible = _totalPossible(results);
                      final percentage = totalPossible == 0
                          ? 0.0
                          : (totalObtained / totalPossible) * 100;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _subjectCard(
                          subject: entry.key,
                          results: results,
                          totalObtained: totalObtained,
                          totalPossible: totalPossible,
                          percentage: percentage,
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupResultsBySubject(
    List<Map<String, dynamic>> records,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final record in records) {
      final subjectValue = record['subject'];
      final subject = subjectValue is String &&
              subjectValue.trim().isNotEmpty
          ? subjectValue.trim()
          : 'Subject';

      grouped.putIfAbsent(subject, () => []).add(record);
    }

    final entries = grouped.entries.toList()
      ..sort(
        (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      );

    return {
      for (final entry in entries) entry.key: entry.value,
    };
  }

  int _totalObtained(List<Map<String, dynamic>> results) {
    return results.fold<int>(0, (sum, result) {
      final value = result['obtainedMarks'];
      return sum + (value is num ? value.toInt() : 0);
    });
  }

  int _totalPossible(List<Map<String, dynamic>> results) {
    return results.fold<int>(0, (sum, result) {
      final value = result['totalMarks'];
      return sum + (value is num ? value.toInt() : 0);
    });
  }

  Widget _summaryCard(ParentResultsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Overall Result',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              '${state.totalObtainedMarks} / ${state.totalPossibleMarks}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Grade: ${state.grade}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tests: ${state.records.length}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectCard({
    required String subject,
    required List<Map<String, dynamic>> results,
    required int totalObtained,
    required int totalPossible,
    required double percentage,
  }) {
    final progress = (percentage / 100).clamp(0.0, 1.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectResultsScreen(
                subject: subject,
                results: results,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.withValues(alpha: 0.10),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${results.length} ${results.length == 1 ? 'test' : 'tests'}'
                      '  •  $totalObtained / $totalPossible marks',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.green.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyResults() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(Icons.assessment, size: 60),
            SizedBox(height: 12),
            Text(
              'No Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Abhi is child ke results available nahi hain.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

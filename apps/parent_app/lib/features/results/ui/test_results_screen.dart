
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
  String get _studentId =>
      widget.child['studentId'] as String? ?? '';

  String get _schoolId =>
      widget.child['schoolId'] as String? ?? '';

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadResults);
  }

  Future<void> _loadResults() async {
    await ref
        .read(parentResultsControllerProvider.notifier)
        .loadResults(
          studentId: _studentId,
          schoolId: _schoolId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentResultsControllerProvider);

    final studentName =
        widget.child['name'] as String? ?? 'Student';

    // Temporary test records grouped by subject.
    final groupedResults = _groupResultsBySubject(state.records);

    // Permanent subject summaries are the source of truth for averages.
    final permanentSubjects = state.subjectAverages;

    // Match temporary tests to their permanent subject summary.
    final displayedSubjects = <String, Map<String, dynamic>>{};

    for (final average in permanentSubjects) {
      final subject = _subjectName(average);
      displayedSubjects[subject] = {
        'average': average,
        'results': groupedResults[subject] ?? <Map<String, dynamic>>[],
      };
    }

    // Also display subjects that have temporary results but no saved average.
    for (final entry in groupedResults.entries) {
      displayedSubjects.putIfAbsent(entry.key, () {
        final results = entry.value;
        final obtained = _totalObtained(results);
        final possible = _totalPossible(results);

        return {
          'average': {
            'obtainedMarks': obtained,
            'totalMarks': possible,
            'percentage': possible == 0
                ? 0.0
                : obtained / possible * 100,
            'testCount': results.length,
          },
          'results': results,
        };
      });
    }

    final hasAnySummary =
        permanentSubjects.isNotEmpty || state.studentAverage != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadResults,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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

                  if (state.studentAverage != null ||
                      state.records.isNotEmpty)
                    _summaryCard(state)
                  else if (!hasAnySummary)
                    _emptyResults(),

                  if (displayedSubjects.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Subject Performance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...displayedSubjects.entries.map((entry) {
                      final summary = entry.value['average']
                          as Map<String, dynamic>;
                      final results = entry.value['results']
                          as List<Map<String, dynamic>>;

                      final totalObtained =
                          _number(summary['obtainedMarks']);
                      final totalPossible =
                          _number(summary['totalMarks']);

                      final percentageValue = summary['percentage'];
                      final percentage = percentageValue is num
                          ? percentageValue.toDouble()
                          : (totalPossible == 0
                              ? 0.0
                              : totalObtained /
                                  totalPossible *
                                  100);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _subjectCard(
                          subject: entry.key,
                          results: results,
                          totalObtained: totalObtained,
                          totalPossible: totalPossible,
                          percentage: percentage,
                          testCount: _number(
                            summary['testCount'],
                            fallback: results.length,
                          ),
                        ),
                      );
                    }),
                  ],

                  if (state.records.isEmpty &&
                      (state.studentAverage != null ||
                          permanentSubjects.isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                          'Purane individual test results expire ho chuke '
                          'hain. Saved subject aur overall averages yahan '
                          'available reh sakte hain.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _subjectName(Map<String, dynamic> record) {
    for (final key in ['subject', 'subjectName', 'subjectId']) {
      final value = record[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'Subject';
  }

  Map<String, List<Map<String, dynamic>>> _groupResultsBySubject(
    List<Map<String, dynamic>> records,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final record in records) {
      final subject = _subjectName(record);
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

  int _number(dynamic value, {int fallback = 0}) {
    return value is num ? value.toInt() : fallback;
  }

  int _totalObtained(List<Map<String, dynamic>> results) {
    return results.fold<int>(0, (sum, result) {
      return sum + _number(result['obtainedMarks']);
    });
  }

  int _totalPossible(List<Map<String, dynamic>> results) {
    return results.fold<int>(0, (sum, result) {
      return sum + _number(result['totalMarks']);
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
              'Unexpired tests: ${state.records.length}',
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
    required int testCount,
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
                      '$testCount ${testCount == 1 ? 'test' : 'tests'}'
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
                        backgroundColor:
                            Colors.green.withValues(alpha: 0.12),
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
              'Abhi is child ke results ya saved averages available nahi hain.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/parent_results_controller.dart';
import '../logic/parent_results_state.dart';
import 'test_result_detail_screen.dart';


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
          .read(
            parentResultsControllerProvider.notifier,
          )
          .loadResults(
            studentId:
                widget.child['studentId']
                        as String? ??
                    '',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      parentResultsControllerProvider,
    );

    final studentName =
        widget.child['name'] as String? ??
            'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Results',
        ),
      ),
      body: state.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(
                      parentResultsControllerProvider
                          .notifier,
                    )
                    .loadResults(
                      studentId:
                          widget.child['studentId']
                                  as String? ??
                              '',
                    );
              },
              child: ListView(
                padding:
                    const EdgeInsets.all(20),
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Academic Results',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (state.error != null)
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        child: Text(
                          state.error!,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                  if (state.records.isEmpty)
                    _emptyResults()
                  else ...[
                    _summaryCard(state),

                    const SizedBox(height: 20),

                    const Text(
                      'Subject Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ...state.records.map(
                      (record) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _resultCard(
                            context,
                            record,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(
    ParentResultsState state,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Overall Result',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              '${state.totalObtainedMarks} / '
              '${state.totalPossibleMarks}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${state.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Grade: ${state.grade}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Subjects: ${state.totalSubjects}',
              style: TextStyle(
                color:
                    Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    final subject =
        record['subject'] as String? ??
            'Subject';

    final obtained =
        record['obtainedMarks'] as num? ??
            0;

    final total =
        record['totalMarks'] as num? ??
            0;

    final percentage =
        total == 0
            ? 0
            : (obtained / total) * 100;

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(
            Icons.assessment,
          ),
        ),
        title: Text(
          subject,
          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${obtained.toInt()} / ${total.toInt()}'
          '  •  '
          '${percentage.toStringAsFixed(1)}%',
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TestResultDetailScreen(
                result: record,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyResults() {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(
              Icons.assessment,
              size: 60,
            ),

            SizedBox(height: 12),

            Text(
              'No Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Abhi is child ke results '
              'available nahi hain.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
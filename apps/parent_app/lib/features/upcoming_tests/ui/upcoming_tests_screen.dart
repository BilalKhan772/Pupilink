import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/upcoming_tests_controller.dart';
import '../logic/upcoming_tests_state.dart';
import 'widgets/upcoming_test_card.dart';
import 'widgets/test_countdown_chip.dart';

class UpcomingTestsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> child;

  const UpcomingTestsScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<UpcomingTestsScreen> createState() =>
      _UpcomingTestsScreenState();
}

class _UpcomingTestsScreenState
    extends ConsumerState<UpcomingTestsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _loadTests();
    });
  }

  Future<void> _loadTests() async {
    final studentId =
        widget.child['studentId'] as String? ?? '';

    if (studentId.isEmpty) {
      return;
    }

    await ref
        .read(
          upcomingTestsControllerProvider
              .notifier,
        )
        .loadUpcomingTests(
          studentId: studentId,
        );
  }

  Future<void> _refresh() async {
    final studentId =
        widget.child['studentId'] as String? ?? '';

    if (studentId.isEmpty) {
      return;
    }

    await ref
        .read(
          upcomingTestsControllerProvider
              .notifier,
        )
        .refresh(
          studentId: studentId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(
      upcomingTestsControllerProvider,
    );

    final studentName =
        widget.child['name'] as String? ??
            'Child';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upcoming Tests',
        ),
      ),
      body: state.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding:
                    const EdgeInsets.all(20),
                children: [
                  _buildHeader(
                    studentName,
                    state,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  if (state.error != null)
                    _buildError(
                      state.error!,
                    ),

                  if (state.records.isEmpty)
                    _buildEmptyState()
                  else
                    ...state.records.map(
                      (test) {
                        return _buildTestItem(
                          test,
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(
    String studentName,
    UpcomingTestsState state,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(
                Icons.quiz,
                size: 30,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Tests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    studentName,
                    style: TextStyle(
                      color:
                          Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    state.totalTests == 0
                        ? 'No upcoming tests'
                        : '${state.totalTests} upcoming test${state.totalTests == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestItem(
    Map<String, dynamic> test,
  ) {
    final date =
        test['date'] as String? ?? '';

    return Column(
      children: [
        UpcomingTestCard(
          test: test,
        ),

        if (date.isNotEmpty)
          Align(
            alignment:
                Alignment.centerRight,
            child: Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
                bottom: 12,
              ),
              child: TestCountdownChip(
                date: date,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildError(
    String message,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(35),
        child: Column(
          children: [
            Icon(
              Icons.event_available,
              size: 70,
            ),

            SizedBox(height: 15),

            Text(
              'No Upcoming Tests',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Abhi is child ke liye koi upcoming test available nahi hai.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
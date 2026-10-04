import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/parent_homework_controller.dart';
import 'homework_detail_screen.dart';
import 'widgets/homework_date_group.dart';
import 'widgets/homework_filter_bar.dart';

class HomeworkScreen
    extends ConsumerStatefulWidget {
  final Map<String, dynamic> child;

  const HomeworkScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<HomeworkScreen>
      createState() =>
          _HomeworkScreenState();
}

class _HomeworkScreenState
    extends ConsumerState<HomeworkScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(
            parentHomeworkControllerProvider
                .notifier,
          )
          .loadHomework(
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
      parentHomeworkControllerProvider,
    );

    final studentName =
        widget.child['name'] as String? ??
            'Student';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Homework',
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
                      parentHomeworkControllerProvider
                          .notifier,
                    )
                    .loadHomework(
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
                    'Homework & Assignments',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  HomeworkFilterBar(
                    selectedFilter:
                        state.selectedFilter,
                    onChanged: (filter) {
                      ref
                          .read(
                            parentHomeworkControllerProvider
                                .notifier,
                          )
                          .setFilter(filter);
                    },
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

                  if (state.filteredRecords.isEmpty)
                    _emptyHomework()
                  else
                    ..._buildGroups(
                      state.filteredRecords,
                    ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildGroups(
    List<Map<String, dynamic>> records,
  ) {
    final Map<String,
            List<Map<String, dynamic>>>
        groups = {};

    for (final record in records) {
      final date =
          record['dueDate'] as String? ??
              '';

      groups.putIfAbsent(
        date,
        () => [],
      ).add(record);
    }

    return groups.entries.map(
      (entry) {
        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 20,
          ),
          child: HomeworkDateGroup(
            date: entry.key,
            homework: entry.value,
            onHomeworkTap:
                _openHomeworkDetail,
          ),
        );
      },
    ).toList();
  }

  void _openHomeworkDetail(
    Map<String, dynamic> homework,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HomeworkDetailScreen(
          homework: homework,
        ),
      ),
    );
  }

  Widget _emptyHomework() {
    return const Card(
      child: Padding(
        padding:
            EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(
              Icons.menu_book,
              size: 60,
            ),

            SizedBox(height: 12),

            Text(
              'No Homework',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Abhi is child ka homework '
              'available nahi hai.',
              textAlign:
                  TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
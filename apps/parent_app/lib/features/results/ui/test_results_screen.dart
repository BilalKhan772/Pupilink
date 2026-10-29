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

class _TestResultsScreenState extends ConsumerState<TestResultsScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

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
    await ref.read(parentResultsControllerProvider.notifier).loadResults(
          studentId: _studentId,
          schoolId: _schoolId,
        );
  }

  String _normalizeSubjectName(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _subjectKey(String subjectName) {
    final normalized = _normalizeSubjectName(subjectName);
    final compact = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (const {'math', 'maths', 'mathematics'}.contains(compact)) {
      return 'math';
    }

    return normalized;
  }

  String _displaySubjectName(String name) {
    if (_subjectKey(name) == 'math') return 'Math';

    return name.trim().isEmpty ? 'Subject' : name.trim();
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

  double _number(dynamic value, {double fallback = 0}) {
    return value is num ? value.toDouble() : fallback;
  }

  int _integer(dynamic value, {int fallback = 0}) {
    return value is num ? value.toInt() : fallback;
  }

  String _formatMarks(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  DateTime? _parseResultDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  List<Map<String, dynamic>> _sortedUniqueResults(
    List<Map<String, dynamic>> source,
  ) {
    final sorted = List<Map<String, dynamic>>.from(source);

    sorted.sort((a, b) {
      final dateA = _parseResultDate(a['date']);
      final dateB = _parseResultDate(b['date']);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    final unique = <String, Map<String, dynamic>>{};

    for (final result in sorted) {
      final examId = result['examId']?.toString().trim() ?? '';
      final recordId = result['id']?.toString().trim() ?? '';

      final key = examId.isNotEmpty
          ? examId
          : recordId.isNotEmpty
              ? recordId
              : '${result['testName']}_${result['date']}';

      unique.putIfAbsent(key, () => result);
    }

    return unique.values.toList();
  }

  /// Combines same-name permanent summaries instead of overwriting them.
  ///
  /// Temporary results are listed only while they are unexpired.
  /// If visible results outnumber the permanent summary's testCount,
  /// the newest missing result records are included in the display totals.
  /// The source mark and permanent summary are not modified here.
  Map<String, Map<String, dynamic>> _buildDisplayedSubjects(
    ParentResultsState state,
  ) {
    final groups = <String, Map<String, dynamic>>{};

    Map<String, dynamic> ensureGroup(
      String key,
      String displayName,
    ) {
      return groups.putIfAbsent(key, () {
        return {
          'subjectName': _displaySubjectName(displayName),
          'obtainedMarks': 0.0,
          'totalMarks': 0.0,
          'testCount': 0,
          'hasPermanentSummary': false,
          'results': <Map<String, dynamic>>[],
        };
      });
    }

    // Combine permanent summaries. Different subject IDs can refer to
    // the same display subject when sections were configured separately.
    for (final average in state.subjectAverages) {
      final rawName = _subjectName(average);
      final key = _subjectKey(rawName);
      final group = ensureGroup(key, rawName);

      group['hasPermanentSummary'] = true;
      group['obtainedMarks'] =
          (group['obtainedMarks'] as double) +
          _number(average['obtainedMarks']);
      group['totalMarks'] =
          (group['totalMarks'] as double) +
          _number(average['totalMarks']);
      group['testCount'] =
          (group['testCount'] as int) +
          _integer(average['testCount']);
    }

    // Group currently available individual results by canonical subject.
    for (final record in state.records) {
      final rawName = _subjectName(record);
      final key = _subjectKey(rawName);
      final group = ensureGroup(key, rawName);

      (group['results'] as List<Map<String, dynamic>>).add(record);
    }

    for (final group in groups.values) {
      final permanentTestCount = group['testCount'] as int;
      final records = _sortedUniqueResults(
        group['results'] as List<Map<String, dynamic>>,
      );

      group['results'] = records;

      // If a permanent summary already contains all currently visible
      // results, do not add them again.
      final missingCount = records.length > permanentTestCount
          ? records.length - permanentTestCount
          : 0;

      if (missingCount > 0) {
        for (final record in records.take(missingCount)) {
          group['obtainedMarks'] =
              (group['obtainedMarks'] as double) +
              _number(record['obtainedMarks']);
          group['totalMarks'] =
              (group['totalMarks'] as double) +
              _number(record['totalMarks']);
        }
      }

      // The count reflects the greater of the permanent count and the
      // currently visible unique result count.
      group['testCount'] = permanentTestCount > records.length
          ? permanentTestCount
          : records.length;

      final total = group['totalMarks'] as double;
      final obtained = group['obtainedMarks'] as double;

      group['percentage'] =
          total > 0 ? (obtained / total) * 100 : 0.0;
    }

    final sortedEntries = groups.entries.toList()
      ..sort(
        (a, b) => (a.value['subjectName'] as String)
            .toLowerCase()
            .compareTo(
              (b.value['subjectName'] as String).toLowerCase(),
            ),
      );

    return {
      for (final entry in sortedEntries) entry.key: entry.value,
    };
  }

  double _gradePercentage(Map<String, dynamic> summary) {
    final explicit = summary['percentage'];

    if (explicit is num) return explicit.toDouble();

    final obtained = _number(summary['obtainedMarks']);
    final total = _number(summary['totalMarks']);

    return total > 0 ? obtained / total * 100 : 0;
  }

  String _gradeFor(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentResultsControllerProvider);
    final studentName =
        widget.child['name'] as String? ?? 'Student';

    final displayedSubjects = _buildDisplayedSubjects(state);
    final hasAnySummary = state.subjectAverages.isNotEmpty ||
        state.studentAverage != null ||
        state.records.isNotEmpty;

    // Prefer the combined subject totals. This also handles the case where
    // multiple summary documents share the same display subject.
    double overallObtained = 0;
    double overallPossible = 0;

    for (final group in displayedSubjects.values) {
      overallObtained += group['obtainedMarks'] as double;
      overallPossible += group['totalMarks'] as double;
    }

    if (displayedSubjects.isEmpty && state.studentAverage != null) {
      overallObtained = _number(
        state.studentAverage!['totalObtainedMarks'],
      );
      overallPossible = _number(
        state.studentAverage!['totalPossibleMarks'],
      );
    } else if (displayedSubjects.isEmpty && state.records.isNotEmpty) {
      for (final record in state.records) {
        overallObtained += _number(record['obtainedMarks']);
        overallPossible += _number(record['totalMarks']);
      }
    }

    final overallPercentage = overallPossible > 0
        ? overallObtained / overallPossible * 100
        : 0.0;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Results'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _green),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth < 600 ? 16.0 : 24.0;
                final contentWidth = constraints.maxWidth >= 1200
                    ? 1120.0
                    : constraints.maxWidth;

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    child: RefreshIndicator(
                      onRefresh: _loadResults,
                      color: _green,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          22,
                          horizontalPadding,
                          36,
                        ),
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Academic Results',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (state.error != null) ...[
                            _ErrorCard(
                              message:
                                  'Unable to refresh results. Please check your connection and try again.',
                              onRetry: _loadResults,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (hasAnySummary)
                            _overallSummaryCard(
                              obtained: overallObtained,
                              total: overallPossible,
                              percentage: overallPercentage,
                              unexpiredCount: state.records.length,
                            )
                          else
                            const _EmptyResults(),
                          if (displayedSubjects.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _sectionHeader(
                              title: 'Subject Performance',
                              subtitle:
                                  'All-time averages with available individual test results',
                              count: displayedSubjects.length,
                            ),
                            const SizedBox(height: 12),
                            ...displayedSubjects.entries.map((entry) {
                              final group = entry.value;
                              final results =
                                  group['results'] as List<Map<String, dynamic>>;

                              final obtained =
                                  group['obtainedMarks'] as double;
                              final total = group['totalMarks'] as double;
                              final percentage =
                                  group['percentage'] as double;
                              final testCount = group['testCount'] as int;

                              final averageSummary = <String, dynamic>{
                                'subject': group['subjectName'],
                                'obtainedMarks': obtained,
                                'totalMarks': total,
                                'percentage': percentage,
                                'testCount': testCount,
                              };

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _subjectCard(
                                  subject: group['subjectName'] as String,
                                  results: results,
                                  averageSummary: averageSummary,
                                ),
                              );
                            }),
                          ],
                          if (state.records.isEmpty &&
                              (state.studentAverage != null ||
                                  state.subjectAverages.isNotEmpty)) ...[
                            const SizedBox(height: 12),
                            const _InformationCard(
                              message:
                                  'Individual test results may expire and disappear from this list. Published marks remain included in saved subject and overall averages.',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _overallSummaryCard({
    required double obtained,
    required double total,
    required double percentage,
    required int unexpiredCount,
  }) {
    final progress =
        (percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFE4F3E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.track_changes_rounded,
              color: _darkGreen,
              size: 27,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Overall Result',
            style: TextStyle(
              color: _text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatMarks(obtained)} / ${_formatMarks(total)}',
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: _green,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Grade: ${_gradeFor(percentage)}',
            style: const TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: _green,
              backgroundColor: const Color(0xFFDCEBE1),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Unexpired individual test results: $unexpiredCount',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F3E9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _subjectCard({
    required String subject,
    required List<Map<String, dynamic>> results,
    required Map<String, dynamic> averageSummary,
  }) {
    final obtained = _number(averageSummary['obtainedMarks']);
    final total = _number(averageSummary['totalMarks']);
    final percentage = _number(averageSummary['percentage']);
    final testCount = _integer(averageSummary['testCount']);
    final progress =
        (percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SubjectResultsScreen(
                subject: subject,
                results: results,
                averageSummary: averageSummary,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5F3E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: _green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$testCount ${testCount == 1 ? 'test' : 'tests'} counted'
                          '  •  ${_formatMarks(obtained)} / ${_formatMarks(total)} marks',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _muted,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  color: const Color(0xFF4CAF50),
                  backgroundColor: const Color(0xFFDCEBE1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyResults() {
    return const _EmptyResults();
  }

  
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE9E1)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assessment_outlined,
            color: Color(0xFF105C3B),
            size: 48,
          ),
          SizedBox(height: 14),
          Text(
            'No Results Yet',
            style: TextStyle(
              color: Color(0xFF202B25),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Published marks and saved averages will appear here when available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF68766E),
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF3C6C2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF912018),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8EBDD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF267344),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF315B40),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
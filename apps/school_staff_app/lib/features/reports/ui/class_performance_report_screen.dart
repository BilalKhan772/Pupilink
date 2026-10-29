import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/school_reports_controller.dart';
import '../logic/school_reports_state.dart';

class ClassPerformanceReportScreen extends ConsumerStatefulWidget {
  const ClassPerformanceReportScreen({
    super.key,
    required this.schoolId,
    required this.sectionMode,
  });

  final String schoolId;
  final bool sectionMode;

  @override
  ConsumerState<ClassPerformanceReportScreen> createState() =>
      _ClassPerformanceReportScreenState();
}

class _ClassPerformanceReportScreenState
    extends ConsumerState<ClassPerformanceReportScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _canvas = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF68766E);

  late final SchoolReportsController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ref.read(
      schoolReportsControllerProvider(widget.schoolId),
    );
    _controller.addListener(_onControllerChanged);

    Future.microtask(() {
      if (mounted) _controller.loadClasses();
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  String _userFacingError(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    final value = raw.toLowerCase();
    if (value.contains('permission-denied') || value.contains('permission')) {
      return 'You do not have permission to access this report.';
    }
    if (value.contains('unavailable') || value.contains('network')) {
      return 'The service is temporarily unavailable. Check your connection and try again.';
    }
    if (value.contains('classes load') || value.contains('class load')) {
      return 'Unable to load classes. Please refresh and try again.';
    }
    if (value.contains('sections load') || value.contains('section load')) {
      return 'Unable to load sections. Please select the class again.';
    }
    if (value.contains('class aur section') || value.contains('class select')) {
      return 'Please select a class and section before generating this report.';
    }
    if (value.contains('school id') || value.contains('school aur class')) {
      return 'The school or class information is missing. Please sign in again or contact your administrator.';
    }
    return 'Unable to generate the report. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    // Resolve report lists once per build rather than creating repeated copies
    // through the state getters while constructing a long report.
    final subjectReports = state.subjectReports;
    final studentReports = state.studentReports;
    final title = widget.sectionMode ? 'Section Reports' : 'Class Overall Report';

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _darkGreen,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.sectionMode
                  ? 'Review academic performance for a selected section'
                  : 'Review combined academic performance across all sections',
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: state.isLoadingClasses
          ? const Center(child: CircularProgressIndicator(color: _green))
          : LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 600 ? 16.0 : 24.0;
                final maxContentWidth = constraints.maxWidth >= 1250
                    ? 1180.0
                    : constraints.maxWidth;
                final contentInnerWidth =
                    (maxContentWidth - horizontalPadding * 2).clamp(0.0, double.infinity).toDouble();

                // Keep the same report content, but build long report lists
                // lazily. This reduces work when a class has hundreds of students.
                final itemBuilders = <WidgetBuilder>[];

                void addWidget(Widget widget) {
                  itemBuilders.add((_) => widget);
                }

                void addBuilder(WidgetBuilder builder) {
                  itemBuilders.add(builder);
                }

                addWidget(const SizedBox(height: 22));
                addWidget(_buildFilterPanel(state, contentInnerWidth));

                if (state.errorMessage != null) {
                  addWidget(const SizedBox(height: 16));
                  addWidget(
                    _ErrorBanner(
                      message: _userFacingError(state.errorMessage),
                      onRetry: _retry,
                    ),
                  );
                }

                if (state.isLoadingReport) {
                  addWidget(const SizedBox(height: 24));
                  addWidget(const _LoadingPanel());
                }

                if (!state.isLoadingReport && state.hasReport) {
                  addWidget(const SizedBox(height: 24));
                  addWidget(_buildSummary(state, contentInnerWidth));
                  addWidget(const SizedBox(height: 28));
                  addWidget(
                    _buildSectionHeading(
                      title: 'Subject Performance',
                      subtitle: 'Combined results from published marks',
                      count: subjectReports.length,
                    ),
                  );
                  addWidget(const SizedBox(height: 12));

                  if (subjectReports.isEmpty) {
                    addWidget(
                      const _EmptyReport(
                        title: 'No Subject Results',
                        message: 'Published marks are not available for this selection yet.',
                      ),
                    );
                  } else {
                    for (final subject in subjectReports) {
                      addBuilder(
                        (_) => _SubjectReportCard(subject: subject),
                      );
                    }
                  }

                  addWidget(const SizedBox(height: 28));
                  addWidget(
                    _buildSectionHeading(
                      title: 'Student Performance',
                      subtitle: 'Overall marks for each student in the selected scope',
                      count: studentReports.length,
                    ),
                  );
                  addWidget(const SizedBox(height: 12));

                  if (studentReports.isEmpty) {
                    addWidget(
                      const _EmptyReport(
                        title: 'No Student Results',
                        message: 'There are no published marks to display for these students.',
                      ),
                    );
                  } else {
                    // Rank by total obtained marks in the UI so this report
                    // does not depend on the ordering used elsewhere.
                    // Student cards are still instantiated lazily by ListView.builder.
                    final rankedStudents = _rankStudents(studentReports);
                    for (var index = 0; index < rankedStudents.length; index++) {
                      final student = rankedStudents[index];
                      final rank = index + 1;
                      addBuilder(
                        (_) => _StudentReportCard(
                          key: ValueKey(
                            'student-report-${student['studentId'] ?? student['id'] ?? rank}',
                          ),
                          student: student,
                          rank: rank,
                          showSection: !widget.sectionMode,
                        ),
                      );
                    }
                  }
                } else if (!state.isLoadingReport &&
                    !state.hasReport &&
                    state.errorMessage == null) {
                  addWidget(const SizedBox(height: 24));
                  addWidget(
                    const _EmptyReport(
                      title: 'Ready to Generate a Report',
                      message: 'Select a class and generate the report to view subject and student performance.',
                      icon: Icons.assessment_outlined,
                    ),
                  );
                }

                addWidget(const SizedBox(height: 36));

                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: maxContentWidth,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      itemCount: itemBuilders.length,
                      itemBuilder: (context, index) =>
                          itemBuilders[index](context),
                      // Lazy list creation makes scrolling smoother for classes
                      // with 150–300+ students without adding more loading calls.
                      cacheExtent: 500,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Rank students by raw total obtained marks, highest first.
  /// Percentage and student name are deterministic tie-breakers.
  List<Map<String, dynamic>> _rankStudents(
    List<Map<String, dynamic>> students,
  ) {
    final ranked = List<Map<String, dynamic>>.of(students);

    double readNumber(Map<String, dynamic> student, String key) {
      final value = student[key];
      return value is num ? value.toDouble() : 0.0;
    }

    double percentageOf(Map<String, dynamic> student) {
      final explicitPercentage = student['percentage'];
      if (explicitPercentage is num) {
        return explicitPercentage.toDouble();
      }

      final obtained = readNumber(student, 'obtainedMarks');
      final total = readNumber(student, 'totalMarks');
      return total > 0 ? obtained / total * 100 : 0.0;
    }

    ranked.sort((a, b) {
      // First, rank by obtained marks (not percentage).
      final marksComparison = readNumber(b, 'obtainedMarks').compareTo(
        readNumber(a, 'obtainedMarks'),
      );
      if (marksComparison != 0) return marksComparison;

      // When the obtained marks tie, higher percentage comes first.
      final percentageComparison = percentageOf(b).compareTo(
        percentageOf(a),
      );
      if (percentageComparison != 0) return percentageComparison;

      // Stable, deterministic final tie-breaker.
      final nameA = (a['studentName'] as String? ?? '').toLowerCase();
      final nameB = (b['studentName'] as String? ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    return ranked;
  }

  Widget _buildFilterPanel(SchoolReportsState state, double availableWidth) {
    final selectedClassId = state.classes.any((c) => c.id == state.selectedClassId)
        ? state.selectedClassId
        : null;
    final selectedSectionId = state.sections.any(
      (s) => (s['id'] as String? ?? '') == state.selectedSectionId,
    )
        ? state.selectedSectionId
        : null;
    final wide = availableWidth >= 720;
    final fieldWidth = wide
        ? widget.sectionMode
            ? (availableWidth - 16) / 2
            : availableWidth
        : availableWidth;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: _green, size: 21),
              SizedBox(width: 9),
              Text(
                'Report Filters',
                style: TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              SizedBox(
                width: fieldWidth,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedClassId,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    label: 'Select Class',
                    icon: Icons.school_outlined,
                  ),
                  items: state.classes.map((schoolClass) {
                    return DropdownMenuItem<String>(
                      value: schoolClass.id,
                      child: Text(schoolClass.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _controller.selectClass(value);
                  },
                ),
              ),
              if (widget.sectionMode)
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedSectionId,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'Select Section',
                      icon: Icons.grid_view_rounded,
                    ),
                    items: state.sections.map((section) {
                      final sectionId = section['id'] as String? ?? '';
                      final sectionName = section['name'] as String? ??
                          section['sectionName'] as String? ??
                          'Unnamed Section';
                      if (sectionId.isEmpty) return null;
                      return DropdownMenuItem<String>(
                        value: sectionId,
                        child: Text(sectionName, overflow: TextOverflow.ellipsis),
                      );
                    }).whereType<DropdownMenuItem<String>>().toList(),
                    onChanged: state.isLoadingSections
                        ? null
                        : (value) {
                            if (value != null) _controller.selectSection(value);
                          },
                  ),
                ),
            ],
          ),
          if (state.isLoadingSections) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(
              minHeight: 3,
              color: _green,
              backgroundColor: Color(0xFFDCEBE1),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: state.isLoadingReport ||
                      state.selectedClassId == null ||
                      (widget.sectionMode && state.selectedSectionId == null)
                  ? null
                  : () {
                      if (widget.sectionMode) {
                        _controller.loadSectionReport();
                      } else {
                        _controller.loadClassReport();
                      }
                    },
              icon: const Icon(Icons.analytics_outlined, size: 20),
              label: Text(
                state.isLoadingReport ? 'Generating Report...' : 'Generate Report',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(SchoolReportsState state, double availableWidth) {
    final overallObtained = (state.report['overallObtainedMarks'] as num?)?.toDouble() ?? 0;
    final overallTotal = (state.report['overallTotalMarks'] as num?)?.toDouble() ?? 0;
    final twoColumns = availableWidth >= 720;
    final cardWidth = twoColumns ? (availableWidth - 12) / 2 : availableWidth;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: cardWidth,
          child: _SummaryCard(
            title: 'Students in Selected Scope',
            value: '${state.studentCount}',
            subtitle: 'Active students',
            icon: Icons.groups_2_outlined,
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: _SummaryCard(
            title: 'Combined Overall Percentage',
            value: '${state.overallPercentage.toStringAsFixed(1)}%',
            subtitle: null,
            icon: Icons.track_changes_outlined,
            percentage: state.overallPercentage,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading({
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
                style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F3E9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _darkGreen,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _green, size: 20),
      filled: true,
      fillColor: const Color(0xFFFBFDFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
    );
  }

  void _retry() {
    if (widget.sectionMode) {
      if (_controller.state.selectedClassId != null) {
        _controller.selectClass(_controller.state.selectedClassId!);
      } else {
        _controller.loadClasses();
      }
    } else if (_controller.state.selectedClassId != null) {
      _controller.loadClassReport();
    } else {
      _controller.loadClasses();
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.percentage,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final double? percentage;

  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _muted = Color(0xFF68766E);

  @override
  Widget build(BuildContext context) {
    final progress = ((percentage ?? 0) / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F3E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _darkGreen, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: _darkGreen,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
          ],
          if (percentage != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                color: _green,
                backgroundColor: const Color(0xFFDCEBE1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectReportCard extends StatelessWidget {
  const _SubjectReportCard({required this.subject});

  final Map<String, dynamic> subject;

  static const Color _green = Color(0xFF4CAF50);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _muted = Color(0xFF657168);

  @override
  Widget build(BuildContext context) {
    final percentage = (subject['percentage'] as num?)?.toDouble() ?? 0;
    final progress = (percentage / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE5F2E8),
                ),
                child: const Icon(Icons.menu_book_rounded, color: _green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['subjectName'] as String? ?? 'Subject',
                      style: const TextStyle(
                        color: Color(0xFF222B25),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
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
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: _green,
              backgroundColor: const Color(0xFFDCEBE1),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentReportCard extends StatelessWidget {
  const _StudentReportCard({
    super.key,
    required this.student,
    required this.rank,
    required this.showSection,
  });

  final Map<String, dynamic> student;
  final int rank;
  final bool showSection;

  static const Color _green = Color(0xFF4CAF50);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _border = Color(0xFFDDE9E1);
  static const Color _muted = Color(0xFF657168);

  @override
  Widget build(BuildContext context) {
    final percentage = (student['percentage'] as num?)?.toDouble() ?? 0;
    final obtained = (student['obtainedMarks'] as num?)?.toDouble() ?? 0;
    final total = (student['totalMarks'] as num?)?.toDouble() ?? 0;
    final progress = (percentage / 100).clamp(0.0, 1.0).toDouble();
    final sectionName = (student['sectionName'] as String? ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163B28).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rank == 1
                      ? const Color(0xFFDDF2E4)
                      : const Color(0xFFF0F5F1),
                  border: rank == 1
                      ? Border.all(color: const Color(0xFFB7DFC5))
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank == 1 ? _darkGreen : _muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['studentName'] as String? ?? 'Student',
                      style: const TextStyle(
                        color: Color(0xFF222B25),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatMarks(obtained)} / ${_formatMarks(total)} marks',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    if (showSection) ...[
                      const SizedBox(height: 3),
                      Text(
                        sectionName.isNotEmpty
                            ? 'Section: $sectionName'
                            : 'Section: Not assigned',
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: _green,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: _green,
              backgroundColor: const Color(0xFFDCEBE1),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport({
    required this.title,
    required this.message,
    this.icon = Icons.menu_book_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDDE9E1)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F3E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF105C3B), size: 27),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF202B25),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF68766E),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF912018),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE9E1)),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF138A4B)),
          SizedBox(height: 14),
          Text(
            'Generating report...',
            style: TextStyle(
              color: Color(0xFF105C3B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMarks(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

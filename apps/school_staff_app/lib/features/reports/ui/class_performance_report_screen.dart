
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
  late final SchoolReportsController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ref.read(
      schoolReportsControllerProvider(widget.schoolId),
    );

    _controller.addListener(_onControllerChanged);

    Future.microtask(() {
      if (!mounted) return;
      _controller.loadClasses();
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SchoolReportsState state = _controller.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sectionMode
              ? 'Section Reports'
              : 'Class Overall Report',
        ),
      ),
      body: state.isLoadingClasses
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(context, state, _controller),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SchoolReportsState state,
    SchoolReportsController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: state.selectedClassId,
          decoration: const InputDecoration(
            labelText: 'Select Class',
            border: OutlineInputBorder(),
          ),
          items: state.classes.map((schoolClass) {
            return DropdownMenuItem<String>(
              value: schoolClass.id,
              child: Text(schoolClass.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.selectClass(value);
            }
          },
        ),

        if (widget.sectionMode) ...[
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: state.selectedSectionId,
            decoration: const InputDecoration(
              labelText: 'Select Section',
              border: OutlineInputBorder(),
            ),
            items: state.sections.map((section) {
              final sectionId = section['id'] as String? ?? '';

              final sectionName =
                  section['name'] as String? ??
                  section['sectionName'] as String? ??
                  'Unnamed Section';

              if (sectionId.isEmpty) {
                return null;
              }

              return DropdownMenuItem<String>(
                value: sectionId,
                child: Text(sectionName),
              );
            }).whereType<DropdownMenuItem<String>>().toList(),
            onChanged: state.isLoadingSections
                ? null
                : (value) {
                    if (value != null) {
                      controller.selectSection(value);
                    }
                  },
          ),

          if (state.isLoadingSections)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],

        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: state.isLoadingReport
              ? null
              : () {
                  if (widget.sectionMode) {
                    controller.loadSectionReport();
                  } else {
                    controller.loadClassReport();
                  }
                },
          icon: const Icon(Icons.assessment_outlined),
          label: const Text('Generate Report'),
        ),

        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],

        if (state.isLoadingReport)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        if (!state.isLoadingReport && state.hasReport) ...[
          const SizedBox(height: 24),

          _SummaryCard(
            title: 'Students in selected scope',
            value: '${state.studentCount}',
            subtitle: 'Active students',
          ),

          const SizedBox(height: 12),

          _SummaryCard(
            title: 'Combined Overall Percentage',
            value:
                '${state.overallPercentage.toStringAsFixed(2)}%',
            subtitle: 'Based on published marks',
          ),

          const SizedBox(height: 24),

          Text(
            'Subject-wise Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          if (state.subjectReports.isEmpty)
            const _EmptyReport()
          else
            ...state.subjectReports.map(
              (subject) => _SubjectReportCard(
                subject: subject,
              ),
            ),

          const SizedBox(height: 24),

          Text(
            'Student Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          if (state.studentReports.isEmpty)
            const _EmptyReport()
          else
            ...state.studentReports.map(
              (student) => _StudentReportCard(
                student: student,
              ),
            ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectReportCard extends StatelessWidget {
  const _SubjectReportCard({
    required this.subject,
  });

  final Map<String, dynamic> subject;

  @override
  Widget build(BuildContext context) {
    final percentage =
        (subject['percentage'] as num?)?.toDouble() ?? 0;

    final obtained =
        (subject['obtainedMarks'] as num?)?.toDouble() ?? 0;

    final total =
        (subject['totalMarks'] as num?)?.toDouble() ?? 0;

    final studentCount =
        (subject['studentCount'] as num?)?.toInt() ?? 0;

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.menu_book_outlined),
        ),
        title: Text(
          subject['subjectName'] as String? ?? 'Subject',
        ),
        subtitle: Text(
          '${obtained.toStringAsFixed(1)} / '
          '${total.toStringAsFixed(1)} marks'
          ' • $studentCount students with marks',
        ),
        trailing: Text(
          '${percentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class _StudentReportCard extends StatelessWidget {
  const _StudentReportCard({
    required this.student,
  });

  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    final percentage =
        (student['percentage'] as num?)?.toDouble() ?? 0;

    final obtained =
        (student['obtainedMarks'] as num?)?.toDouble() ?? 0;

    final total =
        (student['totalMarks'] as num?)?.toDouble() ?? 0;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(
          student['studentName'] as String? ?? 'Student',
        ),
        subtitle: Text(
          '${obtained.toStringAsFixed(1)} / '
          '${total.toStringAsFixed(1)} marks',
        ),
        trailing: Text(
          '${percentage.toStringAsFixed(1)}%',
        ),
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Abhi is selection ke liye published marks available nahi hain.',
        ),
      ),
    );
  }
}

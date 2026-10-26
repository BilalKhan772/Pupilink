import 'package:school_models/school_models.dart';

class SchoolReportsState {
  const SchoolReportsState({
    this.classes = const [],
    this.sections = const [],
    this.selectedClassId,
    this.selectedSectionId,
    this.report = const {},
    this.isLoadingClasses = false,
    this.isLoadingSections = false,
    this.isLoadingReport = false,
    this.errorMessage,
  });

  final List<SchoolClass> classes;
  final List<Map<String, dynamic>> sections;

  final String? selectedClassId;
  final String? selectedSectionId;

  final Map<String, dynamic> report;

  final bool isLoadingClasses;
  final bool isLoadingSections;
  final bool isLoadingReport;

  final String? errorMessage;

  bool get hasReport => report.isNotEmpty;

  List<Map<String, dynamic>> get subjectReports =>
      (report['subjects'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  List<Map<String, dynamic>> get studentReports =>
      (report['students'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

  double get overallPercentage =>
      (report['overallPercentage'] as num?)?.toDouble() ?? 0;

  int get studentCount => (report['studentCount'] as num?)?.toInt() ?? 0;

  SchoolReportsState copyWith({
    List<SchoolClass>? classes,
    List<Map<String, dynamic>>? sections,
    String? selectedClassId,
    bool clearSelectedClassId = false,
    String? selectedSectionId,
    bool clearSelectedSectionId = false,
    Map<String, dynamic>? report,
    bool clearReport = false,
    bool? isLoadingClasses,
    bool? isLoadingSections,
    bool? isLoadingReport,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SchoolReportsState(
      classes: classes ?? this.classes,
      sections: sections ?? this.sections,
      selectedClassId: clearSelectedClassId
          ? null
          : selectedClassId ?? this.selectedClassId,
      selectedSectionId: clearSelectedSectionId
          ? null
          : selectedSectionId ?? this.selectedSectionId,
      report: clearReport ? const {} : report ?? this.report,
      isLoadingClasses: isLoadingClasses ?? this.isLoadingClasses,
      isLoadingSections: isLoadingSections ?? this.isLoadingSections,
      isLoadingReport: isLoadingReport ?? this.isLoadingReport,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
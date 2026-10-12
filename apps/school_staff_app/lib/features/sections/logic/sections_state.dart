
import 'package:school_models/school_models.dart';

class SectionsState {
  const SectionsState({
    this.isLoading = false,
    this.isSaving = false,
    this.sections = const [],
    this.classes = const [],
    this.academicYears = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final List<SchoolSection> sections;
  final List<SchoolClass> classes;
  final List<AcademicYear> academicYears;
  final String searchQuery;
  final String? errorMessage;

  List<SchoolSection> get filteredSections {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return sections;

    return sections.where((section) {
      final sectionName = section.name.toLowerCase();

      final schoolClass = classes.where(
        (item) => item.id == section.classId,
      );

      final className = schoolClass.isEmpty
          ? ''
          : schoolClass.first.name.toLowerCase();

      return sectionName.contains(query) ||
          className.contains(query);
    }).toList();
  }

  int get activeCount =>
      sections.where((section) => section.isActive).length;

  int get inactiveCount =>
      sections.where((section) => !section.isActive).length;

  SectionsState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<SchoolSection>? sections,
    List<SchoolClass>? classes,
    List<AcademicYear>? academicYears,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SectionsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      sections: sections ?? this.sections,
      classes: classes ?? this.classes,
      academicYears: academicYears ?? this.academicYears,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

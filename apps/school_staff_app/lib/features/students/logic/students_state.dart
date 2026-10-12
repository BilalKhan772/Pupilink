
import 'package:school_models/school_models.dart';

class StudentsState {
  const StudentsState({
    this.isLoading = false,
    this.isSaving = false,
    this.students = const [],
    this.classes = const [],
    this.sections = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final List<Student> students;
  final List<SchoolClass> classes;
  final List<SchoolSection> sections;
  final String searchQuery;
  final String? errorMessage;

  List<Student> get filteredStudents {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return students;

    return students.where((student) {
      return student.name.toLowerCase().contains(query) ||
          student.admissionNumber.toLowerCase().contains(query) ||
          student.className.toLowerCase().contains(query) ||
          student.section.toLowerCase().contains(query);
    }).toList();
  }

  int get activeCount => students.where((s) => s.isActive).length;

  int get inactiveCount => students.where((s) => !s.isActive).length;

  StudentsState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<Student>? students,
    List<SchoolClass>? classes,
    List<SchoolSection>? sections,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StudentsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      students: students ?? this.students,
      classes: classes ?? this.classes,
      sections: sections ?? this.sections,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

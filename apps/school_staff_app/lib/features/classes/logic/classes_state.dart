
import 'package:school_models/school_models.dart';

class ClassesState {
  const ClassesState({
    this.isLoading = false,
    this.isSaving = false,
    this.classes = const [],
    this.academicYears = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final List<SchoolClass> classes;
  final List<AcademicYear> academicYears;
  final String searchQuery;
  final String? errorMessage;

  List<SchoolClass> get filteredClasses {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return classes;

    return classes.where((schoolClass) {
      return schoolClass.name.toLowerCase().contains(query);
    }).toList();
  }

  int get activeCount => classes.where((item) => item.isActive).length;

  int get inactiveCount => classes.where((item) => !item.isActive).length;

  ClassesState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<SchoolClass>? classes,
    List<AcademicYear>? academicYears,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ClassesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      classes: classes ?? this.classes,
      academicYears: academicYears ?? this.academicYears,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

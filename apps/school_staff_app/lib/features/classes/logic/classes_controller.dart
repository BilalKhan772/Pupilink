import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../data/classes_repository.dart';
import 'classes_state.dart';

final classesControllerProvider =
    NotifierProvider<ClassesController, ClassesState>(
  ClassesController.new,
);

class ClassesController extends Notifier<ClassesState> {
  @override
  ClassesState build() => const ClassesState();

  // Classes aur academic years load karein.
  Future<void> load(String schoolId) async {
    final id = schoolId.trim();

    if (id.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'School ID available nahi hai.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final repository = ref.read(classesRepositoryProvider);

      final results = await Future.wait([
        repository.getClasses(id),
        repository.getAcademicYears(id),
      ]);

      state = state.copyWith(
        isLoading: false,
        classes: results[0] as List<SchoolClass>,
        academicYears: results[1] as List<AcademicYear>,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  // Purane code ke liye compatibility.
  Future<void> loadClasses() async {
    final schoolId =
        ref.read(staffAuthControllerProvider).schoolId;

    await load(schoolId);
  }

  // Search.
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Nayi class create karein.
  Future<bool> addClass({
    required String schoolId,
    required String name,
    String? academicYearId,
    int? sortOrder,
  }) async {
    final id = schoolId.trim();

    if (id.isEmpty) {
      state = state.copyWith(
        errorMessage: 'School ID available nahi hai.',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
    );

    try {
      await ref.read(classesRepositoryProvider).addClass(
            schoolId: id,
            name: name,
            academicYearId: academicYearId,
            sortOrder: sortOrder,
          );

      await load(id);

      return state.errorMessage == null;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _friendlyError(error),
      );
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  // Existing updateClass method — existing callers ke liye.
  Future<bool> updateClass({
    required String classId,
    required String schoolId,
    required String name,
    String? academicYearId,
    int? sortOrder,
    required bool isActive,
  }) async {
    final id = schoolId.trim();

    if (id.isEmpty) {
      state = state.copyWith(
        errorMessage: 'School ID available nahi hai.',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
    );

    try {
      await ref.read(classesRepositoryProvider).updateClass(
            classId: classId,
            schoolId: id,
            name: name,
            academicYearId: academicYearId,
            sortOrder: sortOrder,
            isActive: isActive,
          );

      await load(id);

      return state.errorMessage == null;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _friendlyError(error),
      );
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  // EditClassScreen ke liye helper method.
  Future<bool> updateExistingClass({
    required SchoolClass schoolClass,
    required String name,
    String? academicYearId,
    int? sortOrder,
  }) async {
    final authSchoolId =
        ref.read(staffAuthControllerProvider).schoolId.trim();

    if (authSchoolId.isEmpty ||
        schoolClass.schoolId != authSchoolId) {
      state = state.copyWith(
        errorMessage: 'Class ka school ID match nahi karta.',
      );
      return false;
    }

    return updateClass(
      classId: schoolClass.id,
      schoolId: authSchoolId,
      name: name,
      academicYearId: academicYearId,
      sortOrder: sortOrder,
      isActive: schoolClass.isActive,
    );
  }

  // Class ko activate/deactivate karein.
  Future<bool> setActive(
    SchoolClass schoolClass,
    bool isActive,
  ) async {
    final authSchoolId =
        ref.read(staffAuthControllerProvider).schoolId.trim();

    if (authSchoolId.isEmpty ||
        schoolClass.schoolId != authSchoolId) {
      state = state.copyWith(
        errorMessage: 'Class ka school ID match nahi karta.',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
    );

    try {
      await ref.read(classesRepositoryProvider).setClassActive(
            classId: schoolClass.id,
            isActive: isActive,
            schoolId: authSchoolId,
          );

      await load(authSchoolId);

      return state.errorMessage == null;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _friendlyError(error),
      );
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  // Purane callers ke liye compatibility.
  Future<bool> setClassActive({
    required String classId,
    required bool isActive,
  }) async {
    final matches = state.classes.where(
      (item) => item.id == classId,
    );

    if (matches.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Class nahi mili.',
      );
      return false;
    }

    return setActive(matches.first, isActive);
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'Classes ka access nahi mila. Firestore Rules check karein.';
    }

    if (message.contains('unavailable')) {
      return 'Firebase connection check karein.';
    }

    return message.replaceFirst('Exception: ', '');
  }
}
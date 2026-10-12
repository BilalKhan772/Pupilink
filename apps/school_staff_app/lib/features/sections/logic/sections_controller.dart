
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../data/sections_repository.dart';
import 'sections_state.dart';

final sectionsControllerProvider =
    NotifierProvider<SectionsController, SectionsState>(
  SectionsController.new,
);

class SectionsController extends Notifier<SectionsState> {
  @override
  SectionsState build() => const SectionsState();

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
      final repository = ref.read(sectionsRepositoryProvider);

      final results = await Future.wait([
        repository.getSections(id),
        repository.getClasses(id),
        repository.getAcademicYears(id),
      ]);

      state = state.copyWith(
        isLoading: false,
        sections: results[0] as List<SchoolSection>,
        classes: results[1] as List<SchoolClass>,
        academicYears: results[2] as List<AcademicYear>,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> loadSections() async {
    final schoolId =
        ref.read(staffAuthControllerProvider).schoolId.trim();

    await load(schoolId);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> addSection({
    required String schoolId,
    required String classId,
    required String name,
    String? academicYearId,
    String? classTeacherId,
    int? capacity,
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
      await ref.read(sectionsRepositoryProvider).addSection(
            schoolId: id,
            classId: classId,
            name: name,
            academicYearId: academicYearId,
            classTeacherId: classTeacherId,
            capacity: capacity,
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

  Future<bool> updateSection({
    required String sectionId,
    required String schoolId,
    required String classId,
    required String name,
    String? academicYearId,
    String? classTeacherId,
    int? capacity,
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
      await ref.read(sectionsRepositoryProvider).updateSection(
            sectionId: sectionId,
            schoolId: id,
            classId: classId,
            name: name,
            academicYearId: academicYearId,
            classTeacherId: classTeacherId,
            capacity: capacity,
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

  Future<bool> setActive(
    SchoolSection section,
    bool isActive,
  ) async {
    final schoolId =
        ref.read(staffAuthControllerProvider).schoolId.trim();

    if (schoolId.isEmpty || section.schoolId != schoolId) {
      state = state.copyWith(
        errorMessage: 'Section ka school ID match nahi karta.',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
    );

    try {
      await ref.read(sectionsRepositoryProvider).setSectionActive(
            sectionId: section.id,
            isActive: isActive,
            schoolId: schoolId,
          );

      await load(schoolId);

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

  Future<bool> setSectionActive({
    required String sectionId,
    required bool isActive,
  }) async {
    final matches = state.sections.where(
      (section) => section.id == sectionId,
    );

    if (matches.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Section nahi mila.',
      );
      return false;
    }

    return setActive(matches.first, isActive);
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'Sections ka access nahi mila. Firestore Rules check karein.';
    }

    if (message.contains('unavailable')) {
      return 'Firebase connection check karein.';
    }

    return message.replaceFirst('Exception: ', '');
  }
}

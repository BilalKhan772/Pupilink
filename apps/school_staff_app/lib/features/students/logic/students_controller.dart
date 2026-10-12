
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../../classes/data/classes_repository.dart';
import '../../sections/data/sections_repository.dart';
import '../data/students_repository.dart';
import 'students_state.dart';

final studentsControllerProvider =
    NotifierProvider<StudentsController, StudentsState>(
  StudentsController.new,
);

class StudentsController extends Notifier<StudentsState> {
  @override
  StudentsState build() => const StudentsState();

  Future<void> load(String schoolId) async {
    final id = schoolId.trim();

    if (id.isEmpty) {
      state = state.copyWith(
        errorMessage: 'School ID available nahi hai.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final studentsRepository = ref.read(studentsRepositoryProvider);
      final classesRepository = ref.read(classesRepositoryProvider);
      final sectionsRepository = ref.read(sectionsRepositoryProvider);

      final results = await Future.wait([
        studentsRepository.getStudents(id),
        classesRepository.getClasses(id),
        sectionsRepository.getSections(id),
      ]);

      state = state.copyWith(
        isLoading: false,
        students: results[0] as List<Student>,
        classes: results[1] as List<SchoolClass>,
        sections: results[2] as List<SchoolSection>,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> loadStudents() async {
    await load(ref.read(staffAuthControllerProvider).schoolId);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> addStudent({
    required String name,
    required String admissionNumber,
    required String city,
    required String schoolName,
    required String classId,
    required String sectionId,
  }) async {
    final schoolId =
        ref.read(staffAuthControllerProvider).schoolId.trim();

    final selectedClass = state.classes.where((c) => c.id == classId);
    final selectedSection = state.sections.where((s) => s.id == sectionId);

    if (schoolId.isEmpty ||
        selectedClass.isEmpty ||
        selectedSection.isEmpty) {
      state = state.copyWith(
        errorMessage: 'School, class ya section ki information valid nahi.',
      );
      return false;
    }

    if (selectedSection.first.classId != classId ||
        selectedSection.first.schoolId != schoolId) {
      state = state.copyWith(
        errorMessage: 'Selected section, class ke saath match nahi karta.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await ref.read(studentsRepositoryProvider).addStudent(
            schoolId: schoolId,
            name: name,
            admissionNumber: admissionNumber,
            city: city,
            schoolName: schoolName,
            classId: classId,
            className: selectedClass.first.name,
            sectionId: sectionId,
            sectionName: selectedSection.first.name,
          );

      await load(schoolId);
      return state.errorMessage == null;
    } catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<bool> updateStudent({
    required Student student,
    required String name,
    required String admissionNumber,
    required String city,
    required String schoolName,
    required String classId,
    required String sectionId,
  }) async {
    final schoolId =
        ref.read(staffAuthControllerProvider).schoolId.trim();

    final selectedClass = state.classes.where((c) => c.id == classId);
    final selectedSection = state.sections.where((s) => s.id == sectionId);

    if (schoolId.isEmpty ||
        student.schoolId != schoolId ||
        selectedClass.isEmpty ||
        selectedSection.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Student, class ya section ki information valid nahi.',
      );
      return false;
    }

    if (selectedSection.first.classId != classId ||
        selectedSection.first.schoolId != schoolId) {
      state = state.copyWith(
        errorMessage: 'Selected section, class ke saath match nahi karta.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await ref.read(studentsRepositoryProvider).updateStudent(
            studentId: student.id,
            schoolId: schoolId,
            name: name,
            admissionNumber: admissionNumber,
            city: city,
            schoolName: schoolName,
            classId: classId,
            className: selectedClass.first.name,
            sectionId: sectionId,
            sectionName: selectedSection.first.name,
            isActive: student.isActive,
          );

      await load(schoolId);
      return state.errorMessage == null;
    } catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<bool> setActive(Student student, bool isActive) async {
    final schoolId =
        ref.read(staffAuthControllerProvider).schoolId.trim();

    if (schoolId.isEmpty || student.schoolId != schoolId) {
      state = state.copyWith(
        errorMessage: 'Student ka school ID match nahi karta.',
      );
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      await ref.read(studentsRepositoryProvider).setStudentActive(
            studentId: student.id,
            schoolId: schoolId,
            isActive: isActive,
          );

      await load(schoolId);
      return state.errorMessage == null;
    } catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
      return false;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'Students ka access nahi mila. Firestore Rules check karein.';
    }

    if (message.contains('unavailable')) {
      return 'Firebase connection check karein.';
    }

    return message.replaceFirst('Exception: ', '');
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/homework_repository.dart';
import 'homework_state.dart';

final homeworkControllerProvider =
    NotifierProvider<HomeworkController, HomeworkState>(
  HomeworkController.new,
);

class HomeworkController extends Notifier<HomeworkState> {
  @override
  HomeworkState build() => const HomeworkState();

  Future<void> loadAssignment() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(homeworkRepositoryProvider);
      final assignment = await repository.getMonitorAssignment();

      final schoolId = assignment['schoolId'] as String? ?? '';
      final sectionId = assignment['sectionId'] as String? ?? '';

      final recentHomework = await repository.getRecentHomework(
        schoolId: schoolId,
        sectionId: sectionId,
      );

      state = state.copyWith(
        isLoading: false,
        schoolId: schoolId,
        classId: assignment['classId'] as String? ?? '',
        className: assignment['className'] as String? ?? '',
        sectionId: sectionId,
        sectionName: assignment['sectionName'] as String? ?? '',
        monitorName: assignment['monitorName'] as String? ?? '',
        recentHomework: recentHomework,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<bool> publishHomework({
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    if (title.trim().isEmpty || description.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Title aur description fill karein.',
        clearSuccess: true,
      );
      return false;
    }

    if (description.trim().length > 5000) {
      state = state.copyWith(
        errorMessage: 'Description 5000 characters se chhoti rakhein.',
        clearSuccess: true,
      );
      return false;
    }

    if (dueDate.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      state = state.copyWith(
        errorMessage: 'Due date aaj ya future ki select karein.',
        clearSuccess: true,
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(homeworkRepositoryProvider);

      final count = await repository.publishHomework(
        title: title,
        description: description,
        dueDate: dueDate,
      );

      final recentHomework = await repository.getRecentHomework(
        schoolId: state.schoolId,
        sectionId: state.sectionId,
      );

      state = state.copyWith(
        isSaving: false,
        recentHomework: recentHomework,
        successMessage: 'Homework $count students ke liye publish ho gaya.',
        clearError: true,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _message(error),
        clearSuccess: true,
      );
      return false;
    }
  }

  String _message(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '');
  }
}

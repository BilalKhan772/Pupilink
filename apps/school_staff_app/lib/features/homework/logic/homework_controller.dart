
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
      final assignment =
          await ref.read(homeworkRepositoryProvider).getMonitorAssignment();

      state = state.copyWith(
        isLoading: false,
        schoolId: assignment['schoolId'] as String? ?? '',
        classId: assignment['classId'] as String? ?? '',
        sectionId: assignment['sectionId'] as String? ?? '',
        sectionName: assignment['sectionName'] as String? ?? '',
        monitorName: assignment['monitorName'] as String? ?? '',
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
    required String subject,
    required String description,
    required DateTime dueDate,
  }) async {
    if (title.trim().isEmpty ||
        subject.trim().isEmpty ||
        description.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Title, subject aur description fill karein.',
        clearSuccess: true,
      );
      return false;
    }

    if (title.trim().length > 150) {
      state = state.copyWith(
        errorMessage: 'Title 150 characters se chhota rakhein.',
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

    // Aaj ki date allowed hai; sirf guzri hui date reject hogi.
    final selectedDate = DateUtils.dateOnly(dueDate);
    final today = DateUtils.dateOnly(DateTime.now());

    if (selectedDate.isBefore(today)) {
      state = state.copyWith(
        errorMessage: 'Due date aaj ya future mein select karein.',
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
      final count = await ref.read(homeworkRepositoryProvider).publishHomework(
            title: title,
            subject: subject,
            description: description,
            dueDate: dueDate,
          );

      state = state.copyWith(
        isSaving: false,
        successMessage:
            'Homework $count students ke liye publish ho gaya.',
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

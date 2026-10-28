import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../data/staff_dashboard_repository.dart';

final staffDashboardControllerProvider =
    NotifierProvider<StaffDashboardController, StaffDashboardState>(
  StaffDashboardController.new,
);

class StaffDashboardState {
  const StaffDashboardState({
    this.isLoading = false,
    this.assignments = const [],
    this.errorMessage,
  });

  final bool isLoading;
  final List<TeacherAssignment> assignments;
  final String? errorMessage;

  StaffDashboardState copyWith({
    bool? isLoading,
    List<TeacherAssignment>? assignments,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StaffDashboardState(
      isLoading: isLoading ?? this.isLoading,
      assignments: assignments ?? this.assignments,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class StaffDashboardController extends Notifier<StaffDashboardState> {
  @override
  StaffDashboardState build() {
    // Initial state. Assignments are loaded explicitly using
    // loadAssignments() from the dashboard screen.
    return const StaffDashboardState();
  }

  Future<void> loadAssignments() async {
    final authState = ref.read(staffAuthControllerProvider);
    final schoolId = authState.schoolId.trim();
    final teacherId = authState.uid.trim();

    if (!authState.isLoggedIn ||
        schoolId.isEmpty ||
        teacherId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Teacher ki login information nahi mili.',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final repository = ref.read(staffDashboardRepositoryProvider);

      final assignments = await repository.getTeacherAssignments(
        schoolId: schoolId,
        teacherId: teacherId,
      );

      state = state.copyWith(
        isLoading: false,
        assignments: assignments,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Assignments load nahi ho sakin: $error',
      );
    }
  }

  Future<void> refresh() => loadAssignments();
}
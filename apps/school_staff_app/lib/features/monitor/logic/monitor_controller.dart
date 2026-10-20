
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/monitor_repository.dart';
import 'monitor_state.dart';

final monitorControllerProvider =
    NotifierProvider<MonitorController, MonitorState>(
  MonitorController.new,
);

class MonitorController extends Notifier<MonitorState> {
  @override
  MonitorState build() {
    return const MonitorState();
  }

  Future<void> loadData({
    required String schoolId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final repository = ref.read(monitorRepositoryProvider);

      final results = await Future.wait([
        repository.getSections(schoolId: schoolId),
        repository.getMonitors(schoolId: schoolId),
      ]);

      state = state.copyWith(
        isLoading: false,
        sections: results[0],
        monitors: results[1],
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyMessage(error),
      );
    }
  }

  Future<bool> createMonitor({
    required String schoolId,
    required String name,
    required String email,
    required String password,
    required String sectionId,
  }) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.length < 8 ||
        sectionId.trim().isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Name, email, kam az kam 8-character password aur section dein.',
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
      final repository = ref.read(monitorRepositoryProvider);

      await repository.createMonitor(
        name: name.trim(),
        email: email.trim(),
        password: password,
        sectionId: sectionId,
      );

      final monitors = await repository.getMonitors(
        schoolId: schoolId,
      );

      state = state.copyWith(
        isSaving: false,
        monitors: monitors,
        successMessage: 'Monitor account successfully create ho gaya.',
        clearError: true,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: _friendlyMessage(error),
        clearSuccess: true,
      );

      return false;
    }
  }

  String _friendlyMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '');
  }
}

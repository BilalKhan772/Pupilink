import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/parent_dashboard_repository.dart';
import 'parent_dashboard_state.dart';

final parentDashboardRepositoryProvider =
    Provider<ParentDashboardRepository>((ref) {
  return ParentDashboardRepository(
    auth: FirebaseAuth.instance,
  );
});

final parentDashboardControllerProvider =
    StateNotifierProvider<
        ParentDashboardController,
        ParentDashboardState>(
  (ref) {
    return ParentDashboardController(
      ref.read(parentDashboardRepositoryProvider),
    );
  },
);

class ParentDashboardController
    extends StateNotifier<ParentDashboardState> {
  final ParentDashboardRepository repository;

  ParentDashboardController(this.repository)
      : super(const ParentDashboardState());

  Future<void> loadDashboard() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
      );

      final user = repository.currentUser;

      state = state.copyWith(
        isLoading: false,
        parentEmail: user?.email ?? '',
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Dashboard load nahi ho saka.',
      );
    }
  }
}
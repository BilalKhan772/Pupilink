import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/child_link_repository.dart';
import 'connect_child_state.dart';

final childLinkRepositoryProvider =
    Provider<ChildLinkRepository>((ref) {
  return ChildLinkRepository();
});

final connectChildControllerProvider =
    StateNotifierProvider<
        ConnectChildController,
        ConnectChildState>(
  (ref) {
    return ConnectChildController(
      ref.read(childLinkRepositoryProvider),
    );
  },
);

class ConnectChildController
    extends StateNotifier<ConnectChildState> {
  final ChildLinkRepository repository;

  ConnectChildController(this.repository)
      : super(const ConnectChildState());

  Future<bool> connectChild({
    required String city,
    required String schoolId,
    required String admissionNumber,
  }) async {
    state = state.copyWith(
      isLoading: true,
      success: false,
      clearError: true,
    );

    try {
      final result =
          await repository.linkChild(
        city: city,
        schoolId: schoolId,
        admissionNumber:
            admissionNumber,
      );

      state = state.copyWith(
        isLoading: false,
        success: true,
        linkId:
            result['linkId'] as String?,
        studentId:
            result['studentId'] as String?,
        studentName:
            result['studentName'] as String?,
        clearError: true,
      );

      return true;
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error:
            e.message ??
            'Child connect nahi ho saka.',
      );

      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        error:
            'Child connect karte waqt error aa gaya.',
      );

      return false;
    }
  }

  void reset() {
    state = const ConnectChildState();
  }
}
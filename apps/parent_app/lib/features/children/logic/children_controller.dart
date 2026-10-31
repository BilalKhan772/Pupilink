
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/children_repository.dart';
import 'children_state.dart';

final childrenRepositoryProvider =
    Provider<ChildrenRepository>((ref) {
  return ChildrenRepository();
});

final childrenControllerProvider =
    StateNotifierProvider<ChildrenController, ChildrenState>(
  (ref) {
    return ChildrenController(
      ref.read(childrenRepositoryProvider),
    );
  },
);

class ChildrenController extends StateNotifier<ChildrenState> {
  final ChildrenRepository repository;

  ChildrenController(this.repository)
      : super(const ChildrenState());

  Future<void> loadChildren() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final children = await repository.getMyChildren();

      state = state.copyWith(
        isLoading: false,
        children: children,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyError(error),
      );
    }
  }

  Future<bool> removeChild({
    required String linkId,
  }) async {
    if (linkId.trim().isEmpty) {
      state = state.copyWith(
        error: 'Child connection ID is missing.',
      );
      return false;
    }

    if (state.isRemovingChild) {
      return false;
    }

    state = state.copyWith(
      isRemovingChild: true,
      removingLinkId: linkId,
      clearError: true,
    );

    try {
      await repository.removeChildLink(linkId: linkId);

      final updatedChildren = state.children
          .where((child) => child['linkId'] != linkId)
          .toList();

      state = state.copyWith(
        isRemovingChild: false,
        clearRemovingLinkId: true,
        children: updatedChildren,
        clearError: true,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        isRemovingChild: false,
        clearRemovingLinkId: true,
        error: _friendlyError(error),
      );

      return false;
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'You do not have permission to manage this child connection.';
    }

    if (message.contains('network')) {
      return 'Please check your internet connection and try again.';
    }

    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseException: ', '');
  }
}

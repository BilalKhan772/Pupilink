import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/children_repository.dart';
import 'children_state.dart';

final childrenRepositoryProvider =
    Provider<ChildrenRepository>((ref) {
  return ChildrenRepository();
});

final childrenControllerProvider =
    StateNotifierProvider<
        ChildrenController,
        ChildrenState>(
  (ref) {
    return ChildrenController(
      ref.read(childrenRepositoryProvider),
    );
  },
);

class ChildrenController
    extends StateNotifier<ChildrenState> {
  final ChildrenRepository repository;

  ChildrenController(this.repository)
      : super(const ChildrenState());

  Future<void> loadChildren() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final children =
          await repository.getMyChildren();

      state = state.copyWith(
        isLoading: false,
        children: children,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Children load nahi ho sake.',
      );
    }
  }
}
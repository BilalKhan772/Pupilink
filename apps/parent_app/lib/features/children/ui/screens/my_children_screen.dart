
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/children_controller.dart';
import '../widgets/add_child_card.dart';
import '../widgets/child_card.dart';
import 'connect_child_screen.dart';
import 'child_profile_screen.dart';

class MyChildrenScreen extends ConsumerStatefulWidget {
  const MyChildrenScreen({super.key});

  @override
  ConsumerState<MyChildrenScreen> createState() =>
      _MyChildrenScreenState();
}

class _MyChildrenScreenState
    extends ConsumerState<MyChildrenScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      ref.read(childrenControllerProvider.notifier).loadChildren();
    });
  }

  Future<void> _openConnectChild() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ConnectChildScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await ref.read(childrenControllerProvider.notifier).loadChildren();
    }
  }

  void _openChildProfile(Map<String, dynamic> child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChildProfileScreen(child: child),
      ),
    );
  }

  Future<void> _confirmRemoveChild(
    Map<String, dynamic> child,
  ) async {
    final linkId = child['linkId'] as String? ?? '';
    final childName = child['name'] as String? ?? 'this child';

    if (linkId.trim().isEmpty) {
      _showMessage(
        'Unable to identify this child connection. Please refresh and try again.',
        isError: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Child'),
        content: Text(
          'Are you sure you want to remove $childName from your parent account?\n\n'
          'This will remove the connection only. The student’s school record '
          'will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(childrenControllerProvider.notifier)
        .removeChild(linkId: linkId);

    if (!mounted) return;

    if (success) {
      _showMessage('$childName has been removed from your account.');
    } else {
      final error = ref.read(childrenControllerProvider).error;
      _showMessage(
        error ?? 'Unable to remove this child. Please try again.',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : _darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(childrenControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      appBar: AppBar(
        title: const Text('My Children'),
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Color(0xFFE1EAE3),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _green),
            )
          : RefreshIndicator(
              color: _green,
              onRefresh: () => ref
                  .read(childrenControllerProvider.notifier)
                  .loadChildren(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      constraints.maxWidth < 600 ? 16.0 : 28.0;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 22,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Manage Your Children',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F3328),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Connect a child or open a profile to view academic information.',
                                style: TextStyle(
                                  color: Color(0xFF718078),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),

                              AddChildCard(
                                onTap: _openConnectChild,
                              ),

                              if (state.error != null) ...[
                                const SizedBox(height: 14),
                                _ErrorCard(message: state.error!),
                              ],

                              const SizedBox(height: 26),

                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Linked Children',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: _darkGreen,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2F2E7),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      '${state.children.length}',
                                      style: const TextStyle(
                                        color: _darkGreen,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              if (state.children.isEmpty)
                                const _EmptyChildrenCard()
                              else
                                ...state.children.map((child) {
                                  final linkId =
                                      child['linkId'] as String? ?? '';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ChildCard(
                                      child: child,
                                      onTap: () => _openChildProfile(child),
                                      onRemove: () =>
                                          _confirmRemoveChild(child),
                                      isRemoving:
                                          state.removingLinkId == linkId,
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyChildrenCard extends StatelessWidget {
  const _EmptyChildrenCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 36,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0EAE3)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.family_restroom_rounded,
            size: 48,
            color: Color(0xFF138A4B),
          ),
          SizedBox(height: 14),
          Text(
            'No Children Linked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF105C3B),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Your approved child connections will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF718078),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C6C2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF912018)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/children_controller.dart';
import '../widgets/add_child_card.dart';
import '../widgets/child_card.dart';
import 'connect_child_screen.dart';
import 'child_profile_screen.dart';

class MyChildrenScreen
    extends ConsumerStatefulWidget {
  const MyChildrenScreen({super.key});

  @override
  ConsumerState<MyChildrenScreen> createState() =>
      _MyChildrenScreenState();
}

class _MyChildrenScreenState
    extends ConsumerState<MyChildrenScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(
            childrenControllerProvider.notifier,
          )
          .loadChildren();
    });
  }

  Future<void> _openConnectChild() async {
    final result =
        await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ConnectChildScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await ref
          .read(
            childrenControllerProvider
                .notifier,
          )
          .loadChildren();
    }
  }

  void _openChildProfile(
    Map<String, dynamic> child,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChildProfileScreen(
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      childrenControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Children',
        ),
      ),
      body: state.isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(
                      childrenControllerProvider
                          .notifier,
                    )
                    .loadChildren();
              },
              child: ListView(
                padding:
                    const EdgeInsets.all(20),
                children: [
                  if (state.error != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 15,
                      ),
                      child: Text(
                        state.error!,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),

                  if (state.children.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.only(
                        top: 50,
                        bottom: 30,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons
                                .family_restroom,
                            size: 70,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'No Child Linked',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Abhi aapke account ke saath '
                            'koi approved child linked nahi hai.',
                            textAlign:
                                TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.children.map(
                      (child) {
                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          child: ChildCard(
                            child: child,
                            onTap: () {
                              _openChildProfile(
                                child,
                              );
                            },
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 10),

                  AddChildCard(
                    onTap:
                        _openConnectChild,
                  ),
                ],
              ),
            ),
    );
  }
}
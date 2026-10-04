import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/parent_auth_controller.dart';
import '../../children/ui/screens/my_children_screen.dart';
import '../../notifications/ui/parent_notifications_screen.dart';
import '../logic/parent_dashboard_controller.dart';
import '../../../routing/parent_router.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState
    extends ConsumerState<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(parentDashboardControllerProvider.notifier)
          .loadDashboard();
    });
  }

  Future<void> _logout() async {
    await ref
        .read(parentAuthControllerProvider.notifier)
        .logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      ParentRouter.login,
      (route) => false,
    );
  }

  void _openMyChildren() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyChildrenScreen(),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ParentNotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState =
        ref.watch(parentDashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          // --------------------------------
          // Notifications
          // --------------------------------
          IconButton(
            tooltip: 'Notifications',
            onPressed: _openNotifications,
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),

          // --------------------------------
          // Logout
          // --------------------------------
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: dashboardState.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () {
                return ref
                    .read(
                      parentDashboardControllerProvider
                          .notifier,
                    )
                    .loadDashboard();
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildWelcomeCard(
                    context,
                    dashboardState.parentEmail ?? '',
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'My Child',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildFeatureCard(
                    icon: Icons.child_care,
                    title: 'My Children',
                    subtitle:
                        'Apne children ki academic information dekhein.',
                  ),

                  const SizedBox(height: 12),

                  _buildFeatureCard(
                    icon: Icons.menu_book,
                    title: 'Homework',
                    subtitle:
                        'Homework aur assignments check karein.',
                  ),

                  const SizedBox(height: 12),

                  _buildFeatureCard(
                    icon: Icons.fact_check,
                    title: 'Attendance',
                    subtitle:
                        'Child ki attendance check karein.',
                  ),

                  const SizedBox(height: 12),

                  _buildFeatureCard(
                    icon: Icons.assessment,
                    title: 'Results',
                    subtitle:
                        'Academic results aur progress dekhein.',
                  ),

                  const SizedBox(height: 20),

                  if (dashboardState.error != null)
                    Text(
                      dashboardState.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    String email,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(
                Icons.person,
                size: 30,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Parent!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    email.isEmpty
                        ? 'School Progress System'
                        : email,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),

        leading: CircleAvatar(
          child: Icon(icon),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
        ),

        onTap: () {
          if (title == 'My Children') {
            _openMyChildren();
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$title feature abhi development mein hai.',
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../../classes/ui/screens/classes_screen.dart';
import '../../notifications/ui/create_announcement_screen.dart';
import '../../reports/ui/reports_dashboard_screen.dart';
import '../../sections/ui/screens/sections_screen.dart';
import '../../students/ui/screens/all_students_screen.dart';

class SchoolAdminDashboardScreen extends ConsumerWidget {
  const SchoolAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(staffAuthControllerProvider);

    final modules = <_DashboardModule>[
      _DashboardModule(
        title: 'Classes',
        subtitle: 'Manage school classes',
        icon: Icons.class_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ClassesScreen(),
            ),
          );
        },
      ),
      _DashboardModule(
        title: 'Sections',
        subtitle: 'Manage class sections',
        icon: Icons.grid_view_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SectionsScreen(),
            ),
          );
        },
      ),
      _DashboardModule(
        title: 'Teachers',
        subtitle: 'Staff and assignments',
        icon: Icons.people_outline_rounded,
      ),
      _DashboardModule(
        title: 'Students',
        subtitle: 'Student records',
        icon: Icons.school_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AllStudentsScreen(),
            ),
          );
        },
      ),
      _DashboardModule(
        title: 'Attendance',
        subtitle: 'Attendance overview',
        icon: Icons.fact_check_outlined,
      ),
      _DashboardModule(
        title: 'Homework',
        subtitle: 'Homework management',
        icon: Icons.menu_book_outlined,
      ),
      _DashboardModule(
        title: 'Timetable',
        subtitle: 'Class schedules',
        icon: Icons.calendar_month_outlined,
      ),
      _DashboardModule(
        title: 'Reports',
        subtitle: 'School progress reports',
        icon: Icons.bar_chart_rounded,
        onTap: () {
          if (auth.schoolId.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'School ID available nahi hai. Dobara login karein.',
                ),
              ),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReportsDashboardScreen(
                schoolId: auth.schoolId,
              ),
            ),
          );
        },
      ),
      _DashboardModule(
        title: 'Notifications',
        subtitle: 'Send school announcements',
        icon: Icons.notifications_active_outlined,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CreateAnnouncementScreen(),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Admin Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: auth.isLoading
                ? null
                : () async {
                    await ref
                        .read(staffAuthControllerProvider.notifier)
                        .signOut();

                    if (!context.mounted) return;

                    if (ref
                        .read(staffAuthControllerProvider)
                        .isLoggedIn) {
                      final error = ref
                          .read(staffAuthControllerProvider)
                          .errorMessage;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            error ??
                                'Logout nahi ho saka. Dobara try karein.',
                          ),
                        ),
                      );
                    }
                  },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, '
                    '${auth.name.isEmpty ? 'School Admin' : auth.name}',
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'School ID: '
                    '${auth.schoolId.isEmpty ? 'Not available' : auth.schoolId}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'School Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 850
                          ? 4
                          : width >= 560
                              ? 2
                              : 1;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: modules.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 150,
                        ),
                        itemBuilder: (context, index) {
                          final module = modules[index];

                          return Card(
                            elevation: 0,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: module.onTap ??
                                  () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${module.title} module abhi connect nahi hua.',
                                        ),
                                      ),
                                    );
                                  },
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      module.icon,
                                      size: 30,
                                      color: const Color(0xFF2563EB),
                                    ),
                                    const Spacer(),
                                    Text(
                                      module.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      module.subtitle,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardModule {
  const _DashboardModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
}

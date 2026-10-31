
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../../classes/ui/screens/classes_screen.dart';
import '../../notifications/ui/create_announcement_screen.dart';
import '../../reports/ui/reports_dashboard_screen.dart';
import '../../students/ui/screens/all_students_screen.dart';

class SchoolAdminDashboardScreen extends ConsumerWidget {
  const SchoolAdminDashboardScreen({super.key});

  static const Color _primaryGreen = Color(0xFF16865A);
  static const Color _darkGreen = Color(0xFF116B46);
  static const Color _lightGreen = Color(0xFFEAF5EF);
  static const Color _background = Color(0xFFF6F9F7);
  static const Color _borderColor = Color(0xFFE2EBE5);
  static const Color _textColor = Color(0xFF202B25);
  static const Color _secondaryText = Color(0xFF718078);

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _openClasses(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ClassesScreen(),
      ),
    );
  }

  void _openStudents(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AllStudentsScreen(),
      ),
    );
  }

  void _openReports(
    BuildContext context,
    String schoolId,
  ) {
    if (schoolId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'School ID is unavailable. Please log in again.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportsDashboardScreen(
          schoolId: schoolId,
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CreateAnnouncementScreen(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref
          .read(staffAuthControllerProvider.notifier)
          .signOut();

      if (!context.mounted) return;

      final updatedAuth = ref.read(
        staffAuthControllerProvider,
      );

      if (updatedAuth.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedAuth.errorMessage ??
                  'Unable to log out. Please try again.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while logging out.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard header
  // ---------------------------------------------------------------------------

  Widget _buildWelcomeSection({
    required BuildContext context,
    required String name,
    required String schoolId,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEAF5EF),
            Color(0xFFF5FAF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: _primaryGreen,
              size: 32,
            ),
          ),

          const SizedBox(width: 17),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  name.isEmpty ? 'School Admin' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: _primaryGreen,
                      size: 16,
                    ),
                    Text(
                      'School ID: ${schoolId.isEmpty ? 'Not available' : schoolId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section heading
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeading(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: 25,
          decoration: BoxDecoration(
            color: _primaryGreen,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'School Management',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _textColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Manage your school from one place.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard module card
  // ---------------------------------------------------------------------------

  Widget _buildModuleCard({
    required BuildContext context,
    required _DashboardModule module,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: module.onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: _borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      module.icon,
                      color: _primaryGreen,
                      size: 25,
                    ),
                  ),

                  const Spacer(),

                  Icon(
                    Icons.arrow_outward_rounded,
                    color: _secondaryText.withOpacity(0.65),
                    size: 19,
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    module.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _secondaryText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main dashboard
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(staffAuthControllerProvider);

    // Only the four requested modules remain on the dashboard.
    final modules = <_DashboardModule>[
      _DashboardModule(
        title: 'Classes',
        subtitle: 'Manage school classes',
        icon: Icons.class_outlined,
        onTap: () => _openClasses(context),
      ),
      _DashboardModule(
        title: 'Students',
        subtitle: 'View and manage student records',
        icon: Icons.school_outlined,
        onTap: () => _openStudents(context),
      ),
      _DashboardModule(
        title: 'Reports',
        subtitle: 'View school performance reports',
        icon: Icons.bar_chart_rounded,
        onTap: () => _openReports(
          context,
          auth.schoolId,
        ),
      ),
      _DashboardModule(
        title: 'Notifications',
        subtitle: 'Send school announcements',
        icon: Icons.notifications_active_outlined,
        onTap: () => _openNotifications(context),
      ),
    ];

    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textColor,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: const Text(
          'School Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _textColor,
          ),
        ),

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: _borderColor,
          ),
        ),

        actions: [
          TextButton.icon(
            onPressed: auth.isLoading
                ? null
                : () => _logout(context, ref),

            style: TextButton.styleFrom(
              foregroundColor: _darkGreen,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
            ),

            icon: auth.isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryGreen,
                    ),
                  )
                : const Icon(
                    Icons.logout_rounded,
                    size: 19,
                  ),

            label: Text(
              auth.isLoading ? 'Logging out...' : 'Logout',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 10),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 15 : 26,
                vertical: isMobile ? 20 : 28,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1150,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWelcomeSection(
                        context: context,
                        name: auth.name,
                        schoolId: auth.schoolId,
                      ),

                      const SizedBox(height: 30),

                      _buildSectionHeading(context),

                      const SizedBox(height: 19),

                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final width = gridConstraints.maxWidth;

                          final columns = width >= 900
                              ? 4
                              : width >= 560
                                  ? 2
                                  : 1;

                          final cardHeight = columns == 1
                              ? 145.0
                              : 165.0;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),

                            itemCount: modules.length,

                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: cardHeight,
                            ),

                            itemBuilder: (context, index) {
                              final module = modules[index];

                              return _buildModuleCard(
                                context: context,
                                module: module,
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      Center(
                        child: Text(
                          'Pupilink School Management System',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: _secondaryText,
                              ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Dashboard module model
// -----------------------------------------------------------------------------

class _DashboardModule {
  const _DashboardModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

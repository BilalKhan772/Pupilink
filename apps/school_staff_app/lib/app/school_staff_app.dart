
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../features/auth/logic/staff_auth_controller.dart';
import '../features/auth/ui/staff_login_screen.dart';
import '../features/dashboard/ui/school_admin_dashboard_screen.dart';

class SchoolStaffApp extends StatelessWidget {
  const SchoolStaffApp({
    super.key,
    required this.config,
  });

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
        ),
      ),
      home: const StaffAppEntryScreen(),
    );
  }
}

class StaffAppEntryScreen extends ConsumerWidget {
  const StaffAppEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(staffAuthControllerProvider);

    if (auth.isLoading && !auth.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return const StaffLoginScreen();
    }

    switch (auth.role) {
      case 'schoolAdmin':
        return const SchoolAdminDashboardScreen();

      case 'classTeacher':
      case 'subjectTeacher':
      case 'monitor':
        return StaffRolePlaceholderScreen(role: auth.role);

      default:
        return const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aapke account ka role recognized nahi hua. '
                'School administrator se rabta karein.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
    }
  }
}

class StaffRolePlaceholderScreen extends StatelessWidget {
  const StaffRolePlaceholderScreen({
    super.key,
    required this.role,
  });

  final String role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Workspace')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Role: $role\nIs role ka dashboard abhi tayyar kiya ja raha hai.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

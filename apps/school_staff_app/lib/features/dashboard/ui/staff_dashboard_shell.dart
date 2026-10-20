
import 'package:flutter/material.dart';

import '../../staff_management/ui/screens/add_staff_screen.dart';
import '../../staff_management/ui/screens/staff_list_screen.dart';

class StaffDashboardShell extends StatefulWidget {
  const StaffDashboardShell({super.key});

  @override
  State<StaffDashboardShell> createState() => _StaffDashboardShellState();
}

class _StaffDashboardShellState extends State<StaffDashboardShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    _StaffHomeContent(),
    StaffListScreen(),
  ];

  void _selectScreen(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Staff Dashboard' : 'Staff Members',
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 44),
                      SizedBox(height: 8),
                      Text(
                        'Pupilink Staff',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                selected: _selectedIndex == 0,
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Dashboard'),
                onTap: () => _selectScreen(0),
              ),
              ListTile(
                selected: _selectedIndex == 1,
                leading: const Icon(Icons.people_outline),
                title: const Text('Staff Members'),
                onTap: () => _selectScreen(1),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text('Add Staff'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddStaffScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}

class _StaffHomeContent extends StatelessWidget {
  const _StaffHomeContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Welcome to Pupilink',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Staff accounts manage karne ke liye neeche button use karein.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddStaffScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Staff Member'),
            ),
          ],
        ),
      ),
    );
  }
}

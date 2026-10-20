import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/logic/staff_auth_controller.dart';
import '../../logic/staff_management_controller.dart';
import 'add_staff_screen.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final schoolId = ref.read(staffAuthControllerProvider).schoolId;
    if (schoolId.trim().isEmpty) return;

    await ref
        .read(staffManagementControllerProvider.notifier)
        .loadStaff(schoolId: schoolId);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'schoolAdmin':
        return 'School Admin';
      case 'classTeacher':
        return 'Class Teacher';
      case 'subjectTeacher':
        return 'Subject Teacher';
      case 'monitor':
        return 'Monitor';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffManagementControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Members'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddStaffScreen()),
          );
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Staff'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: state.isLoading && state.staff.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 250),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : state.errorMessage != null && state.staff.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.error_outline, size: 44),
                  const SizedBox(height: 12),
                  Text(state.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton(
                      onPressed: _load,
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              )
            : state.staff.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.people_outline, size: 56),
                  SizedBox(height: 16),
                  Text(
                    'Abhi koi staff member nahi mila.',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: state.staff.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final member = state.staff[index];
                  final name = member['name'] as String? ?? 'Staff Member';
                  final email = member['email'] as String? ?? '';
                  final role = member['role'] as String? ?? '';
                  final isActive = member['isActive'] != false;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text('$email\n${_roleLabel(role)}'),
                      isThreeLine: true,
                      trailing: Icon(
                        isActive
                            ? Icons.check_circle_outline
                            : Icons.block_outlined,
                        color: isActive ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

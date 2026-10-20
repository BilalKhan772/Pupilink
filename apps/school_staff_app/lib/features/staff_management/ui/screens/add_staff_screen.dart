
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/logic/staff_auth_controller.dart';
import '../../logic/staff_management_controller.dart';
import '../widgets/staff_form.dart';

class AddStaffScreen extends ConsumerWidget {
  const AddStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(staffAuthControllerProvider);
    final managementState = ref.watch(staffManagementControllerProvider);

    final schoolId = authState.schoolId;
    final isCreating = managementState.isCreating;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff Member')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add_alt_1, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Create Staff Account',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Staff member ke liye account banayein aur uska role select karein.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (managementState.errorMessage != null) ...[
                    _MessageCard(
                      message: managementState.errorMessage!,
                      isError: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (managementState.successMessage != null) ...[
                    _MessageCard(
                      message: managementState.successMessage!,
                      isError: false,
                    ),
                    const SizedBox(height: 16),
                  ],
                  StaffForm(
                    isLoading: isCreating,
                    onSubmit: ({
                      required name,
                      required email,
                      required password,
                      required role,
                    }) async {
                      if (schoolId.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Admin profile mein schoolId nahi hai.'),
                          ),
                        );
                        return;
                      }

                      await ref
                          .read(staffManagementControllerProvider.notifier)
                          .createStaff(
                            name: name,
                            email: email,
                            password: password,
                            role: role,
                            schoolId: schoolId,
                          );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Note: Monitor ka account yahan create ho jayega. '
                    'Uski class aur section assignment aglay step mein add hogi.',
                    textAlign: TextAlign.center,
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: color)),
    );
  }
}

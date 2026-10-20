
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../logic/monitor_controller.dart';
import '../logic/monitor_state.dart';

class ManageMonitorScreen extends ConsumerStatefulWidget {
  const ManageMonitorScreen({super.key});

  @override
  ConsumerState<ManageMonitorScreen> createState() =>
      _ManageMonitorScreenState();
}

class _ManageMonitorScreenState
    extends ConsumerState<ManageMonitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedSectionId;
  bool _obscurePassword = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loaded) {
      _loaded = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final profile =
            ref.read(staffAuthControllerProvider).profile;
        final schoolId = profile?['schoolId'] as String? ?? '';

        if (schoolId.isNotEmpty) {
          ref.read(monitorControllerProvider.notifier).loadData(
                schoolId: schoolId,
              );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitorState = ref.watch(monitorControllerProvider);
    final profile = ref.watch(staffAuthControllerProvider).profile;
    final schoolId = profile?['schoolId'] as String? ?? '';

    ref.listen<MonitorState>(monitorControllerProvider, (previous, next) {
      if (!mounted) return;

      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );

        _formKey.currentState?.reset();
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();

        setState(() {
          _selectedSectionId = null;
        });
      }

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Monitors'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: schoolId.isEmpty || monitorState.isLoading
                ? null
                : () => ref
                    .read(monitorControllerProvider.notifier)
                    .loadData(schoolId: schoolId),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: schoolId.isEmpty
          ? const Center(
              child: Text('School ID profile mein available nahi hai.'),
            )
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(monitorControllerProvider.notifier)
                  .loadData(schoolId: schoolId),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCreateForm(monitorState, schoolId),
                  const SizedBox(height: 28),
                  Text(
                    'Existing Monitors (${monitorState.monitors.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (monitorState.isLoading &&
                      monitorState.monitors.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (monitorState.monitors.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Abhi is school mein koi monitor account nahi mila.',
                        ),
                      ),
                    )
                  else
                    ...monitorState.monitors.map(_buildMonitorCard),
                ],
              ),
            ),
    );
  }

  Widget _buildCreateForm(
    MonitorState monitorState,
    String schoolId,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Monitor Account',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Monitor Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Monitor ka naam enter karein.';
                  }
                  if (value.trim().length > 100) {
                    return 'Naam 100 characters se zyada nahi ho sakta.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@')) {
                    return 'Valid email enter karein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password (minimum 8 characters)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password kam az kam 8 characters ka ho.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSectionId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assign Section',
                  prefixIcon: Icon(Icons.groups_outlined),
                  border: OutlineInputBorder(),
                ),
                items: monitorState.sections.map((section) {
                  final sectionId = section['id'] as String;
                  final sectionName =
                      section['name'] as String? ?? 'Unnamed Section';
                  final classId =
                      section['classId'] as String? ?? '';

                  return DropdownMenuItem<String>(
                    value: sectionId,
                    child: Text(
                      classId.isEmpty
                          ? sectionName
                          : '$sectionName (Class ID: $classId)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: monitorState.isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _selectedSectionId = value;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Section select karein.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: monitorState.isSaving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }

                          if (schoolId.isEmpty ||
                              _selectedSectionId == null) {
                            return;
                          }

                          await ref
                              .read(monitorControllerProvider.notifier)
                              .createMonitor(
                                schoolId: schoolId,
                                name: _nameController.text,
                                email: _emailController.text,
                                password: _passwordController.text,
                                sectionId: _selectedSectionId!,
                              );
                        },
                  icon: monitorState.isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(
                    monitorState.isSaving
                        ? 'Creating...'
                        : 'Create Monitor',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonitorCard(Map<String, dynamic> monitor) {
    final name = monitor['name'] as String? ?? 'Unknown Monitor';
    final email = monitor['email'] as String? ?? '';
    final sectionName = monitor['sectionName'] as String? ?? '';
    final classId = monitor['classId'] as String? ?? '';
    final isActive = monitor['isActive'] != false;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'M',
          ),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty) Text(email),
            Text(
              sectionName.isEmpty
                  ? 'Section ID: ${monitor['sectionId'] ?? 'Not assigned'}'
                  : classId.isEmpty
                      ? 'Section: $sectionName'
                      : 'Section: $sectionName • Class ID: $classId',
            ),
            Text(isActive ? 'Active' : 'Inactive'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

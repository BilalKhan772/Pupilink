import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/connect_child_controller.dart';
import '../widgets/city_dropdown.dart';
import '../widgets/school_dropdown.dart';
import '../widgets/admission_number_field.dart';
import '../widgets/child_security_notice.dart';

class ConnectChildScreen extends ConsumerStatefulWidget {
  const ConnectChildScreen({super.key});

  @override
  ConsumerState<ConnectChildScreen> createState() =>
      _ConnectChildScreenState();
}

class _ConnectChildScreenState
    extends ConsumerState<ConnectChildScreen> {
  final TextEditingController admissionController =
      TextEditingController();

  String? selectedCity;
  String? selectedSchool;

  @override
  void dispose() {
    admissionController.dispose();
    super.dispose();
  }

  Future<void> _connectChild() async {
    // Validate fields
    if (selectedCity == null ||
        selectedSchool == null ||
        admissionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'City, school aur admission number complete karein.',
          ),
        ),
      );

      return;
    }

    // Call controller
    final success = await ref
        .read(
          connectChildControllerProvider.notifier,
        )
        .connectChild(
          city: selectedCity!,
          schoolId: selectedSchool!,
          admissionNumber: admissionController.text.trim(),
        );

    if (!mounted) return;

    // If successfully connected
    if (success) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      connectChildControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connect Child',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Connect Your Child',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Apne child ki school information '
                'enter karke linking request bhejein.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 24),

              const ChildSecurityNotice(),

              const SizedBox(height: 20),

              CityDropdown(
                value: selectedCity,
                onChanged: (value) {
                  setState(() {
                    selectedCity = value;
                    selectedSchool = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              SchoolDropdown(
                value: selectedSchool,
                onChanged: (value) {
                  setState(() {
                    selectedSchool = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              AdmissionNumberField(
                controller: admissionController,
              ),

              const SizedBox(height: 28),

              if (state.error != null) ...[
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 15),
              ],

              if (state.isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _connectChild,
                    icon: const Icon(
                      Icons.link,
                    ),
                    label: const Text(
                      'Connect Child',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
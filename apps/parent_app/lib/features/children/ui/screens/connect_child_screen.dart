
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

class _ConnectChildScreenState extends ConsumerState<ConnectChildScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDCE9DF);
  static const Color _text = Color(0xFF24332A);
  static const Color _muted = Color(0xFF718078);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController admissionController =
      TextEditingController();

  String? selectedCity;
  String? selectedSchool;

  @override
  void initState() {
    super.initState();

    // Clear any previous request error when this screen is opened.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(connectChildControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    admissionController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // CONNECT CHILD
  // ------------------------------------------------------------

  Future<void> _connectChild() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCity == null || selectedSchool == null) {
      return;
    }

    final success = await ref
        .read(connectChildControllerProvider.notifier)
        .connectChild(
          city: selectedCity!,
          schoolId: selectedSchool!,
          admissionNumber: admissionController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    }
  }

  // ------------------------------------------------------------
  // ERROR MESSAGE
  // ------------------------------------------------------------

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFF2CACA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SCREEN HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: Color(0xFFE4F3E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.family_restroom_rounded,
            size: 39,
            color: _darkGreen,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Connect Your Child',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _darkGreen,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Link your child to Pupilink to access school '
          'information, attendance and academic progress.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _muted,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // FIELD LABEL
  // ------------------------------------------------------------

  Widget _fieldHeading({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SCREEN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectChildControllerProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 600 ? 16.0 : 28.0;
    final cardPadding = screenWidth < 400 ? 18.0 : 26.0;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _darkGreen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect Child',
              style: TextStyle(
                color: _darkGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Link your child\'s school account',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: _border,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 26,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 680,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 25),

                      const ChildSecurityNotice(),

                      const SizedBox(height: 22),

                      // ------------------------------------------------
                      // CONNECTION FORM
                      // ------------------------------------------------

                      Container(
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF16452C)
                                  .withValues(alpha: 0.035),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    color: _green,
                                    size: 22,
                                  ),
                                  SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      'Student Information',
                                      style: TextStyle(
                                        color: _darkGreen,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 7),

                              const Text(
                                'Enter the school details exactly as '
                                'registered with the school.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),

                              const SizedBox(height: 23),

                              _fieldHeading(
                                title: 'City',
                                subtitle: 'Select the city of your child\'s school.',
                              ),

                              CityDropdown(
                                value: selectedCity,
                                enabled: !state.isLoading,
                                onChanged: (value) {
                                  setState(() {
                                    selectedCity = value;
                                    selectedSchool = null;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              _fieldHeading(
                                title: 'School',
                                subtitle: 'Choose your child\'s school.',
                              ),

                              SchoolDropdown(
                                value: selectedSchool,
                                enabled: !state.isLoading,
                                onChanged: (value) {
                                  setState(() {
                                    selectedSchool = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              _fieldHeading(
                                title: 'Admission Number',
                                subtitle:
                                    'Enter the admission number provided by the school.',
                              ),

                              AdmissionNumberField(
                                controller: admissionController,
                                enabled: !state.isLoading,
                              ),

                              if (state.error != null) ...[
                                const SizedBox(height: 18),
                                _buildErrorBanner(state.error!),
                              ],

                              const SizedBox(height: 24),

                              SizedBox(
                                height: 54,
                                child: FilledButton.icon(
                                  onPressed:
                                      state.isLoading ? null : _connectChild,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        _green.withValues(alpha: 0.55),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  ),
                                  icon: state.isLoading
                                      ? const SizedBox(
                                          width: 19,
                                          height: 19,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.link_rounded,
                                          size: 20,
                                        ),
                                  label: Text(
                                    state.isLoading
                                        ? 'Submitting Request...'
                                        : 'Send Link Request',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              const Text(
                                'Your request will be reviewed by the school. '
                                'The child will appear in your account after '
                                'the school approves the request.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Pupilink • School Progress Management System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
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

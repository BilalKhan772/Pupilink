
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/parent_auth_controller.dart';
import '../../../../routing/parent_router.dart';

class ParentSignupScreen extends ConsumerStatefulWidget {
  const ParentSignupScreen({super.key});

  @override
  ConsumerState<ParentSignupScreen> createState() =>
      _ParentSignupScreenState();
}

class _ParentSignupScreenState extends ConsumerState<ParentSignupScreen> {
  static const Color _green = Color(0xFF138A4B);
  static const Color _darkGreen = Color(0xFF105C3B);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFDCE9DF);
  static const Color _text = Color(0xFF24332A);
  static const Color _muted = Color(0xFF718078);

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SIGN UP
  // ------------------------------------------------------------

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Please accept the Terms and Conditions to continue.',
            ),
          ),
        );
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    final success = await ref
        .read(parentAuthControllerProvider.notifier)
        .signup(
          name: name,
          email: email,
          password: password,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        ParentRouter.dashboard,
        (route) => false,
      );
    }
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: _green,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _green,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.4,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BRAND HEADER
  // ------------------------------------------------------------

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5EC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.family_restroom_rounded,
            size: 52,
            color: _darkGreen,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Welcome to Pupilink!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create Your Parent Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Connect with your child\'s school and stay '
          'informed about academic progress.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: _muted,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // ERROR BANNER
  // This helper is deliberately defined only once.
  // ------------------------------------------------------------

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF4C7C7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFB42318),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 13,
                height: 1.4,
              ),
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
    final authState = ref.watch(parentAuthControllerProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 600 ? 18.0 : 28.0;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _darkGreen,
        title: const Text(
          'Pupilink',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _darkGreen,
          ),
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
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 540,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(
                        screenWidth < 400 ? 20 : 30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16452C)
                                .withValues(alpha: 0.045),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBrandHeader(),

                            const SizedBox(height: 28),

                            // Full Name
                            TextFormField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.name,
                              ],
                              decoration: _inputDecoration(
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                final name = value?.trim() ?? '';

                                if (name.isEmpty) {
                                  return 'Full name is required.';
                                }

                                if (name.length < 2) {
                                  return 'Please enter a valid name.';
                                }

                                if (name.length > 80) {
                                  return 'Name must be 80 characters or fewer.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // Email Address
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              autocorrect: false,
                              decoration: _inputDecoration(
                                label: 'Email Address',
                                hint: 'Enter your email address',
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Email address is required.';
                                }

                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                                  return 'Please enter a valid email address.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.newPassword,
                              ],
                              decoration: _inputDecoration(
                                label: 'Password',
                                hint: 'Create a password',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final password = value ?? '';

                                if (password.isEmpty) {
                                  return 'Password is required.';
                                }

                                if (password.length < 6) {
                                  return 'Password must contain at least 6 characters.';
                                }

                                if (password.length > 128) {
                                  return 'Password must be 128 characters or fewer.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // Confirm Password
                            TextFormField(
                              controller: confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              decoration: _inputDecoration(
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password.';
                                }

                                if (value != passwordController.text) {
                                  return 'Passwords do not match.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Terms and Conditions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Checkbox(
                                    value: _acceptedTerms,
                                    activeColor: _green,
                                    onChanged: authState.isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _acceptedTerms =
                                                  value ?? false;
                                            });
                                          },
                                  ),
                                ),
                                const SizedBox(width: 9),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'I agree to the ',
                                          ),
                                          TextSpan(
                                            text: 'Terms and Conditions',
                                            style: TextStyle(
                                              color: _darkGreen,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy.',
                                            style: TextStyle(
                                              color: _darkGreen,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Authentication error
                            if (authState.error != null) ...[
                              const SizedBox(height: 14),
                              _buildErrorBanner(authState.error!),
                            ],

                            const SizedBox(height: 22),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton.icon(
                                onPressed: authState.isLoading
                                    ? null
                                    : _signup,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _green,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      _green.withValues(alpha: 0.55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: authState.isLoading
                                    ? const SizedBox(
                                        width: 19,
                                        height: 19,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person_add_alt_1_rounded,
                                      ),
                                label: Text(
                                  authState.isLoading
                                      ? 'Creating Account...'
                                      : 'Create Pupilink Account',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Divider
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: _border),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'Parent Registration',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: _border),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Login Navigation
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(color: _muted),
                                ),
                                TextButton(
                                  onPressed: authState.isLoading
                                      ? null
                                      : () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            ParentRouter.login,
                                          );
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: _darkGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

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

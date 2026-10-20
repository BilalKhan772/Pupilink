
import 'package:flutter/material.dart';

import 'role_selector.dart';

class StaffForm extends StatefulWidget {
  const StaffForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  final bool isLoading;
  final Future<void> Function({
    required String name,
    required String email,
    required String password,
    required String role,
  }) onSubmit;

  @override
  State<StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends State<StaffForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'monitor';
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.onSubmit(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _role,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            enabled: !widget.isLoading,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name enter karein.';
              }
              if (value.trim().length > 100) {
                return 'Name 100 characters se chhota hona chahiye.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Valid email address enter karein.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            enabled: !widget.isLoading,
            obscureText: _hidePassword,
            decoration: InputDecoration(
              labelText: 'Temporary Password',
              helperText: 'Kam az kam 8 characters.',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _hidePassword = !_hidePassword);
                },
                icon: Icon(
                  _hidePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final password = value ?? '';
              if (password.length < 8) {
                return 'Password kam az kam 8 characters ka ho.';
              }
              if (password.length > 128) {
                return 'Password bohat lamba hai.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          RoleSelector(
            value: _role,
            enabled: !widget.isLoading,
            onChanged: (role) => setState(() => _role = role),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: widget.isLoading ? null : _submit,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1),
            label: Text(
              widget.isLoading ? 'Creating Account...' : 'Create Staff Account',
            ),
          ),
        ],
      ),
    );
  }
}

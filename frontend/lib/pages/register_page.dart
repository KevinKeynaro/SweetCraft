import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverErrors = <String, String>{};
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ApiService.post('/auth/register', {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, _emailController.text.trim());
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isConflict) {
        setState(() => _serverErrors['email'] = error.message);
        _formKey.currentState!.validate();
      } else if (error.fieldErrors.isNotEmpty) {
        setState(() => _serverErrors.addAll(error.fieldErrors));
        _formKey.currentState!.validate();
      } else {
        _showError(error.message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF991B1B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ),
      );
  }

  void _clearServerError(String field) {
    if (_serverErrors.remove(field) != null) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Buat akun SweetCraft',
      subtitle: 'Daftar sebagai pembeli. Akun penjual disediakan oleh admin.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Sudah punya akun?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6E5D4F),
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8C4A27),
              minimumSize: const Size(48, 48),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Masuk'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nama lengkap',
              hint: 'cth. Siti Rahmawati',
              controller: _nameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              validator: (value) =>
                  _serverErrors['name'] ?? _validateName(value),
              onChanged: (_) => _clearServerError('name'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email',
              hint: 'nama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) =>
                  _serverErrors['email'] ?? _validateEmail(value),
              onChanged: (_) => _clearServerError('email'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nomor HP (opsional)',
              hint: '08xxxxxxxxxx',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: (value) =>
                  _serverErrors['phone'] ?? _validatePhone(value),
              onChanged: (_) => _clearServerError('phone'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              hint: 'Minimal 6 karakter',
              helperText: 'Minimal 6 karakter.',
              controller: _passwordController,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) =>
                  _serverErrors['password'] ?? _validateRegisterPassword(value),
              onChanged: (_) => _clearServerError('password'),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Daftar',
              onPressed: _submit,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

String? _validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Nama wajib diisi';
  if (name.length < 2) return 'Nama minimal 2 karakter';
  if (name.length > 100) return 'Nama maksimal 100 karakter';
  return null;
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi';
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!pattern.hasMatch(email)) return 'Email tidak valid';
  if (email.length > 150) return 'Email maksimal 150 karakter';
  return null;
}

String? _validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) return null;
  if (phone.length < 8) return 'Nomor HP minimal 8 digit';
  if (phone.length > 20) return 'Nomor HP maksimal 20 digit';
  return null;
}

String? _validateRegisterPassword(String? value) {
  if (value == null || value.isEmpty) return 'Password wajib diisi';
  if (value.length < 6) return 'Password minimal 6 karakter';
  if (value.length > 255) return 'Password maksimal 255 karakter';
  return null;
}

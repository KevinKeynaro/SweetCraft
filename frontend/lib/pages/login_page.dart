import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_scaffold.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverErrors = <String, String>{};
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
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
      final data = await ApiService.post('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
      final payload = data as Map<String, dynamic>;
      final token = payload['token'] as String?;
      final user = payload['user'] as Map<String, dynamic>?;
      if (token == null || user == null) {
        throw const ApiException('Respons login tidak valid.');
      }

      await ApiService.saveToken(token);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomePage(
            name: user['name'] as String,
            role: user['role'] as String,
          ),
        ),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.fieldErrors.isNotEmpty) {
        setState(() => _serverErrors.addAll(error.fieldErrors));
        _formKey.currentState!.validate();
      } else {
        _showSnackBar(error.message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFF991B1B)
              : const Color(0xFF166534),
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

  Future<void> _openRegister() async {
    final email = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
    if (!mounted || email == null) return;

    _emailController.text = email;
    _passwordController.clear();
    _showSnackBar('Registrasi berhasil. Silakan masuk.', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Masuk ke SweetCraft',
      subtitle: 'Selamat datang kembali. Masuk untuk melanjutkan pesanan Anda.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Belum punya akun?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6E5D4F),
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : _openRegister,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8C4A27),
              minimumSize: const Size(48, 48),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Daftar'),
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
              label: 'Email',
              hint: 'nama@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: (value) =>
                  _serverErrors['email'] ?? _validateEmail(value),
              onChanged: (_) => _clearServerError('email'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              hint: 'Masukkan password Anda',
              controller: _passwordController,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (value) =>
                  _serverErrors['password'] ?? _validateLoginPassword(value),
              onChanged: (_) => _clearServerError('password'),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Masuk',
              onPressed: _submit,
              isLoading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi';
  final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!pattern.hasMatch(email)) return 'Email tidak valid';
  if (email.length > 150) return 'Email maksimal 150 karakter';
  return null;
}

String? _validateLoginPassword(String? value) {
  if (value == null || value.isEmpty) return 'Password wajib diisi';
  return null;
}

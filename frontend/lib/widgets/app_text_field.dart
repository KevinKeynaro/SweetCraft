import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helperText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.isPassword = false,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helperText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool isPassword;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      obscureText: _obscured,
      cursorColor: const Color(0xFF8C4A27),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        color: const Color(0xFF2B2118),
      ),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: const Color(0xFF6E5D4F),
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5C341E),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFFA79A8C),
        ),
        helperStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: const Color(0xFF6E5D4F),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: const Color(0xFF991B1B),
        ),
        errorMaxLines: 2,
        border: _border(const Color(0xFF9C8370)),
        enabledBorder: _border(const Color(0xFF9C8370)),
        focusedBorder: _border(const Color(0xFF5C341E), width: 2),
        errorBorder: _border(const Color(0xFF991B1B)),
        focusedErrorBorder: _border(const Color(0xFF991B1B), width: 2),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscured
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                iconSize: 20,
                color: const Color(0xFF6E5D4F),
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

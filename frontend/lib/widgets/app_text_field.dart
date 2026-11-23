import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Input field kustom SweetCraft dengan styling artisanal bakery modern.
///
/// Memenuhi WCAG 2.5.8 & Material 3 Touch Target Guidelines (tinggi >= 52dp),
/// surface background [Color(0xFFFAF7F2)], border dekoratif halus [Color(0xFFE6DDD0)],
/// dan fokus aksen caramel [Color(0xFF8C4A27)].
///
/// Referensi standar:
/// - Flutter InputDecoration: https://api.flutter.dev/flutter/material/InputDecoration-class.html
/// - WCAG 2.5.8 Target Size: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
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
    this.prefixIcon,
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
  final Widget? prefixIcon;
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
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF2B2118),
      ),
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      scrollPadding: const EdgeInsets.only(bottom: 120),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: widget.prefixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 48,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: const Color(0xFFFAF7F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6E5D4F),
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          height: 16 / 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8C4A27),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 22 / 14,
          color: const Color(0xFFA79A8C),
        ),
        helperStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          height: 16 / 12,
          color: const Color(0xFF6E5D4F),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          height: 16 / 12,
          color: const Color(0xFF991B1B),
        ),
        errorMaxLines: 2,
        border: _border(const Color(0xFFE6DDD0)),
        enabledBorder: _border(const Color(0xFFE6DDD0)),
        focusedBorder: _border(const Color(0xFF8C4A27), width: 2),
        errorBorder: _border(const Color(0xFF991B1B)),
        focusedErrorBorder: _border(const Color(0xFF991B1B), width: 2),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscured
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                iconSize: 20,
                color: const Color(0xFF6E5D4F),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
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

  OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

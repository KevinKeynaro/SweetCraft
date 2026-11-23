import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.semanticLabel,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.isPassword = false,
    this.enabled = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
  });

  final String semanticLabel;
  final TextEditingController controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool isPassword;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  static const _errorColor = Color(0xFFDC2626);
  static const _errorFill = Color(0xFFFEF2F2);
  static const _neutralBorder = Color(0xFF8C8C8C);
  static const _focusBorder = Color(0xFF111827);
  static const _hintColor = Color(0xFF6B7280);

  late bool _obscured = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (field) {
        final hasError = field.hasError;

        return Semantics(
          label: widget.semanticLabel,
          hint: field.errorText,
          child: TextField(
            controller: widget.controller,
            enabled: widget.enabled,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            cursorColor: _focusBorder,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: const Color(0xFF2B2118),
            ),
            scrollPadding: const EdgeInsets.only(bottom: 120),
            onChanged: (value) {
              field.didChange(value);
              widget.onChanged?.call(value);
            },
            onSubmitted: widget.onFieldSubmitted,
            decoration: InputDecoration(
              hintText: widget.hint ?? widget.semanticLabel,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 22 / 14,
                color: _hintColor,
              ),
              filled: true,
              fillColor: hasError ? _errorFill : const Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: widget.prefixIcon,
                    ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 46,
                minHeight: 48,
              ),
              suffixIcon: _suffixIcon(hasError),
              border: _border(hasError ? _errorColor : _neutralBorder),
              enabledBorder: _border(hasError ? _errorColor : _neutralBorder),
              focusedBorder: _border(
                hasError ? _errorColor : _focusBorder,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _suffixIcon(bool hasError) {
    final errorIcon = hasError
        ? const Icon(
            Icons.error_outline,
            size: 20,
            color: _errorColor,
            semanticLabel: 'Input tidak valid',
          )
        : null;

    if (!widget.isPassword) return errorIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?errorIcon,
        IconButton(
          tooltip: _obscured ? 'Tampilkan password' : 'Sembunyikan password',
          iconSize: 20,
          color: _hintColor,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => setState(() => _obscured = !_obscured),
          icon: Icon(
            _obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

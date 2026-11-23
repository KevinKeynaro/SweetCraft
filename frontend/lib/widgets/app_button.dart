import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const minimumSize = Size.fromHeight(48);
    final child = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined
                  ? const Color(0xFF8C4A27)
                  : const Color(0xFFFFFFFF),
            ),
          )
        : Text(label, textAlign: TextAlign.center, style: textStyle);

    if (outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8C4A27),
          disabledForegroundColor: const Color(0xFFA79A8C),
          minimumSize: minimumSize,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: Color(0xFF8C4A27)),
          shape: shape,
          textStyle: textStyle,
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF8C4A27),
        foregroundColor: const Color(0xFFFFFFFF),
        disabledBackgroundColor: const Color(0xFFEFE9E1),
        disabledForegroundColor: const Color(0xFFA79A8C),
        minimumSize: minimumSize,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: shape,
        textStyle: textStyle,
      ),
      child: child,
    );
  }
}

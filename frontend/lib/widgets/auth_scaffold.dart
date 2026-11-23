import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/sweetcraft_logo_concept_1.png',
                              width: 360,
                              height: 180,
                              fit: BoxFit.contain,
                              semanticLabel: 'Logo SweetCraft',
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.cake_outlined,
                                  size: 128,
                                  color: Color(0xFF8C4A27),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fraunces(
                                fontSize: 24,
                                height: 32 / 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2B2118),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              height: 22 / 14,
                              color: const Color(0xFF6E5D4F),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE6DDD0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0A2B2118),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: child,
                          ),
                          if (footer != null) ...[
                            const SizedBox(height: 16),
                            footer!,
                          ],
                        ],
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

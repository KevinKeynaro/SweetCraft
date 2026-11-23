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
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight =
                (constraints.maxHeight * 0.30).clamp(160.0, 240.0);
            final minContainerHeight = (constraints.maxHeight - headerHeight)
                .clamp(0.0, double.infinity);

            return SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Area Header (30% bagian logo)
                  SizedBox(
                    height: headerHeight,
                    width: double.infinity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Lingkaran Kanan Atas
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x1A5C341E),
                            ),
                          ),
                        ),
                        // Lingkaran Kiri Bawah (di dasar area header, di bawah container putih)
                        Positioned(
                          bottom: -35,
                          left: -40,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x268C4A27),
                            ),
                          ),
                        ),
                        // Logo SweetCraft
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Image.asset(
                              'assets/images/sweetcraft_logo_concept_1.png',
                              width: 240,
                              height: 120,
                              fit: BoxFit.contain,
                              semanticLabel: 'Logo SweetCraft',
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.cake_outlined,
                                  size: 72,
                                  color: Color(0xFF8C4A27),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Container Putih Melengkung (Bagian Bawah ~70%)
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: minContainerHeight),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0D2B2118),
                          blurRadius: 20,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  title,
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  height: 22 / 14,
                                  color: const Color(0xFF6E5D4F),
                                ),
                              ),
                              const SizedBox(height: 24),
                              child,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

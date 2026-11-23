import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Layout scaffolding terpadu untuk halaman autentikasi (Login & Register).
///
/// Menggunakan komposisi visual split-screen:
/// - Area Header (~28% tinggi layar): Logo SweetCraft 2x lebih besar (360x180dp),
///   dihiasi ornamen lingkaran coklat di sudut kanan atas dan kiri bawah header.
/// - Container Putih Melengkung (~72% tinggi layar): Memuat judul di posisi atas
///   dengan margin-top yang lega (40dp) agar tidak mepet lengkungan container,
///   serta mematuhi Touch Target Guidelines (WCAG 2.5.8 & Material Design 3).
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
            final headerHeight = (constraints.maxHeight * 0.28).clamp(
              200.0,
              250.0,
            );
            final minContainerHeight = (constraints.maxHeight - headerHeight)
                .clamp(0.0, double.infinity);

            return SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Area Header Logo (Logo 2x + Ornamen Lingkaran Sudut)
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
                            width: 140,
                            height: 140,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x1A5C341E),
                            ),
                          ),
                        ),
                        // Lingkaran Kiri Bawah Header (berada di belakang container putih)
                        Positioned(
                          bottom: -35,
                          left: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0x268C4A27),
                            ),
                          ),
                        ),
                        // Logo SweetCraft — Diperbesar 2x (360 x 180 dp)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Image.asset(
                              'assets/images/sweetcraft_logo_concept_1.png',
                              width: 360,
                              height: 180,
                              fit: BoxFit.contain,
                              semanticLabel: 'Logo SweetCraft',
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.cake_outlined,
                                  size: 96,
                                  color: Color(0xFF8C4A27),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Container Putih Melengkung (Bagian Bawah ~72%)
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
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
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
                                // Jarak aman antara tombol utama dan footer link
                                // untuk mematuhi Touch Target Guidelines (>= 28dp)
                                const SizedBox(height: 28),
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

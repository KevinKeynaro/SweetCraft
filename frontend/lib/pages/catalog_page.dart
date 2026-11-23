import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/catalog_view.dart';
import 'login_page.dart';

/// Katalog publik untuk pengunjung yang belum login (browse-first).
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        foregroundColor: const Color(0xFF2B2118),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'SweetCraft',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            height: 28 / 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2B2118),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8C4A27),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Masuk'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const CatalogView(),
    );
  }
}

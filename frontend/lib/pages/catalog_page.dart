import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/catalog_view.dart';
import 'login_page.dart';

/// Katalog publik untuk pengunjung yang belum login (browse-first).
class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: CatalogView(
        headerAction: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8C4A27),
              minimumSize: const Size(60, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              textStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Masuk'),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 0,
        onItemSelected: (index) {
          if (index != 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        },
      ),
    );
  }
}

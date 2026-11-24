import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom Navigation Bar statis bergaya artisanal bakery sesuai gambar referensi.
///
/// Memiliki latar putih bersih, 5 menu (Home, Search, Shop, Cart, Profile),
/// dan indikator aktif berupa lingkaran cokelat yang menonjol ke atas di tab aktif.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  static const _navItems = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.search_rounded, label: 'Search'),
    (icon: Icons.storefront_outlined, label: 'Shop'),
    (icon: Icons.shopping_bag_outlined, label: 'Cart'),
    (icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = index == selectedIndex;

            return Expanded(
              child: InkWell(
                onTap: () => onItemSelected(index),
                splashColor: const Color(0x1A8C4A27),
                highlightColor: Colors.transparent,
                child: SizedBox(
                  height: 64,
                  child: isSelected
                      ? Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Lingkaran cokelat menonjol ke atas
                            Positioned(
                              top: -16,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF8C4A27),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x338C4A27),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item.icon,
                                  color: const Color(0xFFFFFFFF),
                                  size: 24,
                                ),
                              ),
                            ),
                            // Label aktif
                            Positioned(
                              bottom: 6,
                              child: Text(
                                item.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8C4A27),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 22,
                              color: const Color(0xFF8C847E),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF8C847E),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

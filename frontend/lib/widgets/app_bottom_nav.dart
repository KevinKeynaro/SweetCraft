import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef NavBarItem = ({IconData icon, String label});

/// Bottom Navigation Bar statis bergaya artisanal bakery SweetCraft.
///
/// Memiliki latar putih bersih dengan sudut atas melengkung, mendukung daftar item
/// pembeli maupun penjual, dan indikator aktif berupa segi-empat cokelat tua dengan sudut
/// membulat (rounded edge) yang menonjol ke atas di tab aktif.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.items = buyerNavItems,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<NavBarItem> items;

  static const List<NavBarItem> buyerNavItems = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.search_rounded, label: 'Search'),
    (icon: Icons.add_rounded, label: 'Pre-Order'),
    (icon: Icons.shopping_bag_outlined, label: 'Cart'),
    (icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: 64 + bottomPadding,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () => onItemSelected(index),
                    splashColor: const Color(0x1A3A2114),
                    highlightColor: Colors.transparent,
                    child: SizedBox(
                      height: 64,
                      child: isSelected
                          ? Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Segi-empat cokelat tua lebih besar dengan rounded edge menonjol ke atas
                                Positioned(
                                  top: -20,
                                  child: Container(
                                    key: const ValueKey(
                                      'bottom-nav-active-square',
                                    ),
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3A2114),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x4D3A2114),
                                          blurRadius: 12,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: const Color(0xFFFFFFFF),
                                      size: 28,
                                    ),
                                  ),
                                ),
                                // Label aktif
                                Positioned(
                                  bottom: 4,
                                  child: Text(
                                    item.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF3A2114),
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
                                  size: 24,
                                  color: const Color(0xFF594333),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF594333),
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
        ),
      ),
    );
  }
}

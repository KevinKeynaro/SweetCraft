import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_button.dart';
import '../widgets/catalog_view.dart';
import 'catalog_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.name, required this.role});

  final String name;
  final String role;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  bool get _isSeller => widget.role == 'penjual';

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Keluar dari akun?',
            style: GoogleFonts.fraunces(
              fontSize: 20,
              height: 28 / 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2B2118),
            ),
          ),
          content: Text(
            'Anda akan kembali ke katalog.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 22 / 14,
              color: const Color(0xFF6E5D4F),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6E5D4F),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF991B1B),
                foregroundColor: const Color(0xFFFFFFFF),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const CatalogPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _isSeller
        ? <Widget>[
            const _PlaceholderTab(
              icon: Icons.restaurant_menu_outlined,
              title: 'Menu',
              description:
                  'Menu penjual akan tersedia di milestone berikutnya.',
            ),
            const _PlaceholderTab(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada pesanan masuk',
              description: 'Pesanan dari pembeli akan muncul di sini.',
            ),
            _ProfileTab(
              name: widget.name,
              role: widget.role,
              onLogout: _confirmLogout,
            ),
          ]
        : <Widget>[
            CatalogView(userName: widget.name),
            const _PlaceholderTab(
              icon: Icons.search_rounded,
              title: 'Search',
              description: 'Cari kue favorit Anda.',
            ),
            const _PlaceholderTab(
              icon: Icons.storefront_outlined,
              title: 'Shop',
              description: 'Jelajahi menu toko SweetCraft.',
            ),
            const _PlaceholderTab(
              icon: Icons.shopping_bag_outlined,
              title: 'Cart',
              description: 'Keranjang belanja Anda masih kosong.',
            ),
            _ProfileTab(
              name: widget.name,
              role: widget.role,
              onLogout: _confirmLogout,
            ),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: _isSeller
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              backgroundColor: const Color(0xFFFFFFFF),
              indicatorColor: const Color(0xFFF5EFE6),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF8C4A27)
                      : const Color(0xFF6E5D4F),
                );
              }),
              destinations: const [
                NavigationDestination(
                  icon: Icon(
                    Icons.restaurant_menu_outlined,
                    color: Color(0xFF6E5D4F),
                  ),
                  selectedIcon: Icon(
                    Icons.restaurant_menu,
                    color: Color(0xFF8C4A27),
                  ),
                  label: 'Menu',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF6E5D4F),
                  ),
                  selectedIcon: Icon(
                    Icons.receipt_long,
                    color: Color(0xFF8C4A27),
                  ),
                  label: 'Pesanan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline, color: Color(0xFF6E5D4F)),
                  selectedIcon: Icon(Icons.person, color: Color(0xFF8C4A27)),
                  label: 'Profil',
                ),
              ],
            )
          : AppBottomNav(
              selectedIndex: _index,
              onItemSelected: (index) => setState(() => _index = index),
            ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: const Color(0xFF8C4A27)),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    height: 28 / 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 22 / 14,
                    color: const Color(0xFF6E5D4F),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  AppButton(
                    label: actionLabel!,
                    outlined: true,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.name,
    required this.role,
    required this.onLogout,
  });

  final String name;
  final String role;
  final Future<void> Function() onLogout;

  String get _roleLabel => role == 'penjual' ? 'Penjual' : 'Pembeli';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profil',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Halo, $name',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masuk sebagai $_roleLabel.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 22 / 14,
                    color: const Color(0xFF6E5D4F),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6DDD0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        color: Color(0xFF8C4A27),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sesi Anda aktif.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: const Color(0xFF2B2118),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Keluar',
                  outlined: true,
                  onPressed: () {
                    onLogout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_button.dart';
import '../widgets/catalog_view.dart';
import '../widgets/seller_dashboard_widgets.dart';
import '../widgets/seller_home_view.dart';
import '../widgets/seller_menu_view.dart';
import 'add_edit_cake_page.dart';
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

  // State inventaris khusus pemilik toko (role == 'penjual')
  List<Map<String, dynamic>> _sellerCakes = [];
  List<Map<String, dynamic>> _sellerCategories = [];
  bool _sellerLoading = true;
  String? _sellerError;
  bool _isMockMode = false;
  final Set<int> _updatingCakeIds = {};
  String _productsStockFilter = 'all';

  bool get _isSeller => widget.role == 'penjual';

  @override
  void initState() {
    super.initState();
    if (_isSeller) {
      _loadSellerInventory();
    }
  }

  Future<void> _loadSellerInventory() async {
    setState(() {
      _sellerLoading = true;
      _sellerError = null;
    });

    try {
      final cakesRes = await ApiService.get('/cakes');
      final catsRes = await ApiService.get('/categories');

      final cakeList = ((cakesRes as Map<String, dynamic>?)?['cakes'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final catList = ((catsRes as Map<String, dynamic>?)?['categories'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      if (!mounted) return;
      if (cakeList.isEmpty) {
        // Fallback ke 8 data produk mock bila backend kosong
        setState(() {
          _sellerCakes = buildMockBakeryCakes();
          _sellerCategories =
              catList.isNotEmpty ? catList : buildMockBakeryCategories();
          _isMockMode = true;
          _sellerLoading = false;
        });
      } else {
        setState(() {
          _sellerCakes = cakeList.map((e) => Map<String, dynamic>.from(e)).toList();
          _sellerCategories =
              catList.isNotEmpty ? catList : buildMockBakeryCategories();
          _isMockMode = false;
          _sellerLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      // Fallback otomatis ke 8 data produk mock bila backend offline/timeout
      setState(() {
        if (_sellerCakes.isEmpty) {
          _sellerCakes = buildMockBakeryCakes();
        }
        if (_sellerCategories.isEmpty) {
          _sellerCategories = buildMockBakeryCategories();
        }
        _isMockMode = true;
        _sellerError = null;
        _sellerLoading = false;
      });
    }
  }

  Future<void> _updateCakeStock(Map<String, dynamic> cake, int newStock) async {
    final safeStock = newStock < 0 ? 0 : newStock;
    final cakeId = cake['id'] as int?;
    if (cakeId == null) return;

    final index = _sellerCakes.indexWhere((c) => c['id'] == cakeId);
    if (index == -1) return;

    final previousStock = _sellerCakes[index]['stock'];

    setState(() {
      _updatingCakeIds.add(cakeId);
      _sellerCakes[index] = {
        ..._sellerCakes[index],
        'stock': safeStock,
      };
    });

    if (_isMockMode || cakeId < 0) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _updatingCakeIds.remove(cakeId));
      return;
    }

    try {
      await ApiService.put('/cakes/$cakeId', {'stock': safeStock});
      if (!mounted) return;
      setState(() => _updatingCakeIds.remove(cakeId));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sellerCakes[index] = {
          ..._sellerCakes[index],
          'stock': previousStock,
        };
        _updatingCakeIds.remove(cakeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFA63232),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sellerCakes[index] = {
          ..._sellerCakes[index],
          'stock': previousStock,
        };
        _updatingCakeIds.remove(cakeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memperbarui stok ke server.'),
          backgroundColor: Color(0xFFA63232),
        ),
      );
    }
  }

  Future<void> _adjustCakeStock(Map<String, dynamic> cake, int delta) async {
    final current = (cake['stock'] as num?)?.toInt() ?? 0;
    await _updateCakeStock(cake, current + delta);
  }

  Future<void> _openEditCake(Map<String, dynamic> cake) async {
    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCakePage(
          cake: cake,
          initialCategories: _sellerCategories,
          isMockMode: _isMockMode,
        ),
      ),
    );

    if (updated == null || !mounted) return;
    setState(() {
      final idx = _sellerCakes.indexWhere((c) => c['id'] == updated['id']);
      if (idx != -1) {
        _sellerCakes[idx] = updated;
      }
    });
  }

  Future<void> _confirmDeleteCake(Map<String, dynamic> cake) async {
    final cakeId = cake['id'] as int?;
    final cakeName = cake['name'] as String? ?? 'produk ini';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Hapus Produk?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3B2A1E),
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "$cakeName" dari daftar menu toko?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF736052),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                foregroundColor: const Color(0xFF736052),
              ),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(84, 44),
                backgroundColor: const Color(0xFFA63232),
                foregroundColor: const Color(0xFFFFFFFF),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted || cakeId == null) return;

    if (!_isMockMode && cakeId > 0) {
      try {
        await ApiService.delete('/cakes/$cakeId');
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.isConflict
                  ? 'Produk tidak bisa dihapus karena sudah ada dalam pesanan.'
                  : e.message,
            ),
            backgroundColor: const Color(0xFFA63232),
          ),
        );
        return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus produk: $e'),
            backgroundColor: const Color(0xFFA63232),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _sellerCakes.removeWhere((c) => c['id'] == cakeId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$cakeName" berhasil dihapus'),
        backgroundColor: const Color(0xFF1E6B3A),
      ),
    );
  }

  void _openSellerProfileSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3EBDD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF8B5A2B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3B2A1E),
                            ),
                          ),
                          Text(
                            'Pemilik Toko • ${_isMockMode ? 'Mode Demo (Mock Data)' : 'Terhubung ke API'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF736052),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmLogout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar dari Akun'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: const Color(0xFFA63232),
                    side: const BorderSide(color: Color(0xFFA63232)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              height: 28 / 20,
              fontWeight: FontWeight.w700,
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
                minimumSize: const Size(48, 44),
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
                minimumSize: const Size(84, 44),
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
            SellerHomeView(
              ownerName: widget.name,
              cakes: _sellerCakes,
              loading: _sellerLoading,
              error: _sellerError,
              isMockMode: _isMockMode,
              updatingIds: _updatingCakeIds,
              onRefresh: _loadSellerInventory,
              onOpenProductsTab: ({String stockFilter = 'all'}) {
                setState(() {
                  _productsStockFilter = stockFilter;
                  _index = 1;
                });
              },
              onOpenAddTab: () => setState(() => _index = 2),
              onAdjustStock: _adjustCakeStock,
              onSetManualStock: _updateCakeStock,
              onOpenProfileDialog: _openSellerProfileSheet,
            ),
            SellerMenuView(
              cakes: _sellerCakes,
              categories: _sellerCategories,
              loading: _sellerLoading,
              error: _sellerError,
              updatingIds: _updatingCakeIds,
              initialStockFilter: _productsStockFilter,
              onRefresh: _loadSellerInventory,
              onAdjustStock: _adjustCakeStock,
              onSetManualStock: _updateCakeStock,
              onEditCake: _openEditCake,
              onDeleteCake: _confirmDeleteCake,
              onOpenAddTab: () => setState(() => _index = 2),
            ),
            AddEditCakePage(
              embedded: true,
              initialCategories: _sellerCategories,
              isMockMode: _isMockMode,
              onSaved: (newCake) {
                setState(() {
                  _sellerCakes.insert(0, newCake);
                  _productsStockFilter = 'all';
                  _index = 1;
                });
              },
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
      backgroundColor:
          _isSeller ? const Color(0xFFFAF6EC) : const Color(0xFFFDFBF7),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: _isSeller
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              backgroundColor: const Color(0xFFFFFFFF),
              surfaceTintColor: Colors.transparent,
              indicatorColor: const Color(0xFFF3EBDD),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected
                      ? const Color(0xFF8B5A2B)
                      : const Color(0xFF736052),
                );
              }),
              destinations: const [
                NavigationDestination(
                  icon: Icon(
                    Icons.dashboard_outlined,
                    color: Color(0xFF736052),
                  ),
                  selectedIcon: Icon(
                    Icons.dashboard_rounded,
                    color: Color(0xFF8B5A2B),
                  ),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF736052),
                  ),
                  selectedIcon: Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF8B5A2B),
                  ),
                  label: 'Produk',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF736052),
                  ),
                  selectedIcon: Icon(
                    Icons.add_circle_rounded,
                    color: Color(0xFF8B5A2B),
                  ),
                  label: 'Tambah',
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
  });

  final IconData icon;
  final String title;
  final String description;

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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    height: 28 / 20,
                    fontWeight: FontWeight.w700,
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w700,
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/create_order_page.dart';
import '../pages/login_page.dart';
import '../services/api.dart';
import 'product_card.dart';

/// Halaman Home / Katalog SweetCraft untuk pembeli & tamu:
/// 1. Header Container cokelat tua (meluas ke atas area status bar) dengan "Location" & Search Bar aktif.
/// 2. Section "Special Offer" & promotion banner warm saddle dengan gambar tart.
/// 3. Section "Categories" (5 kotak persegi empat bernuansa gelap yang bisa diketuk untuk filter kategori).
/// 4. Section "Products" menampilkan grid kartu produk dari backend (`GET /api/cakes`) lengkap
///    dengan loading, empty/error state, filter pencarian, dan detail produk saat diketuk.
class CatalogView extends StatefulWidget {
  const CatalogView({
    super.key,
    this.headerAction,
    this.userName,
    this.onOrderCreated,
  });

  final Widget? headerAction;
  final String? userName;
  final VoidCallback? onOrderCreated;

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _cakes = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedCategory;
  final _searchController = TextEditingController();

  static const _fallbackCategories = [
    (name: 'Cake', icon: 'assets/images/cupcake-icon.png'),
    (name: 'Cup Cake', icon: 'assets/images/cupcake-icon.png'),
    (name: 'Cookies', icon: 'assets/images/cupcake.png'),
    (name: 'Donuts', icon: 'assets/images/sour-dough.png'),
    (name: 'Bread', icon: 'assets/images/artisan-bread-icon.png'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_cakes.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.get('/categories'),
        ApiService.get('/cakes'),
      ]);
      final categoriesPayload = results[0] as Map<String, dynamic>?;
      final cakesPayload = results[1] as Map<String, dynamic>?;

      final categories =
          (categoriesPayload?['categories'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];
      final cakes =
          (cakesPayload?['cakes'] as List?)?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _cakes = cakes;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat menu kue. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  String _iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('bread') || lower.contains('roti')) {
      return 'assets/images/artisan-bread-icon.png';
    }
    if (lower.contains('pastry') || lower.contains('croissant')) {
      return 'assets/images/croissant.png';
    }
    if (lower.contains('donut') || lower.contains('sourdough')) {
      return 'assets/images/sour-dough.png';
    }
    return 'assets/images/cupcake-icon.png';
  }

  List<Map<String, dynamic>> _filteredCakes() {
    final q = _searchQuery.trim().toLowerCase();
    final selectedCat = _selectedCategory?.toLowerCase();

    return _cakes.where((cake) {
      final name = (cake['name'] as String? ?? '').toLowerCase();
      final desc = (cake['description'] as String? ?? '').toLowerCase();
      final cat = (cake['category'] as String? ?? '').toLowerCase();

      if (q.isNotEmpty && !name.contains(q) && !desc.contains(q)) {
        return false;
      }

      if (selectedCat != null && selectedCat.isNotEmpty) {
        if (selectedCat == 'cake') {
          if (!cat.contains('cake') && !cat.contains('tart')) return false;
        } else if (selectedCat == 'cup cake') {
          if (!cat.contains('cupcake') && !cat.contains('cup cake')) {
            return false;
          }
        } else if (selectedCat == 'bread' || selectedCat == 'breads') {
          if (!cat.contains('bread') && !cat.contains('roti')) return false;
        } else if (!cat.contains(selectedCat)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
    });
  }

  Future<void> _startOrder({Map<String, dynamic>? cake}) async {
    final token = await ApiService.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    final created = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => CreateOrderPage(cake: cake)),
    );
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cake != null
                ? 'Pesanan berhasil dibuat!'
                : 'Pesanan custom berhasil diajukan!',
          ),
          backgroundColor: const Color(0xFF166534),
        ),
      );
      _load();
      widget.onOrderCreated?.call();
    }
  }

  void _showCakeDetail(Map<String, dynamic> cake) {
    final name = cake['name'] as String? ?? 'Kue';
    final category = displayCategoryName(cake['category'] as String?);
    final description = cake['description'] as String? ?? '';
    final imageUrl = cake['image_url'] as String?;
    final stock = cake['stock'];
    final isCustom = cake['is_custom'] == true || cake['is_custom'] == 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6DDD0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _CakeFallbackBox(),
                          )
                        : const _CakeFallbackBox(),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFE6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8C4A27),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stockLabel(stock),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E6B3A),
                        ),
                      ),
                    ),
                    if (isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pre-Order Custom',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(cake['price']),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF8C4A27),
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 21 / 14,
                      color: const Color(0xFF6E5D4F),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: const Color(0xFF6E5D4F),
                          side: const BorderSide(color: Color(0xFFE6DDD0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: (stock is num && stock <= 0)
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _startOrder(cake: cake);
                              },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: const Color(0xFF8C4A27),
                          foregroundColor: const Color(0xFFFFFFFF),
                          disabledBackgroundColor: const Color(0xFFEFE9E1),
                          disabledForegroundColor: const Color(0xFFA79A8C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(
                          (stock is num && stock <= 0)
                              ? 'Stok Habis'
                              : (widget.headerAction != null
                                    ? 'Masuk untuk Pesan'
                                    : 'Pesan Sekarang'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width > 720 ? (width - 720) / 2 : 20.0;
    final topSafe = MediaQuery.paddingOf(context).top;

    final categoriesToDisplay =
        (_categories.isNotEmpty
                ? _categories.map((c) {
                    final name = displayCategoryName(c['name'] as String?);
                    return (
                      name: name.isEmpty ? 'Kue' : name,
                      icon: _iconForCategory(name),
                    );
                  }).toList()
                : _fallbackCategories)
            .take(5)
            .toList();

    final filtered = _filteredCakes();
    final hasFilter =
        _searchQuery.trim().isNotEmpty || _selectedCategory != null;

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF8C4A27),
      backgroundColor: const Color(0xFFFFFFFF),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Container cokelat tua menyatu hingga area status bar atas
            _HeaderSection(
              topPadding: topSafe,
              horizontalPadding: horizontalPadding,
              action: widget.headerAction,
              searchController: _searchController,
              searchQuery: _searchQuery,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),

            const SizedBox(height: 22),

            // 2. Section "Special Offer" & Promotion Banner
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: const _SectionHeader(title: 'Special Offer'),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _SpecialOfferBanner(onShopNow: () => _startOrder()),
            ),

            const SizedBox(height: 24),

            // 3. Section "Categories"
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _SectionHeader(
                title: 'Categories',
                actionLabel: _selectedCategory != null ? 'Reset' : 'See All',
                onSeeAll: _selectedCategory != null ? _resetFilters : null,
              ),
            ),
            const SizedBox(height: 14),
            _CategoriesHorizontalList(
              categories: categoriesToDisplay,
              horizontalPadding: horizontalPadding,
              selectedCategory: _selectedCategory,
              onSelectCategory: (name) {
                setState(() {
                  _selectedCategory = _selectedCategory == name ? null : name;
                });
              },
            ),

            const SizedBox(height: 26),

            // 4. Section "Products" + Grid Produk dari Backend
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _SectionHeader(
                title: 'Products',
                actionLabel: hasFilter ? 'Reset' : 'See All',
                onSeeAll: hasFilter ? _resetFilters : _load,
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _buildProductsBody(width, filtered, hasFilter),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsBody(
    double screenWidth,
    List<Map<String, dynamic>> filtered,
    bool hasFilter,
  ) {
    if (_loading && _cakes.isEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3EBDD),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }

    if (_error != null && _cakes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6DDD0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 36,
              color: Color(0xFF991B1B),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF6E5D4F),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(140, 44),
                backgroundColor: const Color(0xFF8C4A27),
                foregroundColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6DDD0)),
        ),
        child: Column(
          children: [
            Icon(
              hasFilter ? Icons.search_off_rounded : Icons.cake_outlined,
              size: 40,
              color: const Color(0xFF9C8370),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Tidak ada kue yang cocok'
                  : 'Belum ada menu kue tersedia',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B2118),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasFilter
                  ? 'Coba kata kunci atau kategori lain.'
                  : 'Tarik ke bawah untuk memuat ulang etalase.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF6E5D4F),
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  minimumSize: const Size(120, 44),
                  foregroundColor: const Color(0xFF8C4A27),
                ),
                child: const Text('Tampilkan Semua'),
              ),
            ],
          ],
        ),
      );
    }

    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (context, index) {
        final cake = filtered[index];
        return ProductCard(cake: cake, onTap: () => _showCakeDetail(cake));
      },
    );
  }
}

class _CakeFallbackBox extends StatelessWidget {
  const _CakeFallbackBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF7F2),
      child: const Center(
        child: Icon(Icons.cake_outlined, size: 48, color: Color(0xFF9C8370)),
      ),
    );
  }
}

/// Header Container cokelat tua dengan Location dan Search bar full-width
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.topPadding,
    required this.horizontalPadding,
    this.action,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final double topPadding;
  final double horizontalPadding;
  final Widget? action;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF8C4A27),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F2B2118),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding + 16,
        horizontalPadding,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Location (Kiri Atas)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFE6DDD0),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFFFDFBF7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Jakarta, Indonesia',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFDFBF7),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFFFDFBF7),
                      ),
                    ],
                  ),
                ],
              ),
              // Aksi opsional (misal tombol Masuk untuk tamu)
              ?action,
            ],
          ),

          const SizedBox(height: 18),

          // Search Bar Full-Width (Putih, Rounded, Placeholder "Search")
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF2B2118),
              ),
              cursorColor: const Color(0xFF8C4A27),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFFA79A8C),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: Color(0xFF6E5D4F),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 48,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: onClearSearch,
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF6E5D4F),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header baris dengan judul di kiri dan teks "See All" / "Reset" cokelat di kanan
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel = 'See All',
    this.onSeeAll,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: const Color(0xFF2B2118),
          ),
        ),
        InkWell(
          onTap: onSeeAll,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              actionLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C4A27),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Promotion Banner warm saddle dengan badge "Limited time.", "Get Special Offer", "Up to 50%", "Shop Now", gambar Tarts, & dots
class _SpecialOfferBanner extends StatelessWidget {
  const _SpecialOfferBanner({this.onShopNow});

  final VoidCallback? onShopNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9E582D), Color(0xFF7E3D18)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E9E582D),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kolom Konten Teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge "Limited time."
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x2EFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Limited time.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFFAF7F2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Judul Utama "Get Special Offer"
                    Text(
                      'Get Special Offer',
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        height: 22 / 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Subteks "Up to 50%"
                    Text(
                      'Up to 50%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE6DDD0),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tombol CTA "Shop Now" (arah ke Pre-Order Custom Cake)
                    Material(
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: onShopNow,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          child: Text(
                            'Shop Now',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7E3D18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Gambar Produk Sisi Kanan (Tarts.png) yang diperbesar
              Image.asset(
                'assets/images/Tarts.png',
                width: 155,
                height: 98,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/croissant.png',
                  width: 155,
                  height: 98,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Indikator Titik (Pagination Dots) di Bawah Banner
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF9E582D),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D0C5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D0C5),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Daftar 5 kategori persegi empat bernuansa gelap yang interaktif saat diketuk,
/// tetap berukuran proporsional agar muat di dalam margin promotion banner.
class _CategoriesHorizontalList extends StatelessWidget {
  const _CategoriesHorizontalList({
    required this.categories,
    required this.horizontalPadding,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  final List<({String name, String icon})> categories;
  final double horizontalPadding;
  final String? selectedCategory;
  final ValueChanged<String> onSelectCategory;

  static const _categoryStyles = [
    // 1. Cake: deep berry / dark strawberry
    (bg: Color(0xFF7A2E2E), border: Color(0xFF5E2020)),
    // 2. Cup Cake: burnt terracotta
    (bg: Color(0xFF9A4A2E), border: Color(0xFF7A3822)),
    // 3. Cookies: dark caramel / toasted biscuit
    (bg: Color(0xFF8A5A1E), border: Color(0xFF6B4516)),
    // 4. Donuts: deep cocoa / dark latte
    (bg: Color(0xFF5A3A2A), border: Color(0xFF432A1E)),
    // 5. Breads: dark olive / rustic sage
    (bg: Color(0xFF4F5D3A), border: Color(0xFF3C472C)),
  ];

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = 8.0;
          final slotWidth =
              (constraints.maxWidth - gap * (categories.length - 1)) /
              categories.length;
          // Lebih besar dari 48dp, tetap muat 5 kategori di layar 320dp.
          // Sumber: https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html
          final squareSize = slotWidth.clamp(48.0, 64.0).toDouble();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < categories.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: _CategoryItem(
                    name: categories[i].name,
                    selected: selectedCategory == categories[i].name,
                    size: squareSize,
                    backgroundColor:
                        _categoryStyles[i % _categoryStyles.length].bg,
                    borderColor:
                        _categoryStyles[i % _categoryStyles.length].border,
                    onTap: () => onSelectCategory(categories[i].name),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.name,
    required this.selected,
    required this.size,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final double size;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              key: ValueKey('category-square-$name'),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? const Color(0xFFF6E7D4) : borderColor,
                  width: selected ? 2.4 : 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              key: ValueKey('category-label-$name'),
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                // Sans-serif extra-bold (Plus Jakarta Sans mendukung w800).
                // Sumber: https://api.flutter.dev/flutter/dart-ui/FontWeight-class.html
                fontWeight: FontWeight.w800,
                color: selected
                    ? const Color(0xFF3A2114)
                    : const Color(0xFF2B2118),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

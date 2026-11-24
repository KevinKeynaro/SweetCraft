import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';

/// Halaman Home / Katalog SweetCraft yang mengacu pada gambar referensi:
/// 1. Header Container cokelat tua dengan label "Location", pin lokasi, dan dropdown.
/// 2. Search bar full-width berlatar putih dengan placeholder "Search".
/// 3. Section "Special Offers" & promotion banner warm saddle dengan badge "Limited time.",
///    "Get Special Offer", "Up to 50%", tombol "Shop Now", gambar Tarts.png, dan pagination dots.
/// 4. Section "Categories" dengan wadah segi-empat rounded edge abu-abu lembut dan nama di-center.
/// 5. Section "Featured Products" (hanya baris header saja).
/// Semua font menggunakan GoogleFonts.plusJakartaSans.
class CatalogView extends StatefulWidget {
  const CatalogView({super.key, this.headerAction, this.userName});

  final Widget? headerAction;
  final String? userName;

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  static const _fallbackCategories = [
    (name: 'Cup Cake', icon: 'assets/images/cupcake-icon.png'),
    (name: 'Cookies', icon: 'assets/images/cupcake.png'),
    (name: 'Donuts', icon: 'assets/images/sour-dough.png'),
    (name: 'Breads', icon: 'assets/images/artisan-bread-icon.png'),
    (name: 'Pastry', icon: 'assets/images/croissant.png'),
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
    setState(() => _loading = true);
    try {
      final results = await ApiService.get('/categories');
      final categoriesPayload = results as Map<String, dynamic>;
      final categories =
          (categoriesPayload['categories'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width > 720 ? (width - 720) / 2 : 20.0;

    final categoriesToDisplay = _categories.isNotEmpty
        ? _categories.map((c) {
            final name = c['name'] as String? ?? 'Kue';
            return (name: name, icon: _iconForCategory(name));
          }).toList()
        : _fallbackCategories;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF8C4A27),
        backgroundColor: const Color(0xFFFFFFFF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Container & Location & Search Bar
              _HeaderSection(
                horizontalPadding: horizontalPadding,
                action: widget.headerAction,
                searchController: _searchController,
              ),

              const SizedBox(height: 24),

              // 2. Section "Special Offers" & Promotion Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const _SectionHeader(title: 'Special Offers'),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const _SpecialOfferBanner(),
              ),

              const SizedBox(height: 24),

              // 3. Section "Categories"
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const _SectionHeader(title: 'Categories'),
              ),
              const SizedBox(height: 14),
              _CategoriesHorizontalList(
                categories: categoriesToDisplay,
                horizontalPadding: horizontalPadding,
              ),

              const SizedBox(height: 28),

              // 4. Section "Featured Products" (Header Saja)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: const _SectionHeader(title: 'Featured Products'),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header Container cokelat tua dengan Location dan Search bar full-width
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.horizontalPadding,
    this.action,
    required this.searchController,
  });

  final double horizontalPadding;
  final Widget? action;
  final TextEditingController searchController;

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
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
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
              if (action != null) action!,
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

/// Header baris dengan judul di kiri dan teks "See All" cokelat di kanan
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
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
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2B2118),
          ),
        ),
        InkWell(
          onTap: onSeeAll,
          child: Text(
            'See All',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8C4A27),
            ),
          ),
        ),
      ],
    );
  }
}

/// Promotion Banner warm saddle dengan badge "Limited time.", "Get Special Offer", "Up to 50%", "Shop Now", gambar Tarts, & dots
class _SpecialOfferBanner extends StatelessWidget {
  const _SpecialOfferBanner();

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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        height: 24 / 19,
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

                    // Tombol CTA "Shop Now"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(20),
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
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Gambar Produk Sisi Kanan (Tarts.png)
              Image.asset(
                'assets/images/Tarts.png',
                width: 120,
                height: 75,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
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

/// Daftar kategori horizontal dengan wadah segi-empat rounded abu-abu lembut dan nama di-center
class _CategoriesHorizontalList extends StatelessWidget {
  const _CategoriesHorizontalList({
    required this.categories,
    required this.horizontalPadding,
  });

  final List<({String name, String icon})> categories;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              _CategoryItem(item: categories[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.item});

  final ({String name, String icon}) item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Wadah Gambar Berbentuk Segi-Empat Rounded Edge Berlatar Abu-abu Lembut
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EFEA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8E2D9),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            item.icon,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.cake_outlined,
              color: Color(0xFF8C4A27),
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Nama Kategori di Bagian Bawah yang Di-Center
        SizedBox(
          width: 64,
          child: Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2B2118),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import 'app_button.dart';
import 'product_card.dart';

class CatalogView extends StatefulWidget {
  const CatalogView({super.key});

  @override
  State<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<CatalogView> {
  List<Map<String, dynamic>> _cakes = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        ApiService.get('/cakes'),
        ApiService.get('/categories'),
      ]);
      final cakesPayload = results[0] as Map<String, dynamic>;
      final categoriesPayload = results[1] as Map<String, dynamic>;
      final cakes =
          (cakesPayload['cakes'] as List?)?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];
      final categories =
          (categoriesPayload['categories'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _cakes = cakes;
        _categories = categories;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Koneksi terputus. Periksa internet lalu coba lagi.';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredCakes {
    if (_selectedCategoryId == null) return _cakes;
    return _cakes
        .where((cake) => cake['category_id'] == _selectedCategoryId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final outerPadding = width > 720 ? (width - 720) / 2 : 16.0;
    final contentWidth = width - outerPadding * 2;
    final columns = contentWidth < 360 ? 1 : (contentWidth < 600 ? 2 : 3);
    const spacing = 12.0;
    final cardWidth = (contentWidth - spacing * (columns - 1)) / columns;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final mainAxisExtent = cardWidth * 3 / 4 + 24 + 110 * textScale;
    final filteredCakes = _filteredCakes;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFF8C4A27),
        backgroundColor: const Color(0xFFFFFFFF),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(padding: outerPadding)),
            if (!_loading && _error == null && _categories.isNotEmpty)
              SliverToBoxAdapter(
                child: _CategoryFilters(
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  padding: outerPadding,
                  onSelected: (categoryId) {
                    setState(() => _selectedCategoryId = categoryId);
                  },
                ),
              ),
            if (_loading)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(outerPadding, 8, outerPadding, 24),
                sliver: SliverGrid.builder(
                  itemCount: 6,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    mainAxisExtent: mainAxisExtent,
                  ),
                  itemBuilder: (context, index) => const _SkeletonCard(),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _CatalogMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'Koneksi terputus',
                  description: _error!,
                  actionLabel: 'Coba lagi',
                  onAction: _load,
                ),
              )
            else if (filteredCakes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _CatalogMessage(
                  icon: Icons.cake_outlined,
                  title: 'Belum ada menu',
                  description: _selectedCategoryId == null
                      ? 'Coba lagi nanti.'
                      : 'Belum ada menu untuk kategori ini.',
                  actionLabel: 'Muat ulang',
                  onAction: _load,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(outerPadding, 8, outerPadding, 24),
                sliver: SliverGrid.builder(
                  itemCount: filteredCakes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    mainAxisExtent: mainAxisExtent,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(cake: filteredCakes[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.padding});

  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 24, padding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Katalog',
            style: GoogleFonts.fraunces(
              fontSize: 24,
              height: 32 / 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2B2118),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kue rumahan untuk setiap momen.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 22 / 14,
              color: const Color(0xFF6E5D4F),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selectedCategoryId,
    required this.padding,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;
  final double padding;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: padding),
        children: [
          _CategoryChip(
            label: 'Semua',
            selected: selectedCategoryId == null,
            onSelected: () => onSelected(null),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _CategoryChip(
                label: category['name'] as String? ?? '',
                selected: selectedCategoryId == category['id'],
                onSelected: () => onSelected(category['id'] as int?),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      backgroundColor: const Color(0xFFF5EFE6),
      selectedColor: const Color(0xFF8C4A27),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? const Color(0xFFFFFFFF) : const Color(0xFF6E5D4F),
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 16),
            AppButton(label: actionLabel, outlined: true, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE6),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'seller_dashboard_widgets.dart';

/// Halaman Daftar Produk & Manajemen Stok Pemilik Toko (Tab 1).
/// Mendukung pencarian, filter kategori tanpa scroll horizontal, update stok cepat (+/- & manual),
/// edit, hapus dengan konfirmasi, serta pull-to-refresh.
class SellerMenuView extends StatefulWidget {
  const SellerMenuView({
    super.key,
    required this.cakes,
    required this.categories,
    required this.loading,
    required this.error,
    required this.updatingIds,
    required this.onRefresh,
    required this.onAdjustStock,
    required this.onSetManualStock,
    required this.onEditCake,
    required this.onDeleteCake,
    required this.onOpenAddTab,
    this.initialStockFilter = 'all',
  });

  final List<Map<String, dynamic>> cakes;
  final List<Map<String, dynamic>> categories;
  final bool loading;
  final String? error;
  final Set<int> updatingIds;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map<String, dynamic> cake, int delta) onAdjustStock;
  final Future<void> Function(Map<String, dynamic> cake, int newStock)
      onSetManualStock;
  final Future<void> Function(Map<String, dynamic> cake) onEditCake;
  final Future<void> Function(Map<String, dynamic> cake) onDeleteCake;
  final VoidCallback onOpenAddTab;
  final String initialStockFilter;

  @override
  State<SellerMenuView> createState() => _SellerMenuViewState();
}

class _SellerMenuViewState extends State<SellerMenuView> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategory = 'Semua';
  late String _stockFilter;

  @override
  void initState() {
    super.initState();
    _stockFilter = widget.initialStockFilter;
  }

  @override
  void didUpdateWidget(covariant SellerMenuView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStockFilter != oldWidget.initialStockFilter) {
      _stockFilter = widget.initialStockFilter;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _buildCategoryOptions() {
    final set = <String>{'Semua'};
    for (final c in widget.categories) {
      final name = c['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        set.add(name.trim());
      }
    }
    for (final cake in widget.cakes) {
      final cat = cake['category'] as String?;
      if (cat != null && cat.trim().isNotEmpty) {
        set.add(cat.trim());
      }
    }
    return set.toList();
  }

  List<Map<String, dynamic>> _filteredCakes() {
    final q = _query.trim().toLowerCase();
    return widget.cakes.where((cake) {
      final name = (cake['name'] as String? ?? '').toLowerCase();
      final desc = (cake['description'] as String? ?? '').toLowerCase();
      final cat = cake['category'] as String? ?? '';
      final stock = cake['stock'];

      if (q.isNotEmpty && !name.contains(q) && !desc.contains(q)) {
        return false;
      }
      if (_selectedCategory != 'Semua' && cat != _selectedCategory) {
        return false;
      }
      if (_stockFilter == 'low' && !isLowStock(stock)) {
        return false;
      }
      if (_stockFilter == 'empty' && !isOutOfStock(stock)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCategory = 'Semua';
      _stockFilter = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = _buildCategoryOptions();
    final filtered = _filteredCakes();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header dengan jarak atas nyaman
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Daftar Produk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF3B2A1E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EBDD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${filtered.length} Menu',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B5A2B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pencarian (>= 48dp touch target)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8DFD1)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF3B2A1E),
                ),
                decoration: InputDecoration(
                  hintText: 'Cari nama kue atau pastry...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFFA79A8C),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF8B5A2B),
                    size: 22,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          tooltip: 'Hapus pencarian',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF736052),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter Kategori (memakai Wrap agar tidak ada scroll horizontal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in categoryOptions)
                  _FilterChipButton(
                    label: cat,
                    selected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  ),
                if (_stockFilter != 'all')
                  _FilterChipButton(
                    label: _stockFilter == 'low'
                        ? 'Stok Menipis ×'
                        : 'Stok Habis ×',
                    selected: true,
                    accentOverride: _stockFilter == 'empty'
                        ? const Color(0xFFA63232)
                        : const Color(0xFFB45309),
                    onTap: () => setState(() => _stockFilter = 'all'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Daftar Produk
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              color: const Color(0xFF8B5A2B),
              backgroundColor: const Color(0xFFFFFFFF),
              child: _buildListBody(context, filtered),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBody(
    BuildContext context,
    List<Map<String, dynamic>> filtered,
  ) {
    if (widget.loading && widget.cakes.isEmpty) {
      return const DashboardSkeleton(itemCount: 4);
    }

    if (widget.error != null && widget.cakes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          DashboardErrorState(
            message: widget.error!,
            onRetry: widget.onRefresh,
          ),
        ],
      );
    }

    if (widget.cakes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          DashboardEmptyState(
            icon: Icons.bakery_dining_outlined,
            title: 'Belum Ada Menu Kue',
            message: 'Menu yang Anda tambahkan akan tampil di sini.',
            actionLabel: 'Tambah Produk',
            onAction: widget.onOpenAddTab,
          ),
        ],
      );
    }

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          DashboardEmptyState(
            icon: Icons.search_off_rounded,
            title: 'Produk Tidak Ditemukan',
            message: 'Coba ubah kata kunci pencarian atau filter kategori.',
            actionLabel: 'Reset Filter',
            onAction: _resetFilters,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cake = filtered[index];
        final id = cake['id'];
        return SellerProductCard(
          cake: cake,
          isUpdatingStock: widget.updatingIds.contains(id),
          onAdjustStock: (delta) => widget.onAdjustStock(cake, delta),
          onManualStockTap: () async {
            final current = (cake['stock'] as num?)?.toInt() ?? 0;
            final newStock = await showManualStockDialog(
              context,
              productName: cake['name'] as String? ?? 'Kue',
              initialStock: current,
            );
            if (newStock != null) {
              await widget.onSetManualStock(cake, newStock);
            }
          },
          onEdit: () => widget.onEditCake(cake),
          onDelete: () => widget.onDeleteCake(cake),
        );
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accentOverride,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentOverride;

  @override
  Widget build(BuildContext context) {
    final activeBg = accentOverride ?? const Color(0xFF8B5A2B);

    return Material(
      color: selected ? activeBg : const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? activeBg : const Color(0xFFE8DFD1),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF3B2A1E),
            ),
          ),
        ),
      ),
    );
  }
}

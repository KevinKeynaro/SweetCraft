import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'product_card.dart';
import 'seller_dashboard_widgets.dart';

/// Halaman Beranda Pemilik Toko (Tab 0):
/// Menampilkan ringkasan stok (Total, Menipis, Habis) dan daftar cepat produk perlu di-restock.
class SellerHomeView extends StatelessWidget {
  const SellerHomeView({
    super.key,
    required this.ownerName,
    required this.cakes,
    required this.loading,
    required this.error,
    required this.isMockMode,
    required this.updatingIds,
    required this.onRefresh,
    required this.onOpenProductsTab,
    required this.onOpenAddTab,
    required this.onAdjustStock,
    required this.onSetManualStock,
    this.onOpenProfileDialog,
  });

  final String ownerName;
  final List<Map<String, dynamic>> cakes;
  final bool loading;
  final String? error;
  final bool isMockMode;
  final Set<int> updatingIds;
  final Future<void> Function() onRefresh;
  final void Function({String stockFilter}) onOpenProductsTab;
  final VoidCallback onOpenAddTab;
  final Future<void> Function(Map<String, dynamic> cake, int delta) onAdjustStock;
  final Future<void> Function(Map<String, dynamic> cake, int newStock)
      onSetManualStock;
  final VoidCallback? onOpenProfileDialog;

  @override
  Widget build(BuildContext context) {
    final firstName = ownerName.trim().split(RegExp(r'\s+')).first;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bersih Beranda dengan jarak atas nyaman
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ${firstName.isEmpty ? 'Pemilik' : firstName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF736052),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Dashboard Toko',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF3B2A1E),
                              ),
                            ),
                          ),
                          if (isMockMode) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Demo',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onOpenProfileDialog != null) ...[
                  const SizedBox(width: 8),
                  Material(
                    color: const Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE8DFD1)),
                    ),
                    child: InkWell(
                      onTap: onOpenProfileDialog,
                      borderRadius: BorderRadius.circular(14),
                      child: const Tooltip(
                        message: 'Profil & Keluar',
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF8B5A2B),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: const Color(0xFF8B5A2B),
              backgroundColor: const Color(0xFFFFFFFF),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (loading && cakes.isEmpty) {
      return const DashboardSkeleton(itemCount: 4);
    }

    if (error != null && cakes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          DashboardErrorState(message: error!, onRetry: onRefresh),
        ],
      );
    }

    final totalCount = cakes.length;
    final lowCount = cakes.where((c) => isLowStock(c['stock'])).length;
    final emptyCount = cakes.where((c) => isOutOfStock(c['stock'])).length;

    final restockList = cakes
        .where((c) => isOutOfStock(c['stock']) || isLowStock(c['stock']))
        .toList()
      ..sort((a, b) {
        final sa = (a['stock'] as num?)?.toInt() ?? 0;
        final sb = (b['stock'] as num?)?.toInt() ?? 0;
        return sa.compareTo(sb);
      });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        // 1. Kartu Ringkasan Stok (3 kolom sejajar, aman di 360dp)
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Produk',
                count: totalCount,
                icon: Icons.inventory_2_outlined,
                accentColor: const Color(0xFF8B5A2B),
                badgeBackground: const Color(0xFFF3EBDD),
                onTap: () => onOpenProductsTab(stockFilter: 'all'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Menipis',
                count: lowCount,
                icon: Icons.warning_amber_rounded,
                accentColor: const Color(0xFFB45309),
                badgeBackground: const Color(0xFFFEF3C7),
                onTap: () => onOpenProductsTab(stockFilter: 'low'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SummaryCard(
                title: 'Habis',
                count: emptyCount,
                icon: Icons.error_outline_rounded,
                accentColor: const Color(0xFFA63232),
                badgeBackground: const Color(0xFFFDE8E8),
                onTap: () => onOpenProductsTab(stockFilter: 'empty'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // 2. Header Daftar Singkat Restock
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Perlu Di-Restock',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3B2A1E),
                ),
              ),
            ),
            TextButton(
              onPressed: () => onOpenProductsTab(stockFilter: 'all'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                foregroundColor: const Color(0xFF8B5A2B),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),

        const SizedBox(height: 6),

        if (cakes.isEmpty)
          DashboardEmptyState(
            icon: Icons.bakery_dining_outlined,
            title: 'Toko Masih Kosong',
            message: 'Tambahkan produk kue atau pastry pertama Anda.',
            actionLabel: 'Tambah Produk',
            onAction: onOpenAddTab,
          )
        else if (restockList.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFD1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4EA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF1E6B3A),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semua Stok Aman!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B2A1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tidak ada kue dengan stok menipis atau habis saat ini.',
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
          )
        else ...[
          for (final cake in restockList.take(5)) ...[
            _RestockQuickCard(
              cake: cake,
              isUpdating: updatingIds.contains(cake['id']),
              onQuickPlus: () => onAdjustStock(cake, 1),
              onTapManual: () async {
                final current = (cake['stock'] as num?)?.toInt() ?? 0;
                final newStock = await showManualStockDialog(
                  context,
                  productName: cake['name'] as String? ?? 'Kue',
                  initialStock: current,
                );
                if (newStock != null) {
                  await onSetManualStock(cake, newStock);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _RestockQuickCard extends StatelessWidget {
  const _RestockQuickCard({
    required this.cake,
    required this.isUpdating,
    required this.onQuickPlus,
    required this.onTapManual,
  });

  final Map<String, dynamic> cake;
  final bool isUpdating;
  final VoidCallback onQuickPlus;
  final VoidCallback onTapManual;

  @override
  Widget build(BuildContext context) {
    final name = cake['name'] as String? ?? 'Kue';
    final price = cake['price'];
    final stock = cake['stock'];
    final imageUrl = cake['image_url'] as String?;
    final mockAsset = cake['mock_asset'] as String?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x083B2A1E),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          BakeryThumbnail(
            imageUrl: imageUrl,
            mockAsset: mockAsset,
            size: 56,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B2A1E),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StockBadge(stock: stock, compact: true),
                    Text(
                      formatRupiah(price),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF736052),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tombol ketuk untuk input manual atau +1 cepat (>= 44dp)
          InkWell(
            onTap: isUpdating ? null : onTapManual,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8DFD1)),
              ),
              alignment: Alignment.center,
              child: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8B5A2B),
                      ),
                    )
                  : Text(
                      'Atur',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B5A2B),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: const Color(0xFF8B5A2B),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: isUpdating ? null : onQuickPlus,
              borderRadius: BorderRadius.circular(10),
              child: const Tooltip(
                message: 'Tambah 1 stok',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

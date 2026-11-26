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
  final Set<int> updatingIds;
  final Future<void> Function() onRefresh;
  final void Function({String stockFilter}) onOpenProductsTab;
  final VoidCallback onOpenAddTab;
  final Future<void> Function(Map<String, dynamic> cake, int delta)
  onAdjustStock;
  final Future<void> Function(Map<String, dynamic> cake, int newStock)
  onSetManualStock;
  final VoidCallback? onOpenProfileDialog;

  @override
  Widget build(BuildContext context) {
    final firstName = ownerName.trim().split(RegExp(r'\s+')).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SellerCurvedHeader(
          subtitle: 'Halo, ${firstName.isEmpty ? 'Pemilik' : firstName}',
          title: 'Dashboard Toko',
          trailing: onOpenProfileDialog == null
              ? null
              : Material(
                  color: const Color(0x2EFFFFFF),
                  borderRadius: BorderRadius.circular(14),
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
                          color: Color(0xFFFDFBF7),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
          bottomChild: Container(
            height: 48,
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
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onOpenProductsTab(stockFilter: 'all'),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF6E5D4F),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cari nama kue atau kelola stok...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFFA79A8C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: const Color(0xFF8C4A27),
            backgroundColor: const Color(0xFFFFFFFF),
            child: _buildContent(context),
          ),
        ),
      ],
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

    final restockList =
        cakes
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
                accentColor: const Color(0xFF8C4A27),
                badgeBackground: const Color(0xFFF5EFE6),
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
                accentColor: const Color(0xFF991B1B),
                badgeBackground: const Color(0xFFFEE2E2),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: const Color(0xFF2B2118),
                ),
              ),
            ),
            TextButton(
              onPressed: () => onOpenProductsTab(stockFilter: 'all'),
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 44),
                foregroundColor: const Color(0xFF8C4A27),
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
              border: Border.all(color: const Color(0xFFE6DDD0)),
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
                    color: Color(0xFF166534),
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
                          color: const Color(0xFF2B2118),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tidak ada kue dengan stok menipis atau habis saat ini.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF6E5D4F),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DDD0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2B2118),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          BakeryThumbnail(imageUrl: imageUrl, size: 56, radius: 12),
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
                    color: const Color(0xFF2B2118),
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
                        color: const Color(0xFF6E5D4F),
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6DDD0)),
              ),
              alignment: Alignment.center,
              child: isUpdating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8C4A27),
                      ),
                    )
                  : Text(
                      'Atur',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8C4A27),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: const Color(0xFF8C4A27),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isUpdating ? null : onQuickPlus,
              borderRadius: BorderRadius.circular(12),
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

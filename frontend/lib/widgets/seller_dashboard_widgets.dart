import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'product_card.dart';

/// Menentukan apakah stok tergolong menipis (1..5).
bool isLowStock(dynamic stock) => stock is num && stock > 0 && stock <= 5;

/// Menentukan apakah stok habis (0).
bool isOutOfStock(dynamic stock) => stock is num && stock <= 0;

/// Badge status stok berwarna lembut (hijau aman, kuning menipis, merah bata habis).
class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock, this.compact = false});

  final dynamic stock;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;

    if (stock is! num) {
      label = 'Pre-Order';
      bg = const Color(0xFFE6F4EA);
      fg = const Color(0xFF1E6B3A);
    } else if (stock <= 0) {
      label = 'Habis';
      bg = const Color(0xFFFDE8E8);
      fg = const Color(0xFFA63232);
    } else if (stock <= 5) {
      label = 'Menipis (${stock.toInt()})';
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else {
      label = 'Aman (${stock.toInt()})';
      bg = const Color(0xFFE6F4EA);
      fg = const Color(0xFF1E6B3A);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Kartu ringkasan stok reusable untuk halaman Beranda pemilik toko.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.badgeBackground,
    this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color accentColor;
  final Color badgeBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A3B2A1E),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: badgeBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF9C8370),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3B2A1E),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF736052),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail foto kue yang mendukung URL jaringan maupun placeholder.
class BakeryThumbnail extends StatelessWidget {
  const BakeryThumbnail({
    super.key,
    this.imageUrl,
    this.size = 76,
    this.radius = 14,
  });

  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackWidget(),
      );
    } else {
      content = _fallbackWidget();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EC),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE8DFD1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _fallbackWidget() {
    return const ColoredBox(
      color: Color(0xFFF5EDE0),
      child: Center(
        child: Icon(
          Icons.bakery_dining_outlined,
          color: Color(0xFF8B5A2B),
          size: 28,
        ),
      ),
    );
  }
}

/// Kartu produk untuk halaman daftar produk pemilik toko, dilengkapi aksi +/- stok cepat,
/// tap angka stok untuk input manual, edit, dan hapus.
class SellerProductCard extends StatelessWidget {
  const SellerProductCard({
    super.key,
    required this.cake,
    required this.onAdjustStock,
    required this.onManualStockTap,
    required this.onEdit,
    required this.onDelete,
    this.isUpdatingStock = false,
  });

  final Map<String, dynamic> cake;
  final ValueChanged<int> onAdjustStock;
  final VoidCallback onManualStockTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isUpdatingStock;

  @override
  Widget build(BuildContext context) {
    final name = cake['name'] as String? ?? 'Kue';
    final categoryLabel = displayCategoryName(cake['category'] as String?);
    final category = categoryLabel.isEmpty ? 'Lainnya' : categoryLabel;
    final price = cake['price'];
    final stock = cake['stock'];
    final imageUrl = cake['image_url'] as String?;
    final currentStock = stock is num ? stock.toInt() : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A3B2A1E),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BakeryThumbnail(imageUrl: imageUrl, size: 76, radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF6EC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE8DFD1)),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B5A2B),
                            ),
                          ),
                        ),
                        StockBadge(stock: stock, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B2A1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(price),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF8B5A2B),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0E8DA)),
          const SizedBox(height: 10),

          // Baris Kontrol Stok Cepat (- / angka manual / +) & Aksi (Edit / Hapus)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kontrol Stok (Touch target >= 44dp)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StockStepButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Kurangi stok',
                    enabled: !isUpdatingStock && currentStock > 0,
                    onTap: () => onAdjustStock(-1),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Ketuk untuk ubah stok manual',
                    child: InkWell(
                      onTap: isUpdatingStock ? null : onManualStockTap,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 52,
                          minHeight: 44,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF6EC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE8DFD1)),
                        ),
                        alignment: Alignment.center,
                        child: isUpdatingStock
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF8B5A2B),
                                ),
                              )
                            : Text(
                                stock is num ? '${stock.toInt()}' : '∞',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF3B2A1E),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _StockStepButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Tambah stok',
                    enabled: !isUpdatingStock,
                    onTap: () => onAdjustStock(1),
                  ),
                ],
              ),

              // Aksi Edit & Hapus (rounded square, touch target >= 48dp)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SquareIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit produk',
                    color: const Color(0xFF8B5A2B),
                    backgroundColor: const Color(0xFFF8F1E7),
                    borderColor: const Color(0xFFE8DFD1),
                    onPressed: onEdit,
                  ),
                  const SizedBox(width: 6),
                  _SquareIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Hapus produk',
                    color: const Color(0xFFA63232),
                    backgroundColor: const Color(0xFFFDF0F0),
                    borderColor: const Color(0xFFF0D6D6),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: color,
        minimumSize: const Size(48, 48),
        maximumSize: const Size(48, 48),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _StockStepButton extends StatelessWidget {
  const _StockStepButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? const Color(0xFF8B5A2B) : const Color(0xFFEFE9E1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFFA79A8C),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog input angka stok manual untuk memperbarui stok produk secara cepat.
Future<int?> showManualStockDialog(
  BuildContext context, {
  required String productName,
  required int initialStock,
}) {
  final controller = TextEditingController(text: '$initialStock');
  String? errorText;

  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFFFFFFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'Atur Stok Produk',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B2A1E),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  productName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF736052),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B2A1E),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Jumlah Stok (unit)',
                    errorText: errorText,
                    filled: true,
                    fillColor: const Color(0xFFFAF6EC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE8DFD1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B5A2B),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  foregroundColor: const Color(0xFF736052),
                ),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  final parsed = int.tryParse(controller.text.trim());
                  if (parsed == null || parsed < 0) {
                    setDialogState(() {
                      errorText = 'Masukkan angka stok 0 atau lebih';
                    });
                    return;
                  }
                  Navigator.pop(dialogContext, parsed);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(84, 44),
                  backgroundColor: const Color(0xFF8B5A2B),
                  foregroundColor: const Color(0xFFFFFFFF),
                ),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Skeleton loading sederhana berdenyut tanpa package tambahan.
class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shade = Color.lerp(
          const Color(0xFFEDE4D4),
          const Color(0xFFF6F0E4),
          _controller.value,
        )!;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => Container(
            height: 108,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFD1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: shade,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: shade,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: shade,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 110,
                        decoration: BoxDecoration(
                          color: shade,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tampilan empty state yang rapi dan konsisten.
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFF3EBDD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF8B5A2B)),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B2A1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 20 / 13,
                color: const Color(0xFF736052),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  backgroundColor: const Color(0xFF8B5A2B),
                  foregroundColor: const Color(0xFFFFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tampilan error state dengan tombol coba lagi.
class DashboardErrorState extends StatelessWidget {
  const DashboardErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFA63232),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak Dapat Memuat Data',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B2A1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF736052),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(140, 48),
                backgroundColor: const Color(0xFF8B5A2B),
                foregroundColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
